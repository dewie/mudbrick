defmodule Mudbrick.Path.Output do
  @moduledoc false

  defstruct operations: []

  alias Mudbrick.ContentStream.{
    L,
    M,
    QPop,
    QPush,
    Re,
    Rg,
    S,
    W
  }

  def to_iodata(%Mudbrick.Path{sub_paths: []}) do
    %__MODULE__{}
  end

  def to_iodata(%Mudbrick.Path{} = path) do
    %__MODULE__{}
    |> add(%QPush{})
    |> then(fn output ->
      for sub_path <- Enum.reverse(path.sub_paths), reduce: output do
        acc ->
          case sub_path do
            %Mudbrick.Path.Move{} = move ->
              acc
              |> add(%M{coords: move.to})

            %Mudbrick.Path.Line{} = line ->
              {r, g, b} = line.colour

              acc
              |> add(Rg.new(stroking: true, r: r, g: g, b: b))
              |> add(%W{width: line.width})
              |> add(%L{coords: line.to})
              |> add(%S{})

            %Mudbrick.Path.Rectangle{} = rect ->
              {r, g, b} = rect.colour

              acc
              |> add(Rg.new(stroking: true, r: r, g: g, b: b))
              |> add(%W{width: rect.line_width})
              |> add(%Re{
                lower_left: rect.lower_left,
                dimensions: rect.dimensions
              })
              |> add(%S{})
          end
      end
    end)
    |> add(%QPop{})
  end

  def add(%__MODULE__{} = output, op) do
    %{output | operations: [op | output.operations]}
  end
end
