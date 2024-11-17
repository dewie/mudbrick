defmodule Mudbrick.ContentStream.W do
  @moduledoc false

  defstruct [:width]

  defimpl Mudbrick.Object do
    def to_iodata(w) do
      [to_string(w.width), " w"]
    end
  end
end
