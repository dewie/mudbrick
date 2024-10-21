defmodule Mudbrick.Font.CIDFont do
  @moduledoc false

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
