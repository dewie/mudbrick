defmodule Mudbrick.ContentStream.TStar do
  @moduledoc false
  defstruct []

  defimpl Mudbrick.Object do
    def from(_), do: ["T*"]
  end
end
