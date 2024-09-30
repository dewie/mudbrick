defmodule Mudbrick.IndirectObject do
  defstruct [:value, :number]

  alias Mudbrick.PDFObject

  def new(value, number: number) do
    %Mudbrick.IndirectObject{value: value, number: number}
  end

  def reference(%Mudbrick.IndirectObject{number: number}) do
    "#{number} 0 R"
  end

  defimpl Mudbrick.PDFObject do
    def from(%Mudbrick.IndirectObject{value: value, number: number}) do
      """
      #{number} 0 obj
      #{PDFObject.from(value)}
      endobj
      """
    end
  end
end
