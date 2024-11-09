defmodule Mudbrick.TextBlock.Line do
  @moduledoc false

  defstruct leading: nil, parts: []

  defmodule Part do
    @moduledoc false

    @enforce_keys [
      :colour,
      :font,
      :font_size,
      :text
    ]
    defstruct colour: {0, 0, 0},
              font: nil,
              font_size: nil,
              text: ""

    def width(part) do
      Mudbrick.Font.width(
        part.font,
        part.font_size,
        part.text
      )
    end

    def wrap(text, opts) when text != "" do
      struct(__MODULE__, Keyword.put_new(opts, :text, text))
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

  def width(line) do
    for part <- line.parts, reduce: 0.0 do
      acc ->
        acc +
          Part.width(part)
    end
  end
end
