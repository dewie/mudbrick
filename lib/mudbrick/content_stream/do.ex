defmodule Mudbrick.ContentStream.Do do
  @moduledoc false
  defstruct [:image]

  defimpl Mudbrick.Object do
    def from(operator) do
      [
        Mudbrick.Object.from(operator.image.resource_identifier),
        " Do"
      ]
    end
  end
end
