defmodule Mudbrick.ContentStream.Tf do
  @moduledoc false
  @enforce_keys [:font, :size]
  defstruct [:font, :size]

  defimpl Mudbrick.Object do
    def from(tf) do
      [
        Mudbrick.Object.from(tf.font.resource_identifier),
        " ",
        to_string(tf.size),
        " Tf"
      ]
    end
  end
end
