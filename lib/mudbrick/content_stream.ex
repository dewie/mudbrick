defmodule Mudbrick.ContentStream do
  @enforce_keys [:page]
  defstruct page: nil, operations: []

  alias Mudbrick.Document
  alias Mudbrick.Font

  defmodule Rg do
    defstruct [:r, :g, :b]

    defimpl Mudbrick.Object do
      def from(%Rg{r: r, g: g, b: b}) do
        [[r, g, b] |> Enum.map_join(" ", &to_string/1), " rg"]
      end
    end
  end

  defmodule Tf do
    defstruct [:font, :size]

    def latest!(content_stream) do
      Enum.find(
        content_stream.value.operations,
        &match?(%Tf{}, &1)
      ) || raise Mudbrick.Font.NotSet, "No font chosen"
    end

    defimpl Mudbrick.Object do
      def from(tf) do
        [
          Mudbrick.Object.from(tf.font.resource_identifier),
          " ",
          to_string(tf.size),
          " Tf"
        ]
      end
    end
  end

  defmodule Td do
    defstruct [:tx, :ty, :purpose]

    def most_recent(content_stream) do
      Enum.find(content_stream.value.operations, &match?(%Td{}, &1))
    end

    defimpl Mudbrick.Object do
      def from(td) do
        [td.tx, td.ty, "Td"]
        |> Enum.map(&to_string/1)
        |> Enum.intersperse(" ")
      end
    end
  end

  defmodule TL do
    defstruct [:leading]

    defimpl Mudbrick.Object do
      def from(tl) do
        [to_string(tl.leading), " TL"]
      end
    end
  end

  defmodule Tj do
    defstruct font: nil,
              operator: "Tj",
              text: nil
  end

  defmodule Apostrophe do
    defstruct font: nil,
              operator: "'",
              text: nil
  end

  defimpl Mudbrick.Object, for: [Tj, Apostrophe] do
    def from(op) do
      if op.font.descendant && String.length(op.text) > 0 do
        {glyph_ids_decimal, _positions} =
          OpenType.layout_text(op.font.parsed, op.text)

        glyph_ids_hex = Enum.map(glyph_ids_decimal, &Mudbrick.to_hex/1)

        ["<", glyph_ids_hex, "> ", op.operator]
      else
        [Mudbrick.Object.from(op.text), " ", op.operator]
      end
    end
  end

  def new(opts \\ []) do
    struct!(__MODULE__, opts)
  end

  def add({doc, contents_obj}, operation) do
    Document.update(doc, contents_obj, fn contents ->
      Map.update!(contents, :operations, fn operations ->
        [operation | operations]
      end)
    end)
  end

  def add({doc, contents_obj}, mod, opts) do
    Document.update(doc, contents_obj, fn contents ->
      Map.update!(contents, :operations, fn operations ->
        [struct!(mod, opts) | operations]
      end)
    end)
  end

  def write_text({_doc, content_stream} = context, text, opts) do
    tf = Tf.latest!(content_stream)
    old_alignment = current_alignment(content_stream)

    [first_part | parts] = String.split(text, "\n")

    context = align(context, first_part, opts)

    case {first_part, old_alignment} do
      {"", _} ->
        context

      {text, :left} ->
        add(context, Tj, font: tf.font, text: text)

      {text, :right} ->
        add(context, Apostrophe, font: tf.font, text: text)
    end
    |> negate_right_alignment()
    |> then(fn context ->
      for part <- parts, reduce: context do
        acc ->
          acc
          |> align(part, opts)
          |> add(Apostrophe, font: tf.font, text: part)
          |> negate_right_alignment()
      end
    end)
  end

  defp align(context, "", _opts) when not is_nil(context) do
    context
  end

  defp align({_doc, content_stream} = context, text, opts) do
    case Keyword.get(opts, :align, :left) do
      :left ->
        context

      :right ->
        tf = Tf.latest!(content_stream)
        width = Font.width(tf.font, tf.size, text)
        add(context, Td, tx: -width, ty: 0, purpose: :align_right)
    end
  end

  defp negate_right_alignment({_doc, cs} = context) do
    if td = current_right_alignment(cs) do
      add(context, %{td | tx: -td.tx, purpose: :negate_align_right})
    else
      context
    end
  end

  defp current_alignment(content_stream) do
    case Td.most_recent(content_stream) do
      %Td{purpose: :align_right} -> :right
      %Td{purpose: :negate_align_right} -> :right
      _ -> :left
    end
  end

  defp current_right_alignment(content_stream) do
    case Td.most_recent(content_stream) do
      %Td{purpose: :align_right} = td -> td
      _ -> nil
    end
  end

  defimpl Mudbrick.Object do
    def from(content_stream) do
      Mudbrick.Stream.new(
        data: [
          "BT\n",
          content_stream.operations
          |> Enum.reverse()
          |> Mudbrick.join("\n"),
          "\nET"
        ]
      )
      |> Mudbrick.Object.from()
    end
  end
end
