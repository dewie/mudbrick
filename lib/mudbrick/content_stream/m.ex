defmodule Mudbrick.ContentStream.M do
  @moduledoc false

  @enforce_keys :coords
  defstruct [:coords]

  defimpl Mudbrick.Object do
    def to_iodata(%Mudbrick.ContentStream.M{coords: {x, y}}) do
      Enum.map_intersperse([x, y, "m"], " ", &to_string/1)
    end
  end
end
