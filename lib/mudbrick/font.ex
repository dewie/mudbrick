defmodule Mudbrick.Font do
  @enforce_keys [
    :name,
    :resource_identifier,
    :type
  ]

  defstruct [
    :descendant,
    :encoding,
    :name,
    :resource_identifier,
    :to_unicode,
    :type,
    :parsed
  ]

  defmodule NotMeasured do
    defexception [:message]
  end

  defmodule NotSet do
    defexception [:message]
  end

  defmodule Unregistered do
    defexception [:message]
  end

  alias __MODULE__
  alias Mudbrick.Document
  alias Mudbrick.Font.CMap
  alias Mudbrick.Object
  alias Mudbrick.Stream

  def new(opts) do
    case Keyword.fetch(opts, :parsed) do
      {:ok, parsed} ->
        {:name, font_type} = Map.fetch!(parsed, "SubType")
        struct!(__MODULE__, Keyword.put(opts, :type, type!(font_type)))

      :error ->
        struct!(__MODULE__, opts)
    end
  end

  def type!(s), do: Map.fetch!(%{"Type0" => :Type0}, s)

  def add_objects(doc, fonts) do
    {doc, font_objects, _id} =
      for {human_name, font_opts} <- fonts, reduce: {doc, %{}, 0} do
        {doc, font_objects, id} ->
          font_opts =
            Keyword.put(font_opts, :resource_identifier, :"F#{id + 1}")

          {doc, font} =
            case Keyword.pop(font_opts, :file) do
              {nil, font_opts} ->
                Document.add(doc, new(font_opts))

              {file_contents, font_opts} ->
                opentype =
                  OpenType.new()
                  |> OpenType.parse(file_contents)

                font_name = String.to_atom(opentype.name)

                doc
                |> add_font_file(file_contents)
                |> add_descriptor(opentype, font_name)
                |> add_cid_font(opentype, font_name)
                |> add_font(opentype, font_name, font_opts)
            end

          {doc, Map.put(font_objects, human_name, font), id + 1}
      end

    {doc, font_objects}
  end

  defp add_font_file(doc, contents) do
    doc
    |> Document.add(
      Stream.new(
        data: contents,
        additional_entries: %{
          Length1: byte_size(contents),
          Subtype: :OpenType
        }
      )
    )
  end

  defp add_descriptor(doc, opentype, font_name) do
    doc
    |> Document.add(
      &Font.Descriptor.new(
        ascent: opentype.ascent,
        cap_height: opentype.capHeight,
        descent: opentype.descent,
        file: &1,
        flags: opentype.flags,
        font_name: font_name,
        bounding_box: opentype.bbox,
        italic_angle: opentype.italicAngle,
        stem_vertical: opentype.stemV
      )
    )
  end

  defp add_cid_font(doc, opentype, font_name) do
    doc
    |> Document.add(
      &Font.CIDFont.new(
        default_width: opentype.defaultWidth,
        descriptor: &1,
        type: :CIDFontType0,
        font_name: font_name,
        widths: opentype.glyphWidths
      )
    )
  end

  defp add_font({doc, cid_font}, opentype, font_name, font_opts) do
    doc
    |> Document.add(CMap.new(parsed: opentype))
    |> Document.add(fn cmap ->
      Font.new(
        Keyword.merge(font_opts,
          descendant: cid_font,
          encoding: :"Identity-H",
          name: font_name,
          parsed: opentype,
          to_unicode: cmap
        )
      )
    end)
  end

  def width(%Font{parsed: nil}, _size, _text) do
    raise Font.NotMeasured, "Built-in fonts aren't alignable yet"
  end

  def width(_font, _size, "") do
    0
  end

  def width(font, size, text) do
    {glyph_ids, _positions} = OpenType.layout_text(font.parsed, text)

    for id <- glyph_ids, reduce: 0 do
      acc ->
        glyph_width = Enum.at(font.parsed.glyphWidths, id)
        width_in_points = glyph_width / 1000 * size

        acc + width_in_points
    end
  end

  defimpl Mudbrick.Object do
    def from(font) do
      Object.from(
        %{
          Type: :Font,
          BaseFont: font.name,
          Subtype: font.type
        }
        |> optional(:Encoding, font.encoding)
        |> Map.merge(
          if font.descendant,
            do: %{
              DescendantFonts: [font.descendant.ref],
              ToUnicode: font.to_unicode.ref
            },
            else: %{}
        )
      )
    end

    defp optional(orig, _name, nil) do
      orig
    end

    defp optional(orig, name, value) do
      Map.put(orig, name, value)
    end
  end
end
