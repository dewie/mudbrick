defmodule Mudbrick.Path.Output do
  @moduledoc false

  defstruct operations: []

  alias Mudbrick.ContentStream.{
    L,
    M,
    S,
    W
  }

  def from(%Mudbrick.Path{} = path) do
    for path <- Enum.reverse(path.sub_paths), reduce: %__MODULE__{} do
      acc ->
        acc
        |> add(%W{width: path.line_width})
        |> add(%M{coords: path.from})
        |> add(%L{coords: path.to})
        |> add(%S{})
    end
  end

  def add(%__MODULE__{} = output, op) do
    %{output | operations: [op | output.operations]}
  end
end
