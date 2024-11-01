defmodule Mudbrick.ContentStream.W do
  @moduledoc false

  defstruct [:width]

  defimpl Mudbrick.Object do
    def from(w) do
      [to_string(w.width), " w"]
    end
  end
end
