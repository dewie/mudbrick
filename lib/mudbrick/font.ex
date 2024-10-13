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

  def type!(s),
    do:
      %{
        "Type0" => :Type0
      }
      |> Map.fetch!(s)

  defmodule Unregistered do
    defexception [:message]
  end

  defmodule CIDFont do
    @enforce_keys [:font_name, :descriptor, :type]
    defstruct [:font_name, :descriptor, :type]

    def new(opts) do
      struct!(__MODULE__, opts)
    end

    defimpl Mudbrick.Object do
      def from(descendant) do
        Mudbrick.Object.from(%{
          Type: :Font,
          Subtype: descendant.type,
          BaseFont: descendant.font_name,
          CIDSystemInfo: %{
            Registry: "Adobe",
            Ordering: "Identity",
            Supplement: 0
          },
          FontDescriptor: descendant.descriptor.ref
        })
      end
    end
  end

  defmodule Descriptor do
    @enforce_keys [
      :ascent,
      :bounding_box,
      :file,
      :flags,
      :font_name,
      :italic_angle
    ]
    defstruct [
      :ascent,
      :bounding_box,
      :file,
      :flags,
      :font_name,
      :italic_angle
    ]

    def new(opts) do
      struct!(Descriptor, opts)
    end

    defimpl Mudbrick.Object do
      def from(descriptor) do
        Mudbrick.Object.from(%{
          Ascent: descriptor.ascent,
          Flags: descriptor.flags,
          FontBBox: descriptor.bounding_box,
          FontFile3: descriptor.file.ref,
          FontName: descriptor.font_name,
          ItalicAngle: descriptor.italic_angle,
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
              DescendantFonts: [font.descendant.ref]
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
