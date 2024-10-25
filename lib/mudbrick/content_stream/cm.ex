defmodule Mudbrick.ContentStream.Cm do
  @moduledoc false
  defstruct scale: {0, 0},
            skew: {0, 0},
            position: {0, 0}

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
