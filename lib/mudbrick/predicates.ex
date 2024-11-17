defmodule Mudbrick.Predicates do
  @moduledoc """
  Useful for testing PDF documents.

  While these predicates do check the PDF in a black-box way, it's not expected
  that they will work on PDFs not generated with Mudbrick.
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
  expected to be written. The text must be present in TJ operator format, which
  raw hexadecimal form corresponding to the font's glyph IDs, interspersed with
  optional kerning offsets.

  The [OpenType](https://hexdocs.pm/opentype) library is used to find font
  features, such as ligatures, which are expected to have been used in the PDF.

  ## Options

  - `:in_font` - raw font data in which the text is expected. Required.

  ## Example: with compression

      iex> import Mudbrick.TestHelper
      ...> import Mudbrick.Predicates
      ...> import Mudbrick
      ...> font = bodoni_regular()
      ...> raw_pdf =
      ...>   new(compress: true, fonts: %{default: font})
      ...>   |> page()
      ...>   |> text(
      ...>     "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWhello, CO₂!WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
      ...>     font_size: 100
      ...>   )
      ...>   |> render()
      ...>   |> IO.iodata_to_binary()
      ...> {has_text?(raw_pdf, "hello, CO₂!", in_font: font), has_text?(raw_pdf, "good morning!", in_font: font)}
      {true, false}

  ## Example: without compression

      iex> import Mudbrick.TestHelper
      ...> import Mudbrick.Predicates
      ...> import Mudbrick
      ...> font = bodoni_regular()
      ...> raw_pdf =
      ...>   new(compress: false, fonts: %{default: font})
      ...>   |> page()
      ...>   |> text(
      ...>     "Hello, world!",
      ...>     font_size: 100
      ...>   )
      ...>   |> render()
      ...>   |> IO.iodata_to_binary()
      ...> {has_text?(raw_pdf, "Hello, world!", in_font: font), has_text?(raw_pdf, "Good morning!", in_font: font)}
      {true, false}
  """
  @spec has_text?(pdf :: iodata(), text :: binary(), opts :: list()) :: boolean()
  def has_text?(pdf, text, opts) do
    font = Keyword.fetch!(opts, :in_font)
    parsed_font = OpenType.new() |> OpenType.parse(font)

    mudbrick_font = %Mudbrick.Font{
      name: nil,
      resource_identifier: nil,
      type: nil,
      parsed: parsed_font
    }

    pattern_source =
      Mudbrick.Font.kerned(mudbrick_font, text)
      |> Enum.reduce("", &append_glyph_id/2)

    pattern = Regex.compile!(pattern_source)

    pdf
    |> extract_streams()
    |> Enum.any?(&(&1 =~ pattern))
  end

  defp extract_streams(pdf) do
    binary = IO.iodata_to_binary(pdf)

    ~r"<<(.*?)>>\nstream\n(.*?)endstream"s
    |> Regex.scan(binary, capture: :all_but_first)
    |> Enum.map(fn
      [dictionary, content] ->
        if String.contains?(dictionary, "FlateDecode") do
          content |> Mudbrick.decompress() |> IO.iodata_to_binary()
        else
          content
        end
    end)
  end

  defp append_glyph_id({glyph_id, _kerning}, acc) do
    append_glyph_id(glyph_id, acc)
  end

  defp append_glyph_id(glyph_id, acc) do
    "#{acc}<#{glyph_id}>[  \\d]+"
  end
end
