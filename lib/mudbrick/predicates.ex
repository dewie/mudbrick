defmodule Mudbrick.Predicates do
  @moduledoc """
  Useful for testing PDF documents.

  While these predicates do check the PDF in a black-box way, it's not expected
  that they will work on all PDFs found in the wild.
  """

  @doc """
  Checks for presence of `text` in the `pdf` `iodata`. Searches compressed and uncompressed data.

  This arity only works with text that can be found in literal form inside a stream, compressed or uncompressed, 
  """
  @spec has_text?(pdf :: iodata(), text :: binary()) :: boolean()
  def has_text?(pdf, text) do
    binary = IO.iodata_to_binary(pdf)
    streams = extract_streams(binary)
    Enum.any?(streams, &String.contains?(&1, text))
  end

  @doc """
  Checks for presence of `text` in the `pdf` `iodata`. Searches compressed and uncompressed data.

  This arity requires you to pass the raw font data in which the text is
  expected to be written. It must be present in raw hexadecimal form
  corresponding to the font's glyph IDs.

  The [OpenType](https://hexdocs.pm/opentype) library is used to find font
  features, such as ligatures, which are expected to have been used in the PDF.

  ## Options

  - `:in_font` - raw font data in which the text is expected.

  ## Example

      iex> Mudbrick.Predicates.has_text?("some-pdf", "hello", in_font: Mudbrick.TestHelper.bodoni())
  """
  @spec has_text?(pdf :: iodata(), text :: binary(), opts :: list()) :: boolean()
  def has_text?(pdf, text, opts) do
    font = Keyword.fetch!(opts, :in_font)
    parsed_font = OpenType.new() |> OpenType.parse(font)
    {glyph_ids_decimal, _positions} = OpenType.layout_text(parsed_font, text)
    glyph_ids_hex = Enum.map_join(glyph_ids_decimal, "", &Mudbrick.to_hex/1)

    has_text?(pdf, glyph_ids_hex)
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
