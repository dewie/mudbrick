defmodule Mudbrick.Path do
  @moduledoc false

  defmodule SubPath do
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

  @type t :: %__MODULE__{
          sub_paths: [SubPath.t()]
        }

  defstruct sub_paths: []

  @spec new :: t()
  def new do
    struct!(__MODULE__, [])
  end

  @spec sub_path(t(), SubPath.options()) :: t()
  def sub_path(path, opts) do
    %{path | sub_paths: [SubPath.new(opts) | path.sub_paths]}
  end
end
