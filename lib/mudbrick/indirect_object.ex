defmodule Mudbrick.IndirectObject do
  defstruct [:value, :number]

  def new(value, number: number) do
    %Mudbrick.IndirectObject{value: value, number: number}
  end

  def reference(%Mudbrick.IndirectObject{number: number}) do
    "#{number} 0 R"
  end

  defimpl String.Chars do
    def to_string(%Mudbrick.IndirectObject{value: value, number: number}) do
      """
      #{number} 0 obj
      #{value}
      endobj
      """
    end
  end
end
