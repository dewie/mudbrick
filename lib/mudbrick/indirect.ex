defmodule Mudbrick.Indirect.Reference do
  defstruct [:number]

  def new(number) do
    %Mudbrick.Indirect.Reference{number: number}
  end
end

defmodule Mudbrick.Indirect.Object do
  defstruct [:value, :reference]

  alias Mudbrick.Indirect

  def new(reference, value) do
    %Indirect.Object{value: value, reference: reference}
  end

  def renumber(obj, number) do
    %Indirect.Object{
      obj
      | reference: %Indirect.Reference{obj.reference | number: number}
    }
  end
end
