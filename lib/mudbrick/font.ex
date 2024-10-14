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

  defmodule Unregistered do
    defexception [:message]
  end

  alias Mudbrick.Document
  alias Mudbrick.Font
  alias Mudbrick.Stream

  def new(opts) do
    case Keyword.fetch(opts, :parsed) do
      {:ok, parsed} ->
        {:name, font_type} = Map.fetch!(parsed, "SubType")
        struct!(Mudbrick.Font, Keyword.put(opts, :type, type!(font_type)))

      :error ->
        struct!(Mudbrick.Font, opts)
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
      Mudbrick.Stream.new(
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

  defmodule CMap do
    defstruct [:parsed]

    def new(opts) do
      struct!(CMap, opts)
    end

    defimpl Mudbrick.Object do
      def from(cmap) do
        pairs =
          cmap.parsed.gid2cid
          |> Enum.map(fn {gid, cid} ->
            ["<", Mudbrick.to_hex(gid), "> <", Mudbrick.to_hex(cid), ">\n"]
          end)
          |> Enum.sort()

        data = [
          """
          /CIDInit /ProcSet findresource begin
          12 dict begin
          begincmap
          /CIDSystemInfo
          << /Registry (Adobe)
             /Ordering (UCS)
             /Supplement 0
          >> def
          /CMapName /Adobe-Identity-UCS def
          /CMapType 2 def
          1 begincodespacerange
          <0000> <ffff>
          endcodespacerange
          """,
          pairs |> length() |> to_string(),
          """
           beginbfchar
          """,
          pairs,
          """
          endbfchar
          endcmap
          CMapName currentdict /CMap defineresource pop
          end
          end\
          """
        ]

        Mudbrick.Object.from(Stream.new(data: data))
      end
    end
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

  defmodule CIDFont do
    @enforce_keys [
      :default_width,
      :descriptor,
      :font_name,
      :type,
      :widths
    ]
    defstruct [
      :default_width,
      :descriptor,
      :font_name,
      :type,
      :widths
    ]

    def new(opts) do
      struct!(__MODULE__, opts)
    end

    defimpl Mudbrick.Object do
      def from(cid_font) do
        Mudbrick.Object.from(%{
          Type: :Font,
          Subtype: cid_font.type,
          BaseFont: cid_font.font_name,
          CIDSystemInfo: %{
            Registry: "Adobe",
            Ordering: "Identity",
            Supplement: 0
          },
          FontDescriptor: cid_font.descriptor.ref,
          DW: cid_font.default_width,
          W: [0, cid_font.widths]
        })
      end
    end
  end

  defmodule Descriptor do
    @enforce_keys [
      :ascent,
      :bounding_box,
      :cap_height,
      :descent,
      :file,
      :flags,
      :font_name,
      :italic_angle,
      :stem_vertical
    ]
    defstruct [
      :ascent,
      :bounding_box,
      :cap_height,
      :descent,
      :file,
      :flags,
      :font_name,
      :italic_angle,
      :stem_vertical
    ]

    def new(opts) do
      struct!(Descriptor, opts)
    end

    defimpl Mudbrick.Object do
      def from(descriptor) do
        Mudbrick.Object.from(%{
          Ascent: descriptor.ascent,
          CapHeight: descriptor.cap_height,
          Descent: descriptor.descent,
          Flags: descriptor.flags,
          FontBBox: descriptor.bounding_box,
          FontFile3: descriptor.file.ref,
          FontName: descriptor.font_name,
          ItalicAngle: descriptor.italic_angle,
          StemV: descriptor.stem_vertical,
          Type: :FontDescriptor
        })
      end
    end
  end

  defimpl Mudbrick.Object do
    def from(font) do
      Mudbrick.Object.from(
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
