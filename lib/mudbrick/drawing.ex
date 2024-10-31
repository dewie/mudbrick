defmodule Mudbrick.Drawing do
  defstruct lines: []

  def new() do
    struct!(__MODULE__, [])
  end

  defmodule Path do
    @enforce_keys [:from, :to]
    defstruct [:from, :to]

    def new(drawing, opts) do
      Map.update!(drawing, :lines, fn lines ->
        [struct!(__MODULE__, opts) | lines]
      end)
    end
  end
end
