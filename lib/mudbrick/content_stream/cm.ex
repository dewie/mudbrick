defmodule Mudbrick.ContentStream.Cm do
  @type option ::
          {:position, Mudbrick.coords()}
          | {:scale, Mudbrick.coords()}
          | {:skew, Mudbrick.coords()}

  @type options :: [options()]

  @type t :: %__MODULE__{
          position: Mudbrick.coords(),
          scale: Mudbrick.coords(),
          skew: Mudbrick.coords()
        }

  defstruct scale: {0, 0},
            skew: {0, 0},
            position: {0, 0}

  @doc false
  @spec new(options()) :: t()
  def new(opts) do
    struct!(__MODULE__, opts)
  end

  defimpl Mudbrick.Object do
    def from(%Mudbrick.ContentStream.Cm{
          scale: {x_scale, y_scale},
          skew: {x_skew, y_skew},
          position: {x_translate, y_translate}
        }) do
      [
        Mudbrick.join([x_scale, x_skew, y_skew, y_scale, x_translate, y_translate]),
        " cm"
      ]
    end
  end
end
