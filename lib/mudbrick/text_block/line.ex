defmodule Mudbrick.TextBlock.Line do
  @moduledoc false

  @enforce_keys [:leading, :parts]
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

    def new(text, opts) when text != "" do
      struct(__MODULE__, Keyword.put_new(opts, :text, text))
    end
  end

  def wrap("", opts) do
    struct(__MODULE__, opts)
  end

  def wrap(text, opts) do
    struct(__MODULE__, Keyword.put(opts, :parts, [Part.new(text, opts)]))
  end

  def append(line, text, opts) do
    line = Map.update!(line, :parts, &[Part.new(text, opts) | &1])
    new_leading = Keyword.fetch!(opts, :leading)

    if new_leading > line.leading do
      Map.put(line, :leading, new_leading)
    else
      line
    end
  end

  def width(line) do
    for part <- line.parts, reduce: 0.0 do
      acc -> acc + Part.width(part)
    end
  end
end
