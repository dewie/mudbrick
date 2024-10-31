defmodule Mudbrick.ContentStream.M do
  @enforce_keys :coords
  defstruct [:coords]

  defimpl Mudbrick.Object do
    def from(%Mudbrick.ContentStream.M{coords: {x, y}}) do
      Enum.map_intersperse([x, y, "m"], " ", &to_string/1)
    end
  end
end
