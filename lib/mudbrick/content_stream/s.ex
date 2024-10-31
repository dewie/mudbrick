defmodule Mudbrick.ContentStream.S do
  defstruct []

  defimpl Mudbrick.Object do
    def from(_op) do
      ["S"]
    end
  end
end
