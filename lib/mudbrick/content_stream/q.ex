defmodule Mudbrick.ContentStream.QPush do
  @moduledoc false
  defstruct []

  defimpl Mudbrick.Object do
    def to_iodata(_), do: ["q"]
  end
end

defmodule Mudbrick.ContentStream.QPop do
  @moduledoc false
  defstruct []

  defimpl Mudbrick.Object do
    def to_iodata(_), do: ["Q"]
  end
end
