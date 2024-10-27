defmodule Mudbrick.TextBlock.Line do
  defstruct parts: []

  defmodule Part do
    defstruct colour: {0, 0, 0},
              text: ""

    def wrap(text, opts) do
      struct!(%Part{text: text}, opts)
    end
  end

  def wrap(text, opts) do
    %__MODULE__{parts: [Part.wrap(text, opts)]}
  end
end
