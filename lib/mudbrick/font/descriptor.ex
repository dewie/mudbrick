defmodule Mudbrick.Font.Descriptor do
  @moduledoc false

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
    struct!(__MODULE__, opts)
  end

  defimpl Mudbrick.Object do
    def to_iodata(descriptor) do
      Mudbrick.Object.to_iodata(%{
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
