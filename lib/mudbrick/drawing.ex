defmodule Mudbrick.Drawing do
  defstruct paths: []

  defmodule Path do
    @enforce_keys [:from, :to]
    defstruct [:from, :to]

    def new(opts) do
      struct!(__MODULE__, opts)
    end
  end

  def new do
    struct!(__MODULE__, [])
  end

  def path(drawing, opts) do
    %{drawing | paths: [Path.new(opts) | drawing.paths]}
  end
end
