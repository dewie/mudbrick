defmodule Mudbrick.ContentStream.Tf do
  @moduledoc false
  @enforce_keys [:font, :size]
  defstruct [:font, :size]

  defimpl Mudbrick.Object do
    def to_iodata(tf) do
      [
        Mudbrick.Object.to_iodata(tf.font.resource_identifier),
        " ",
        to_string(tf.size),
        " Tf"
      ]
    end
  end
end
