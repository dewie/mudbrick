defmodule Mudbrick.ContentStream.Re do
  @moduledoc false

  @enforce_keys [:lower_left, :dimensions]
  defstruct [:lower_left, :dimensions]

  defimpl Mudbrick.Object do
    def to_iodata(%Mudbrick.ContentStream.Re{lower_left: {x, y}, dimensions: {width, height}}) do
      Enum.map_intersperse([x, y, width, height, "re"], " ", &to_string/1)
    end
  end
end
