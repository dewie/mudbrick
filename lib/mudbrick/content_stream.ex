defmodule Mudbrick.ContentStream do
  @moduledoc false

  alias Mudbrick.ContentStream.{BT, ET}
  alias Mudbrick.ContentStream.Td
  alias Mudbrick.ContentStream.Tf
  alias Mudbrick.ContentStream.{Tj, Apostrophe}
  alias Mudbrick.Document
  alias Mudbrick.Font

  @enforce_keys [:page]
  defstruct compress: false,
            current_alignment: nil,
            operations: [],
            page: nil,
            current_base_td: %Td{tx: 0, ty: 0},
            current_tf: nil,
            current_tl: nil

  defmodule InvalidColour do
    defexception [:message]
  end

  def new(opts \\ []) do
    struct!(__MODULE__, opts)
  end

  def add(context, nil) do
    context
  end

  def add(context, operation) do
    update_operations(context, fn operations ->
      [operation | operations]
    end)
  end

  def add(context, mod, opts) do
    update_operations(context, fn operations ->
      [struct!(mod, opts) | operations]
    end)
  end

  def write_text({_doc, content_stream} = context, text, opts) do
    tf = Tf.current!(content_stream)
    old_alignment = content_stream.value.current_alignment
    new_alignment = Keyword.get(opts, :align, :left)

    [first_part | parts] = String.split(text, "\n")

    context
    |> then(&if new_alignment == old_alignment, do: ET.remove(&1), else: BT.open(&1))
    |> then(fn context ->
      case first_part do
        "" ->
          context

        text ->
          context
          |> align(
            text,
            old_alignment,
            new_alignment,
            %Tj{font: tf.font, text: text}
          )
      end
      |> then(fn context ->
        for text <- parts, reduce: context do
          context ->
            {context, operator} =
              if new_alignment == :left do
                {track_line(context), %Apostrophe{font: tf.font, text: text}}
              else
                {context
                 |> add(%ET{})
                 |> add(%BT{})
                 |> track_line()
                 |> Td.add_current(), %Tj{font: tf.font, text: text}}
              end

            align(context, text, old_alignment, new_alignment, operator)
        end
      end)
    end)
    |> Mudbrick.ContentStream.add(%ET{})
  end

  def put(context, fields) do
    update(context, fn contents ->
      struct!(contents, fields)
    end)
  end

  defp update({doc, contents_obj}, f) do
    Document.update(doc, contents_obj, f)
  end

  def update_operations(context, f) do
    update(context, fn contents ->
      Map.update!(contents, :operations, f)
    end)
  end

  defp align(context, text, old, new, operator) do
    case {old, new} do
      {_, :left} ->
        put(context, current_alignment: :left)

      {:right, :right} ->
        align_right_after_existing(context, text)

      {_, :right} ->
        align_right(context, text)
    end
    |> add(operator)
  end

  defp align_right({_doc, content_stream} = context, text) do
    tf = Tf.current!(content_stream)

    case Font.width(tf.font, tf.size, text) do
      0 -> context
      width -> add(context, Td, tx: -width, ty: 0, purpose: :align_right)
    end
    |> put(current_alignment: :right)
  end

  defp align_right_after_existing({_doc, content_stream} = context, text) do
    td = Enum.find(content_stream.value.operations, &match?(%Td{purpose: :align_right}, &1))
    tf = Tf.current!(content_stream)
    current_text_width = Font.width(tf.font, tf.size, text)

    context
    |> update_latest_align(td, -current_text_width)
    |> put(current_alignment: :right)
  end

  defp update_latest_align(context, operator, offset) do
    update_operations(context, fn operations ->
      update_in(operations, [Access.find(&(&1 == operator))], fn o ->
        Map.update!(o, :tx, &(&1 + offset))
      end)
    end)
  end

  defp track_line(context) do
    update(context, fn content_stream ->
      Map.update!(content_stream, :current_base_td, fn td ->
        Map.update!(td, :ty, &(&1 - content_stream.current_tl.leading))
      end)
    end)
  end

  defimpl Mudbrick.Object do
    def from(content_stream) do
      Mudbrick.Stream.new(
        compress: content_stream.compress,
        data: [
          content_stream.operations
          |> Enum.reverse()
          |> Mudbrick.join("\n")
        ]
      )
      |> Mudbrick.Object.from()
    end
  end
end
