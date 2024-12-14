defmodule Mudbrick.Parser.Helpers do
  import NimbleParsec

  def eol, do: string("\n")
  def whitespace, do: ascii_string([?\n, ?\s], min: 1)

  def version do
    ignore(string("%PDF-"))
    |> integer(1)
    |> ignore(string("."))
    |> integer(1)
    |> ignore(eol())
    |> tag(:version)
  end

  def name do
    ignore(string("/"))
    |> utf8_string(
      [
        not: ?\s,
        not: ?\n,
        not: ?],
        not: ?[,
        not: ?/,
        not: ?<,
        not: ?>
      ],
      min: 1
    )
    |> unwrap_and_tag(:name)
  end

  def non_negative_integer do
    ascii_string([?0..?9], min: 1)
  end

  def negative_integer do
    string("-")
    |> concat(non_negative_integer())
  end

  def indirect_reference do
    non_negative_integer()
    |> ignore(whitespace())
    |> concat(non_negative_integer())
    |> ignore(whitespace())
    |> string("R")
    |> tag(:indirect_reference)
  end

  def integer do
    choice([
      non_negative_integer(),
      negative_integer()
    ])
    |> tag(:integer)
  end

  def real do
    choice([
      non_negative_integer(),
      negative_integer()
    ])
    |> string(".")
    |> optional(non_negative_integer())
    |> tag(:real)
  end

  def number do
    choice([real(), integer()])
  end

  def string do
    ignore(string("("))
    |> optional(ascii_string([not: ?(, not: ?)], min: 1))
    |> ignore(string(")"))
    |> tag(:string)
  end

  def boolean do
    choice([
      string("true") |> replace(true),
      string("false") |> replace(false)
    ])
    |> unwrap_and_tag(:boolean)
  end

  def xref do
    ignore(string("xref"))
    |> ignore(eol())
  end

  def tf do
    ignore(string("/F"))
    |> concat(non_negative_integer())
    |> ignore(whitespace())
    |> concat(non_negative_integer())
    |> ignore(whitespace())
    |> ignore(string("Tf"))
    |> tag(:Tf)
  end

  def tl do
    real()
    |> ignore(string(" TL"))
    |> tag(:TL)
  end

  def rg_stroking do
    three_number_operation("RG")
    |> tag(:RG)
  end

  def rg_non_stroking do
    three_number_operation("rg")
    |> tag(:rg)
  end

  def m do
    two_number_operation("m")
    |> tag(:m)
  end

  def w do
    one_number_operation("w")
    |> tag(:w)
  end

  def glyph_id_hex do
    ignore(string("<"))
    |> ascii_string([?A..?Z, ?0..?9], min: 1)
    |> ignore(string(">"))
    |> unwrap_and_tag(:glyph_id)
  end

  def tj do
    ignore(string("["))
    |> ignore(whitespace())
    |> repeat(
      choice([
        glyph_id_hex(),
        non_negative_integer() |> unwrap_and_tag(:offset)
      ])
      |> ignore(whitespace())
    )
    |> ignore(string("]"))
    |> ignore(whitespace())
    |> ignore(string("TJ"))
    |> tag(:TJ)
  end

  def td do
    two_number_operation("Td")
    |> tag(:Td)
  end

  def l do
    two_number_operation("l")
    |> tag(:l)
  end

  def q_push do
    ignore(string("q")) |> tag(:q)
  end

  def s do
    ignore(string("S")) |> tag(:S)
  end

  def t_star do
    ignore(string("T*")) |> tag(:TStar)
  end

  def q_pop do
    ignore(string("Q")) |> tag(:Q)
  end

  def graphics_block do
    q_push()
    |> ignore(whitespace())
    |> repeat(
      choice([
        l(),
        m(),
        rg_non_stroking(),
        rg_stroking(),
        s(),
        w()
      ])
      |> ignore(whitespace())
    )
    |> concat(q_pop())
    |> tag(:graphics_block)
  end

  def text_block do
    tag(ignore(string("BT")), :BT)
    |> ignore(whitespace())
    |> repeat(
      choice([
        l(),
        m(),
        q_pop(),
        q_push(),
        rg_non_stroking(),
        rg_stroking(),
        s(),
        td(),
        tf(),
        tj(),
        tl(),
        t_star(),
        w()
      ])
      |> ignore(whitespace())
    )
    |> tag(ignore(string("ET")), :ET)
    |> tag(:text_block)
  end

  defp one_number_operation(operator) do
    number()
    |> ignore(whitespace())
    |> ignore(string(operator))
  end

  defp two_number_operation(operator) do
    number()
    |> ignore(whitespace())
    |> concat(number())
    |> ignore(whitespace())
    |> ignore(string(operator))
  end

  defp three_number_operation(operator) do
    number()
    |> ignore(whitespace())
    |> concat(number())
    |> ignore(whitespace())
    |> concat(number())
    |> ignore(whitespace())
    |> ignore(string(operator))
  end
