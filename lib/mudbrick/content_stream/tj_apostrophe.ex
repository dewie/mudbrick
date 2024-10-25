defmodule Mudbrick.ContentStream.Tj do
  @moduledoc false
  defstruct font: nil,
            operator: "Tj",
            text: nil
end

defmodule Mudbrick.ContentStream.Apostrophe do
  @moduledoc false
  defstruct font: nil,
            operator: "'",
            text: nil
end

defimpl Mudbrick.Object, for: [Mudbrick.ContentStream.Tj, Mudbrick.ContentStream.Apostrophe] do
  def from(op) do
    if op.font.descendant && String.length(op.text) > 0 do
      {glyph_ids_decimal, _positions} =
        OpenType.layout_text(op.font.parsed, op.text)

      glyph_ids_hex = Enum.map(glyph_ids_decimal, &Mudbrick.to_hex/1)

      ["<", glyph_ids_hex, "> ", op.operator]
    else
      [Mudbrick.Object.from(op.text), " ", op.operator]
    end
  end
end
