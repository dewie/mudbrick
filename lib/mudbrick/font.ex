defmodule Mudbrick.Font do
  @enforce_keys [
    :encoding,
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
    :type
  ]

  def type!(s),
    do:
      %{
        "Type0" => :Type0
      }
      |> Map.fetch!(s)

  defmodule Unregistered do
    defexception [:message]
  end

  defmodule Descendant do
    @enforce_keys [:font_name, :descriptor, :type]
    defstruct [:font_name, :descriptor, :type]

    def new(opts) do
      struct!(__MODULE__, opts)
    end

    defimpl Mudbrick.Object do
      def from(descendant) do
        Mudbrick.Object.from(%{
          Type: :Font,
          BaseFont: descendant.font_name,
          Subtype: descendant.type
        })
      end
    end
  end

  defmodule Descriptor do
    @enforce_keys [:file, :font_name]
    defstruct [:file, :font_name]

    def new(opts) do
      struct!(Descriptor, opts)
    end

    defimpl Mudbrick.Object do
      def from(descriptor) do
        Mudbrick.Object.from(%{
          Type: :FontDescriptor,
          FontName: descriptor.font_name,
          FontFile3: descriptor.file.ref
        })
      end
    end
  end

  def new(opts) do
    struct!(Mudbrick.Font, opts)
  end

  defimpl Mudbrick.Object do
    def from(font) do
      Mudbrick.Object.from(%{
        Type: :Font,
        BaseFont: font.name,
        Encoding: font.encoding,
        Subtype: font.type
      })
    end
  end
end
