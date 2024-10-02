defmodule Mudbrick.Indirect.Object do
  defstruct [:value, :number]

  alias Mudbrick.Object

  def new(value, number: number) do
    %Mudbrick.Indirect.Object{value: value, number: number}
  end

  defimpl Mudbrick.Object do
    def from(%Mudbrick.Indirect.Object{value: value, number: number}) do
      """
      #{number} 0 obj
      #{Object.from(value)}
      endobj\
      """
    end
  end
end

defmodule Mudbrick.Indirect.Reference do
  defstruct [:referent]

  def new(%Mudbrick.Indirect.Object{} = obj) do
    %Mudbrick.Indirect.Reference{referent: obj}
  end

  defimpl Mudbrick.Object do
    def from(%Mudbrick.Indirect.Reference{referent: referent}) do
      "#{referent.number} 0 R"
    end
  end
end
