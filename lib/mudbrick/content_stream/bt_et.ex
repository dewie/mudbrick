defmodule Mudbrick.ContentStream.BT do
  @moduledoc false
  defstruct []

  defimpl Mudbrick.Object do
    def to_iodata(_), do: ["BT"]
  end
end

defmodule Mudbrick.ContentStream.ET do
  @moduledoc false
  defstruct []

  defimpl Mudbrick.Object do
    def to_iodata(_), do: ["ET"]
  end
end
