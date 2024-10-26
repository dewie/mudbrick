defmodule Mudbrick.TextBlock do
  defstruct font: nil,
            font_size: nil,
            operations: [],
            position: {0, 0}

  alias Mudbrick.ContentStream.{BT, ET}
  alias Mudbrick.ContentStream.Td
  alias Mudbrick.ContentStream.Tf
  alias Mudbrick.ContentStream.{Tj, Apostrophe}
  alias Mudbrick.ContentStream.TL

  def new(opts \\ []) do
    struct!(__MODULE__, opts)
  end

  def write(%__MODULE__{font: font, font_size: font_size, position: {x, y}} = tb, text) do
    tb =
      tb
      |> add(%BT{})
      |> add(%Td{tx: x, ty: y})
      |> add(%Tf{font: font, size: font_size})
      |> add(%TL{leading: font_size * 1.2})

    case String.split(text, "\n") do
      [first | rest] ->
        tb
        |> tj(first)
        |> then(
          &for text <- rest, reduce: &1 do
            acc ->
              apos(acc, text)
          end
        )
    end
    |> add(%ET{})
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
