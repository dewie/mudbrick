defmodule Mudbrick.Path.Output do
  @moduledoc false

  defstruct operations: []

  alias Mudbrick.ContentStream.{
    L,
    M,
    Rg,
    S,
    W
  }

  def from(%Mudbrick.Path{} = path) do
    for sub_path <- Enum.reverse(path.sub_paths), reduce: %__MODULE__{} do
      acc ->
        {r, g, b} = sub_path.colour

        acc
        |> add(Rg.new(stroking: true, r: r, g: g, b: b))
        |> add(%W{width: sub_path.line_width})
        |> add(%M{coords: sub_path.from})
        |> add(%L{coords: sub_path.to})
        |> add(%S{})
    end
  end

  def add(%__MODULE__{} = output, op) do
    %{output | operations: [op | output.operations]}
  end
end
