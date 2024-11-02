defmodule Mudbrick.Path.Output do
  @moduledoc false

  defstruct operations: []

  alias Mudbrick.ContentStream.{
    L,
    M,
    Re,
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
        |> draw(sub_path)
        |> add(%S{})
    end
  end

  def add(%__MODULE__{} = output, op) do
    %{output | operations: [op | output.operations]}
  end

  defp draw(path, %Mudbrick.Path.Rectangle{} = sub_path) do
    path
    |> add(%Re{
      lower_left: sub_path.lower_left,
      dimensions: sub_path.dimensions
    })
  end

  defp draw(path, %Mudbrick.Path.StraightLine{} = sub_path) do
    path
    |> add(%M{coords: sub_path.from})
    |> add(%L{coords: sub_path.to})
  end
end
