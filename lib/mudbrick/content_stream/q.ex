defmodule Mudbrick.ContentStream.QPush do
  @moduledoc false
  defstruct []

  defimpl Mudbrick.Object do
    def from(_), do: ["q"]
  end
end

defmodule Mudbrick.ContentStream.QPop do
  @moduledoc false
  defstruct []

  defimpl Mudbrick.Object do
    def from(_), do: ["Q"]
  end
end
