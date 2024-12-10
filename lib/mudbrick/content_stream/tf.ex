defmodule Mudbrick.ContentStream.Tf do
  @moduledoc false
  @enforce_keys [:font_identifier, :size]
  defstruct [:font_identifier, :size]

  defimpl Mudbrick.Object do
    def to_iodata(tf) do
      [
        Mudbrick.Object.to_iodata(tf.font_identifier),
        " ",
        to_string(tf.size),
        " Tf"
      ]
    end
  end
end
