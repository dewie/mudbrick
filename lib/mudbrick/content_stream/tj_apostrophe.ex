defmodule Mudbrick.ContentStream.Tj do
  @moduledoc false
  defstruct font: nil,
            operator: "Tj",
            text: nil
end

defmodule Mudbrick.ContentStream.TJ do
  @moduledoc false
  defstruct font: nil,
            operator: "TJ",
            text: nil

  defimpl Mudbrick.Object do
    def from(%Mudbrick.ContentStream.TJ{text: ""}) do
      []
    end

    def from(op) do
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

defmodule Mudbrick.ContentStream.Apostrophe do
  @moduledoc false
  defstruct font: nil,
            operator: "'",
            text: nil
end

defimpl Mudbrick.Object, for: [Mudbrick.ContentStream.Tj, Mudbrick.ContentStream.Apostrophe] do
  def from(%{text: ""} = op) do
    ["() ", op.operator]
  end

  def from(op) do
    {glyph_ids_decimal, _positions} =
      OpenType.layout_text(op.font.parsed, op.text)

    glyph_ids_hex = Enum.map(glyph_ids_decimal, &Mudbrick.to_hex/1)

    ["<", glyph_ids_hex, "> ", op.operator]
  end
end
