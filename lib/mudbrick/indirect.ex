defmodule Mudbrick.Indirect do
  defmodule Ref do
    defstruct [:number]

    def new(number) do
      %__MODULE__{number: number}
    end

    defimpl Mudbrick.Object do
      def from(%Ref{number: number}) do
        [to_string(number), " 0 R"]
      end
    end
  end

  defmodule Object do
    defstruct [:value, :ref]

    def new(ref, value) do
      %__MODULE__{value: value, ref: ref}
    end

    defimpl Mudbrick.Object do
      def from(%Object{value: value, ref: ref}) do
        [to_string(ref.number), " 0 obj\n", Mudbrick.Object.from(value), "\nendobj"]
      end
    end
  end
end
