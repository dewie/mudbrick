defmodule Mudbrick.ContentStream.L do
  @moduledoc false

  @enforce_keys :coords
  defstruct [:coords]

  defimpl Mudbrick.Object do
    def to_iodata(%Mudbrick.ContentStream.L{coords: {x, y}}) do
      Enum.map_intersperse([x, y, "l"], " ", &to_string/1)
    end
  end
end
