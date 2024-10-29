defmodule Mudbrick.TextBlock.Line do
  @moduledoc false

  defstruct leading: nil, parts: []

  defmodule Part do
    @moduledoc false

    defstruct colour: {0, 0, 0},
              font: nil,
              font_size: nil,
              text: ""

    def wrap(text, opts) when text != "" do
      struct(%Part{text: text}, opts)
    end
  end

  def wrap("", _prefer_options_from_subsequent_appends) do
    %__MODULE__{}
  end

  def wrap(text, opts) do
    struct(%__MODULE__{parts: [Part.wrap(text, opts)]}, opts)
  end

  def append(line, text, opts) do
    line = Map.update!(line, :parts, &[Part.wrap(text, opts) | &1])
    new_leading = Keyword.fetch!(opts, :leading)

    if line.leading == nil or new_leading > line.leading do
      Map.put(line, :leading, new_leading)
    else
      line
    end
  end

  def text(line) do
    Enum.map_join(line.parts, "", & &1.text)
  end
end
