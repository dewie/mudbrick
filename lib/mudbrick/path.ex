defmodule Mudbrick.Path do
  @moduledoc false

  defmodule Rectangle do
    @type option ::
            {:lower_left, Mudbrick.coords()}
            | {:dimensions, Mudbrick.coords()}
            | {:line_width, number()}
            | {:colour, Mudbrick.colour()}

    @type options :: [option()]

    @type t :: %__MODULE__{
            lower_left: Mudbrick.coords(),
            dimensions: Mudbrick.coords(),
            line_width: number(),
            colour: Mudbrick.colour()
          }

    @enforce_keys [:lower_left, :dimensions]
    defstruct lower_left: nil,
              dimensions: nil,
              line_width: 1,
              colour: {0, 0, 0}

    @doc false
    @spec new(options()) :: t()
    def new(opts) do
      struct!(__MODULE__, opts)
    end
  end

  defmodule StraightLine do
    @type option ::
            {:from, Mudbrick.coords()}
            | {:to, Mudbrick.coords()}
            | {:line_width, number()}
            | {:colour, Mudbrick.colour()}

    @type options :: [option()]

    @type t :: %__MODULE__{
            from: Mudbrick.coords(),
            to: Mudbrick.coords(),
            line_width: number(),
            colour: Mudbrick.colour()
          }

    @enforce_keys [:from, :to]
    defstruct from: nil,
              to: nil,
              line_width: 1,
              colour: {0, 0, 0}

    @doc false
    @spec new(options()) :: t()
    def new(opts) do
      struct!(__MODULE__, opts)
    end
  end

  @type sub_path :: Rectangle.t() | StraightLine.t()

  @type t :: %__MODULE__{
          sub_paths: [sub_path()]
        }

  defstruct sub_paths: []

  @spec new :: t()
  def new do
    struct!(__MODULE__, [])
  end

  @spec straight_line(t(), StraightLine.options()) :: t()
  def straight_line(path, opts) do
    add(path, StraightLine.new(opts))
  end

  @spec rectangle(t(), Rectangle.options()) :: t()
  def rectangle(path, opts) do
    add(path, Rectangle.new(opts))
  end

  defp add(path, sub_path) do
    %{path | sub_paths: [sub_path | path.sub_paths]}
  end
end
