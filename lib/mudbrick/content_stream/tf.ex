defmodule Mudbrick.ContentStream.Tf do
  @moduledoc false
  defstruct [:font, :size]

  def current!(content_stream) do
    content_stream.value.current_tf || raise Mudbrick.Font.NotSet, "No font chosen"
  end

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
