defmodule Mudbrick.TextBlock.Line do
  @moduledoc false

  defstruct parts: []

  defmodule Part do
    @moduledoc false

    defstruct colour: {0, 0, 0},
              font: nil,
              text: ""

    def wrap(text, opts) do
      struct!(%Part{text: text}, opts)
    end
  end

  def wrap(text, opts) do
    %__MODULE__{parts: [Part.wrap(text, opts)]}
  end
end
