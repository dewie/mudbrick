defmodule Mudbrick.ContentStream.S do
  @moduledoc false

  defstruct []

  defimpl Mudbrick.Object do
    def to_iodata(_op) do
      ["S"]
    end
  end
end
