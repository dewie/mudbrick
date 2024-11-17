defmodule Mudbrick.ContentStream.TStar do
  @moduledoc false
  defstruct []

  defimpl Mudbrick.Object do
    def to_iodata(_), do: ["T*"]
  end
end
