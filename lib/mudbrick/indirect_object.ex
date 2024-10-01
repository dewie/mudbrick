defmodule Mudbrick.IndirectObject do
  defstruct [:value, :number]

  alias Mudbrick.Object

  def new(value, number: number) do
    %Mudbrick.IndirectObject{value: value, number: number}
  end

  defimpl Mudbrick.Object do
    def from(%Mudbrick.IndirectObject{value: value, number: number}) do
      """
      #{number} 0 obj
      #{Object.from(value)}
      endobj\
      """
    end
  end

  defmodule Reference do
    defstruct [:referent]

    def new(%Mudbrick.IndirectObject{} = obj) do
      %Reference{referent: obj}
    end

    defimpl Mudbrick.Object do
      def from(%Mudbrick.IndirectObject.Reference{referent: referent}) do
        "#{referent.number} 0 R"
      end
    end
  end
end
