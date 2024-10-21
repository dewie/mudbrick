defmodule Mudbrick.Predicates do
  def has_text?(pdf, text) do
    binary = IO.iodata_to_binary(pdf)
    String.contains?(binary, text)
  end

  def has_text?(pdf, text, in_font: font) do
    binary = IO.iodata_to_binary(pdf)
    parsed_font = OpenType.new() |> OpenType.parse(font)

    {glyph_ids_decimal, _positions} =
      OpenType.layout_text(parsed_font, text)

    glyph_ids_hex = Enum.map_join(glyph_ids_decimal, "", &Mudbrick.to_hex/1)

    streams = extract_streams(binary)
    Enum.any?(streams, &String.contains?(&1, glyph_ids_hex))
  end

  defp extract_streams(pdf) do
    ~r"<<(.*?)>>\nstream\n(.*?)endstream"s
    |> Regex.scan(pdf, capture: :all_but_first)
    |> Enum.map(fn
      [dictionary, content] ->
        if String.contains?(dictionary, "FlateDecode") do
          Mudbrick.decompress(content) |> IO.iodata_to_binary()
        else
          content
        end
    end)
  end
end
