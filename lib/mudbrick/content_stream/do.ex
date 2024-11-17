defmodule Mudbrick.ContentStream.Do do
  @moduledoc false
  defstruct [:image]

  defimpl Mudbrick.Object do
    def to_iodata(operator) do
      [
        Mudbrick.Object.to_iodata(operator.image.resource_identifier),
        " Do"
      ]
    end
  end
end
