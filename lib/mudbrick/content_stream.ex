defmodule Mudbrick.ContentStream do
  @enforce_keys [:page]
  defstruct current_alignment: nil,
            current_width: nil,
            operations: [],
            page: nil

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
    defstruct tx: 0,
              ty: 0,
              purpose: nil

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

  def add(context, operation) do
    update(context, fn contents ->
      Map.update!(contents, :operations, fn operations ->
        [operation | operations]
      end)
    end)
  end

  def add(context, mod, opts) do
    update(context, fn contents ->
      Map.update!(contents, :operations, fn operations ->
        [struct!(mod, opts) | operations]
      end)
    end)
  end

  def write_text({_doc, content_stream} = context, text, opts) do
    tf = Tf.latest!(content_stream)
    old_alignment = content_stream.value.current_alignment
    new_alignment = Keyword.get(opts, :align, :left)

    [first_part | parts] = String.split(text, "\n")

    case first_part do
      "" ->
        context

      text ->
        align(context, text, old_alignment, new_alignment, fn ->
          %Tj{font: tf.font, text: text}
        end)
    end
    |> then(fn context ->
      for part <- parts, reduce: context do
        acc ->
          align(acc, part, old_alignment, new_alignment, fn ->
            %Apostrophe{font: tf.font, text: part}
          end)
      end
    end)
  end

  defp align(context, text, old, new, f) do
    case {old, new} do
      {_, :left} ->
        put(context, current_alignment: :left)

      {:right, :right} ->
        align_right_after_existing(context, text)

      {_, :right} ->
        align_right(context, text)
    end
    |> add(f.())
    |> negate_right_alignment()
  end

  defp align_right({_doc, content_stream} = context, text) do
    tf = Tf.latest!(content_stream)

    case Font.width(tf.font, tf.size, text) do
      0 -> context
      width -> add(context, Td, tx: -width, ty: 0, purpose: :align_right)
    end
    |> put(current_alignment: :right)
  end

  defp align_right_after_existing({_doc, content_stream} = context, text) do
    td = Enum.find(content_stream.value.operations, &match?(%Td{purpose: :align_right}, &1))
    tf = Tf.latest!(content_stream)
    current_text_width = Font.width(tf.font, tf.size, text)
    new_offset_for_previous_text = td.tx - current_text_width

    context
    # existing negation puts us in correct place
    |> update_latest_align(td, new_offset_for_previous_text)
    |> put(current_alignment: :right, current_width: current_text_width)
  end

  defp negate_right_alignment({_doc, cs} = context) do
    if tx = current_right_alignment(cs) do
      add(context, %Td{tx: -tx, purpose: :negate_align_right})
    else
      context
    end
    |> put(current_width: nil)
  end

  defp current_right_alignment(%{value: %{current_width: nil}} = content_stream) do
    case Td.most_recent(content_stream) do
      %Td{purpose: :align_right} = td -> td.tx
      _ -> nil
    end
  end

  defp current_right_alignment(%{value: %{current_width: current_width}}) do
    -current_width
  end

  defp update_latest_align(context, operator, new_offset) do
    update(context, fn contents ->
      %{
        contents
        | operations:
            update_in(contents.operations, [Access.find(&(&1 == operator))], fn o ->
              %{o | tx: new_offset}
            end)
      }
    end)
  end

  defp put(context, fields) do
    update(context, fn contents ->
      struct!(contents, fields)
    end)
  end

  defp update({doc, contents_obj}, f) do
    Document.update(doc, contents_obj, f)
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
