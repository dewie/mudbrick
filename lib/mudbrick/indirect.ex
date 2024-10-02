defmodule Mudbrick.Indirect.Object do
  defstruct [:value, :reference]

  def new(reference, value) do
    %Mudbrick.Indirect.Object{value: value, reference: reference}
  end
end

defmodule Mudbrick.Indirect.Reference do
  defstruct [:number]

  def new(number) do
    %Mudbrick.Indirect.Reference{number: number}
  end
end
