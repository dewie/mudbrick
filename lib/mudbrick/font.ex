defmodule Mudbrick.Font do
  @enforce_keys [
    :name,
    :resource_identifier,
    :type
  ]

  defstruct [
    :descendant,
    :encoding,
    :first_char,
    :name,
    :resource_identifier,
    :type,
    :parsed
  ]

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

  defmodule Unregistered do
    defexception [:message]
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
            do: %{DescendantFonts: [font.descendant.ref]},
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
