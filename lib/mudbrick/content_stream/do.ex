defmodule Mudbrick.ContentStream.Do do
  @moduledoc false
  defstruct [:image_identifier]

  defimpl Mudbrick.Object do
    def to_iodata(operator) do
      [
        Mudbrick.Object.to_iodata(operator.image_identifier),
        " Do"
      ]
    end
  end
end
