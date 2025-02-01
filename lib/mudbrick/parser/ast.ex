defmodule Mudbrick.Parser.AST do
  @moduledoc false

  alias Mudbrick.ContentStream.{
    Cm,
    Do,
    L,
    M,
    QPop,
    QPush,
    Re,
    Rg,
    Td,
    Tf,
    TJ,
    TL,
    W
  }

  alias Mudbrick.Indirect

  def to_operator({:cm, [x_scale, x_skew, y_skew, y_scale, x_translate, y_translate]}),
    do: %Cm{
      scale: {to_mudbrick(x_scale), to_mudbrick(y_scale)},
      skew: {to_mudbrick(x_skew), to_mudbrick(y_skew)},
      position: {to_mudbrick(x_translate), to_mudbrick(y_translate)}
    }

  def to_operator({:re, [x, y, w, h]}),
    do: %Re{
      lower_left: {to_mudbrick(x), to_mudbrick(y)},
      dimensions: {to_mudbrick(w), to_mudbrick(h)}
    }

  def to_operator({:m, [x, y]}),
    do: %M{
      coords: {to_mudbrick(x), to_mudbrick(y)}
    }

  def to_operator({:l, [x, y]}),
    do: %L{
      coords: {to_mudbrick(x), to_mudbrick(y)}
    }

  def to_operator({:RG, [r, g, b]}),
    do: %Rg{
      stroking: true,
      r: to_mudbrick(r),
      g: to_mudbrick(g),
      b: to_mudbrick(b)
    }

  def to_operator({:Do, [index]}), do: %Do{image_identifier: :"I#{index}"}
  def to_operator({:Td, [x, y]}), do: %Td{tx: to_mudbrick(x), ty: to_mudbrick(y)}
  def to_operator({:w, number}), do: %W{width: to_mudbrick(number)}
  def to_operator({:Tf, [index, size]}), do: %Tf{font_identifier: :"F#{index}", size: size}
  def to_operator({:TL, leading}), do: %TL{leading: to_mudbrick(leading)}

  def to_operator({:rg, components}),
    do: struct!(Rg, Enum.zip([:r, :g, :b], Enum.map(components, &to_mudbrick/1)))

  def to_operator({:TJ, glyphs_and_offsets}) do
    contains_kerns? = Enum.any?(glyphs_and_offsets, &match?({:offset, _}, &1))

    kerned_text =
      Enum.reduce(glyphs_and_offsets, [], fn
        {:glyph_id, id}, acc ->
          [id | acc]

        {:offset, {:integer, offset}}, [last_glyph | acc] ->
          [{last_glyph, offset |> Enum.join() |> String.to_integer()} | acc]
      end)

    %TJ{
      auto_kern: contains_kerns?,
      kerned_text: Enum.reverse(kerned_text)
    }
  end

  def to_operator({:Q, []}), do: %QPop{}
  def to_operator({:q, []}), do: %QPush{}

  def to_operator({op, []}),
    do: struct!(Module.safe_concat([Mudbrick.ContentStream, op]), [])

  def to_mudbrick([{block_type, _operations} | _rest] = input)
      when block_type in [:text_block, :graphics_block] do
    mudbrick_operations =
      Enum.flat_map(input, fn {_block_type, operations} ->
        Enum.map(operations, &to_operator/1)
      end)

    %Mudbrick.ContentStream{
      page: nil,
      operations: Enum.reverse(mudbrick_operations)
    }
  end

  def to_mudbrick(x) when is_tuple(x), do: to_mudbrick([x])
  def to_mudbrick(array: a), do: Enum.map(a, &to_mudbrick/1)
  def to_mudbrick(boolean: b), do: b
  def to_mudbrick(integer: [n]), do: String.to_integer(n)
  def to_mudbrick(integer: ["-", n]), do: -String.to_integer(n)
  def to_mudbrick(real: [n, ".", d]), do: String.to_float("#{n}.#{d}")
  def to_mudbrick(real: ["-" | rest]), do: -to_mudbrick(real: rest)
  def to_mudbrick(string: [s]), do: s
  def to_mudbrick(string: []), do: ""
  def to_mudbrick(name: s), do: String.to_atom(s)

  def to_mudbrick(pair: [k, v]) do
    {to_mudbrick(k), to_mudbrick(v)}
  end

  def to_mudbrick(dictionary: []), do: %{}

  def to_mudbrick(dictionary: pairs) do
    for {:pair, [k, v]} <- pairs, into: %{} do
      {to_mudbrick(k), to_mudbrick(v)}
    end
  end

  def to_mudbrick([]), do: []

  def to_mudbrick([[{:indirect_object, _} | _rest] = unwrapped]) do
    to_mudbrick(unwrapped)
  end

  def to_mudbrick([
        {:indirect_object,
         [
           ref_number,
           _version,
           {:dictionary, pairs}
         ]}
        | rest
      ]) do
    [
      Indirect.Ref.new(ref_number)
      |> Indirect.Object.new(
        pairs
        |> Enum.map(&to_mudbrick/1)
        |> Enum.into(%{})
      )
      | to_mudbrick(rest)
    ]
  end

  def to_mudbrick([
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
    additional_entries =
      pairs
      |> Enum.map(&to_mudbrick/1)
      |> Map.new()
      |> Map.drop([:Length])

    [
      Indirect.Ref.new(ref_number)
      |> Indirect.Object.new(
        Mudbrick.Stream.new(
          compress: additional_entries[:Filter] == [:FlateDecode],
          data: stream,
          additional_entries: additional_entries
        )
      )
      | to_mudbrick(rest)
    ]
  end

  def to_mudbrick([
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
      |> Indirect.Ref.new()
    ]
  end
end
