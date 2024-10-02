defmodule Mudbrick.Indirect.Object do
  defstruct [:value, :reference]

  def new(reference, value) do
    %Mudbrick.Indirect.Object{value: value, reference: reference}
  end

  defimpl Mudbrick.Object do
    def from(%Mudbrick.Indirect.Object{value: value, reference: reference}) do
      """
      #{reference.number} 0 obj
      #{Mudbrick.Object.from(value)}
      endobj\
      """
    end
  end
end

defmodule Mudbrick.Indirect.Reference do
  defstruct [:number]

  def new(number) do
    %Mudbrick.Indirect.Reference{number: number}
  end

  defimpl Mudbrick.Object do
    def from(%Mudbrick.Indirect.Reference{number: number}) do
      "#{number} 0 R"
    end
  end
end
