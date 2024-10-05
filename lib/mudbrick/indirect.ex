defmodule Mudbrick.Indirect do
  defmodule Ref do
    defstruct [:number]

    def new(number) do
      %__MODULE__{number: number}
    end
  end

  defmodule Object do
    defstruct [:value, :ref]

    alias Mudbrick.Indirect

    def new(ref, value) do
      %__MODULE__{value: value, ref: ref}
    end

    def renumber(obj, number) do
      %__MODULE__{obj | ref: %Indirect.Ref{obj.ref | number: number}}
    end
  end
end
