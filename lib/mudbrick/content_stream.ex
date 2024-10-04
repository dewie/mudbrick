defmodule Mudbrick.ContentStream do
  defstruct [:text]

  alias Mudbrick.Indirect

  def new(opts) do
    struct(Mudbrick.ContentStream, opts)
  end

  def objects(_stream) do
    font =
      Indirect.Reference.new(1)
      |> Indirect.Object.new(%{
        BaseFont: :Helvetica,
        Encoding: :"Identity-H",
        Subtype: :TrueType,
        Type: :Font
        # FontDescriptor: font_descriptor.reference
      })

    [font]
  end
end
