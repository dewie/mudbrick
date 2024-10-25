defmodule Mudbrick.ContentStream.TL do
  @moduledoc false
  defstruct [:leading]

  defimpl Mudbrick.Object do
    def from(tl) do
      [to_string(tl.leading), " TL"]
    end
  end
end
