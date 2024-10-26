defmodule Mudbrick.TextBlock do
  defstruct align: :left,
            font: nil,
            font_size: nil,
            operations: [],
            position: {0, 0}

  alias Mudbrick.ContentStream.{BT, ET}
  alias Mudbrick.ContentStream.Td
  alias Mudbrick.ContentStream.Tf
  alias Mudbrick.ContentStream.{Tj, Apostrophe}
  alias Mudbrick.ContentStream.TL
  alias Mudbrick.Font

  def new(opts \\ []) do
    struct!(__MODULE__, opts)
  end

  def write(%__MODULE__{align: :right} = tb, text) do
    tb = start(tb)

    split(text, fn
      [first | rest] ->
        tb
        |> right_text(first, 1)
        |> then(fn context ->
          {_n, context} =
            for text <- rest, reduce: {2, context} do
              {line, acc} ->
                {
                  line + 1,
                  acc
                  |> start_block()
                  |> right_text(text, line)
                }
            end

          context
        end)
    end)
  end

  def write(%__MODULE__{position: {x, y}} = tb, text) do
    tb = start(tb)

    split(text, fn
      [first | rest] ->
        tb
        |> add(%Td{tx: x, ty: y})
        |> tj(first)
        |> then(
          &for text <- rest, reduce: &1 do
            acc -> apos(acc, text)
          end
        )
    end)
    |> end_block()
  end

  defp split(text, f) do
    f.(String.split(text, "\n"))
  end

  defp right_text(tb, text, line) do
    tb
    |> right_offset(text, line)
    |> tj(text)
    |> end_block()
  end

  defp right_offset(tb, text, line) do
    n = line - 1
    {x, y} = tb.position

    add(tb, %Td{
      tx: x - Font.width(tb.font, tb.font_size, text),
      ty: y - leading(tb) * n
    })
  end

  defp start(%__MODULE__{font: font, font_size: font_size} = tb) do
    tb
    |> start_block()
    |> add(%Tf{font: font, size: font_size})
    |> add(%TL{leading: leading(tb)})
  end

  defp start_block(tb) do
    add(tb, %BT{})
  end

  defp end_block(tb) do
    add(tb, %ET{})
  end

  defp leading(tb) do
    tb.font_size * 1.2
  end

  defp add(%__MODULE__{} = tb, op) do
    Map.update!(tb, :operations, &[op | &1])
  end

  defp tj(block, text) do
    add(block, %Tj{font: block.font, text: text})
  end

  defp apos(block, text) do
    add(block, %Apostrophe{font: block.font, text: text})
  end
end
