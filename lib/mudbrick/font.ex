defmodule Mudbrick.Font do
  @enforce_keys [
    :resource_identifier,
    :name,
    :encoding,
    :type
  ]

  defstruct [
    :resource_identifier,
    :name,
    :encoding,
    :type
  ]

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
