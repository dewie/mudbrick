defmodule Mudbrick.ContentStream.TJ do
  @moduledoc false
  defstruct font: nil,
            text: nil

  defimpl Mudbrick.Object do
    def to_iodata(%Mudbrick.ContentStream.TJ{text: ""}) do
      []
    end

    def to_iodata(op) do
      [
        "[ ",
        Mudbrick.Font.kerned(op.font, op.text)
        |> Enum.map(fn
          {glyph_id, kerning} ->
            ["<", glyph_id, "> ", to_string(kerning), " "]

          glyph_id ->
            ["<", glyph_id, "> "]
        end),
        "] TJ"
      ]
    end
  end
end
