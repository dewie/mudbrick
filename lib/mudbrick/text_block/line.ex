defmodule Mudbrick.TextBlock.Line do
  @moduledoc false

  defstruct parts: []

  defmodule Part do
    @moduledoc false

    defstruct colour: {0, 0, 0},
              font: nil,
              font_size: nil,
              text: ""

    def wrap(text, opts) when text != "" do
      struct!(%Part{text: text}, opts)
    end
  end

  def wrap("", _opts) do
    %__MODULE__{}
  end

  def wrap(text, opts) do
    %__MODULE__{parts: [Part.wrap(text, opts)]}
  end

  def text(line) do
    Enum.map_join(line.parts, "", & &1.text)
  end
end