end

defmodule Mudbrick.Parser do
  import NimbleParsec
  import Mudbrick.Parser.Helpers

  alias Mudbrick.ContentStream.{
    BT,
    ET,
    L,
    M,
    QPop,
    QPush,
    Rg,
    S,
    Td,
    Tf,
    TJ,
    TL,
    W
  }

  defparsec(:boolean, boolean())
  defparsec(:number, number())
  defparsec(:real, real())
  defparsec(:string, string())

  defparsec(
    :content_blocks,
    repeat(
      choice([
        text_block(),
        graphics_block()
      ])
      |> ignore(optional(whitespace()))
    )
  )

  defparsec(
    :array,
    ignore(ascii_char([?[]))
    |> repeat(
      optional(ignore(whitespace()))
      |> parsec(:object)
      |> optional(ignore(whitespace()))
    )
    |> ignore(ascii_char([?]]))
    |> tag(:array)
  )

  defparsec(
    :dictionary,
    ignore(string("<<"))
    |> repeat(
      optional(ignore(whitespace()))
      |> concat(name())
      |> ignore(whitespace())
      |> parsec(:object)
      |> tag(:pair)
    )
    |> optional(ignore(whitespace()))
    |> ignore(string(">>"))
    |> tag(:dictionary)
  )

  defparsec(
    :object,
    choice([
      string(),
      name(),
      indirect_reference(),
      real(),
      integer(),
      boolean(),
      parsec(:array),
      parsec(:dictionary)
    ])
  )

  defparsec(
    :stream,
    parsec(:dictionary)
    |> ignore(whitespace())
    |> string("stream")
    |> ignore(eol())
    |> post_traverse({:stream_contents, []})
    |> ignore(eol())
    |> ignore(string("endstream"))
  )

  defparsec(
    :indirect_object,
    integer(min: 1)
    |> ignore(whitespace())
    |> integer(min: 1)
    |> ignore(whitespace())
    |> ignore(string("obj"))
    |> ignore(eol())
    |> concat(
      choice([
        boolean(),
        parsec(:stream),
        parsec(:dictionary)
      ])
    )
    |> ignore(eol())
    |> ignore(string("endobj"))
    |> ignore(eol())
    |> tag(:indirect_object)
  )

  def stream_contents(
        rest,
        [
          "stream",
          {:dictionary, pairs}
        ] = results,
        context,
        _line,
        _offset
      ) do
    dictionary = ast_to_mudbrick({:dictionary, pairs})
    bytes_to_read = dictionary[:Length]

    {
      binary_slice(rest, bytes_to_read..-1//1),
      [binary_slice(rest, 0, bytes_to_read) | results],
      context
    }
  end

  defparsec(
    :pdf,
    ignore(version())
    |> ignore(ascii_string([not: ?\n], min: 1))
    |> ignore(eol())
    |> repeat(parsec(:indirect_object))
    |> ignore(string("xref"))
    |> ignore(eol())
    |> eventually(ignore(string("trailer") |> concat(eol())))
    |> parsec(:dictionary)
  )

  defp one(items, ref) do
    Enum.find(items, &match?(%{ref: ^ref}, &1))
  end

  defp all(items, refs) do
    Enum.filter(items, fn
      %{ref: ref} ->
        ref in refs

      _ ->
        false
    end)
  end

  def extract_text(iodata) do
    alias Mudbrick.ContentStream.{Tf, TJ}

    doc = parse(iodata)

    content_stream =
      Mudbrick.Document.find_object(doc, &match?(%Mudbrick.ContentStream{}, &1))

    page_tree = Mudbrick.Document.root_page_tree(doc)
    fonts = page_tree.value.fonts

    {text_items, _last_found_font} =
      content_stream.value.operations
      |> List.foldr({[], nil}, fn
        %Tf{font_identifier: font_identifier}, {text_items, _current_font} ->
          {text_items, Map.fetch!(fonts, font_identifier).value.parsed}

        %TJ{kerned_text: kerned_text}, {text_items, current_font} ->
          text =
            kerned_text
            |> Enum.map(fn
              {hex_glyph, _kern} -> hex_glyph
              hex_glyph -> hex_glyph
            end)
            |> Enum.map(fn hex_glyph ->
              {decimal_glyph, _} = Integer.parse(hex_glyph, 16)
              Map.fetch!(current_font.gid2cid, decimal_glyph)
            end)
            |> to_string()

          {[text | text_items], current_font}

        _operation, {text_items, current_font} ->
          {text_items, current_font}
      end)

    Enum.reverse(text_items)
  end

  def parse(iodata) do
    {:ok, parsed_items, _rest, %{}, _, _} =
      iodata
      |> IO.iodata_to_binary()
      |> pdf()

    items = Enum.flat_map(parsed_items, &ast_to_mudbrick/1)

    trailer =
      Enum.find(items, &match?({:Root, _}, &1))

    {:Root, [catalog_ref]} = trailer

    font_files =
      Enum.filter(
        items,
        &match?(%{value: %{additional_entries: %{Subtype: :OpenType}}}, &1)
      )

    catalog = one(items, catalog_ref)

    [page_tree_ref] = catalog.value[:Pages]

    page_tree = one(items, page_tree_ref)

    page_refs = List.flatten(page_tree.value[:Kids])

    {_, fonts} =
      for font_file <- font_files, reduce: {1, %{}} do
        {n, fonts} ->
          {n + 1, Map.put(fonts, :"F#{n}", font_file.value.data)}
      end

    opts = [fonts: fonts]

    for page <- all(items, page_refs), reduce: Mudbrick.new(opts) do
      acc ->
        [contents_ref] = page.value[:Contents]
        contents = one(items, contents_ref)

        %Mudbrick.ContentStream{operations: operations} =
          contents.value.data
          |> to_mudbrick(:content_blocks)

        Mudbrick.page(acc)
        |> Mudbrick.ContentStream.update_operations(fn ops ->
          operations ++ ops
        end)
    end
    |> Mudbrick.Document.finish()
  end

  def parse(iodata, f) do
    case iodata
         |> IO.iodata_to_binary()
         |> then(&apply(__MODULE__, f, [&1])) do
      {:ok, resp, _, %{}, _, _} -> resp
    end
  end

  def to_mudbrick(iodata, f),
    do:
      iodata
      |> parse(f)
      |> ast_to_mudbrick()

  defp ast_to_operator({:BT, []}), do: %BT{}

  defp ast_to_operator({:m, [x, y]}),
    do: %M{
      coords: {ast_to_mudbrick(x), ast_to_mudbrick(y)}
    }

  defp ast_to_operator({:l, [x, y]}),
    do: %L{
      coords: {ast_to_mudbrick(x), ast_to_mudbrick(y)}
    }

  defp ast_to_operator({:RG, [r, g, b]}),
    do: %Rg{
      stroking: true,
      r: ast_to_mudbrick(r),
      g: ast_to_mudbrick(g),
      b: ast_to_mudbrick(b)
    }

  defp ast_to_operator({:S, []}), do: %S{}
  defp ast_to_operator({:Td, [x, y]}), do: %Td{tx: ast_to_mudbrick(x), ty: ast_to_mudbrick(y)}

  defp ast_to_operator({:w, number}), do: %W{width: ast_to_mudbrick(number)}

  defp ast_to_operator({:q, []}), do: %QPush{}
  defp ast_to_operator({:Q, []}), do: %QPop{}

  defp ast_to_operator({:Tf, [index, size]}), do: %Tf{font_identifier: :"F#{index}", size: size}

  defp ast_to_operator({:TL, leading}), do: %TL{leading: ast_to_mudbrick(leading)}

  defp ast_to_operator({:rg, components}),
    do: struct!(Rg, Enum.zip([:r, :g, :b], Enum.map(components, &ast_to_mudbrick/1)))

  defp ast_to_operator({:TJ, glyphs_and_offsets}) do
    contains_kerns? = Enum.any?(glyphs_and_offsets, &match?({:offset, _}, &1))

    kerned_text =
      Enum.reduce(glyphs_and_offsets, [], fn
        {:glyph_id, id}, acc ->
          [id | acc]

        {:offset, offset}, [last_glyph | acc] ->
          [{last_glyph, String.to_integer(offset)} | acc]
      end)

    %TJ{
      auto_kern: contains_kerns?,
      kerned_text: Enum.reverse(kerned_text)
    }
  end

  defp ast_to_operator({:ET, []}), do: %ET{}

  defp ast_to_mudbrick([{block_type, _operations} | _rest] = input)
       when block_type in [:text_block, :graphics_block] do
    mudbrick_operations =
      Enum.flat_map(input, fn {_block_type, operations} ->
        Enum.map(operations, &ast_to_operator/1)
      end)

    %Mudbrick.ContentStream{
      page: nil,
      operations: Enum.reverse(mudbrick_operations)
    }
  end

  defp ast_to_mudbrick(x) when is_tuple(x), do: ast_to_mudbrick([x])
  defp ast_to_mudbrick(array: a), do: Enum.map(a, &ast_to_mudbrick/1)
  defp ast_to_mudbrick(boolean: b), do: b
  defp ast_to_mudbrick(integer: [n]), do: String.to_integer(n)
  defp ast_to_mudbrick(integer: ["-", n]), do: -String.to_integer(n)
  defp ast_to_mudbrick(real: [n, ".", d]), do: String.to_float("#{n}.#{d}")
  defp ast_to_mudbrick(real: ["-" | rest]), do: -ast_to_mudbrick(real: rest)
  defp ast_to_mudbrick(string: [s]), do: s
  defp ast_to_mudbrick(string: []), do: ""
  defp ast_to_mudbrick(name: s), do: String.to_atom(s)

  defp ast_to_mudbrick(pair: [k, v]) do
    {ast_to_mudbrick(k), ast_to_mudbrick(v)}
  end

  defp ast_to_mudbrick(dictionary: []), do: %{}

  defp ast_to_mudbrick(dictionary: pairs) do
    for {:pair, [k, v]} <- pairs, into: %{} do
      {ast_to_mudbrick(k), ast_to_mudbrick(v)}
    end
  end

  defp ast_to_mudbrick([]), do: []

  defp ast_to_mudbrick([[{:indirect_object, _} | _rest] = unwrapped]) do
    ast_to_mudbrick(unwrapped)
  end

  defp ast_to_mudbrick([
         {:indirect_object,
          [
            ref_number,
            _version,
            {:dictionary, pairs}
          ]}
         | rest
       ]) do
    [
      Mudbrick.Indirect.Ref.new(ref_number)
      |> Mudbrick.Indirect.Object.new(
        pairs
        |> Enum.map(&ast_to_mudbrick/1)
        |> Enum.into(%{})
      )
      | ast_to_mudbrick(rest)
    ]
  end

  defp ast_to_mudbrick([
         {:indirect_object,
          [
            ref_number,
            _version,
            {:dictionary, pairs},
            "stream",
            stream
          ]}
         | rest
       ]) do
    [
      Mudbrick.Indirect.Ref.new(ref_number)
      |> Mudbrick.Indirect.Object.new(
        Mudbrick.Stream.new(
          data: stream,
          additional_entries:
            pairs
            |> Enum.map(&ast_to_mudbrick/1)
            |> Map.new()
            |> Map.drop([:Length])
        )
      )
      | ast_to_mudbrick(rest)
    ]
  end

  defp ast_to_mudbrick([
         {:indirect_reference,
          [
            ref_number,
            _version,
            "R"
          ]}
         | _rest
       ]) do
    [
      ref_number
      |> String.to_integer()
      |> Mudbrick.Indirect.Ref.new()
    ]
  end
end
