defmodule Mudbrick.ContentStream.TL do
  @moduledoc false
  defstruct [:leading]

  defimpl Mudbrick.Object do
    def to_iodata(tl) do
      [to_string(tl.leading), " TL"]
    end
  end
end
