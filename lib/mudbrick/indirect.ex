defmodule Mudbrick.Indirect do
  @moduledoc false

  defmodule Ref do
    @type t :: %__MODULE__{
            number: number()
          }

    defstruct [:number]

    @doc false
    def new(number) do
      %__MODULE__{number: number}
    end

    defimpl Mudbrick.Object do
      def to_iodata(%Ref{number: number}) do
        [to_string(number), " 0 R"]
      end
    end
  end

  defmodule Object do
    @type t :: %__MODULE__{
            value: term(),
            ref: Ref.t()
          }

    defstruct [:value, :ref]

    @doc false
    def new(ref, value) do
      %__MODULE__{value: value, ref: ref}
    end

    defimpl Mudbrick.Object do
      def to_iodata(%Object{value: value, ref: ref}) do
        [to_string(ref.number), " 0 obj\n", Mudbrick.Object.to_iodata(value), "\nendobj"]
      end
    end
  end
end
