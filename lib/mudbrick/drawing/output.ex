defmodule Mudbrick.Drawing.Output do
  defstruct operations: []

  alias Mudbrick.ContentStream.{
    L,
    M,
    S
  }

  def from(%Mudbrick.Drawing{} = drawing) do
    for path <- Enum.reverse(drawing.paths), reduce: %__MODULE__{} do
      acc ->
        acc
        |> add(%M{coords: path.from})
        |> add(%L{coords: path.to})
        |> add(%S{})
    end
  end

  def add(%__MODULE__{} = output, op) do
    %{output | operations: [op | output.operations]}
  end
end
