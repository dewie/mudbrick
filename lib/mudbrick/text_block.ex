defmodule Mudbrick.TextBlock do
  @moduledoc false

  @type alignment :: :left | :right

  @type option ::
          {:align, alignment()}
          | {:font, atom()}
          | {:font_size, number()}
          | {:position, Mudbrick.coords()}
          | {:leading, number()}

  @type options :: [option()]

  @type t :: %__MODULE__{
          align: alignment(),
          font: atom(),
          font_size: number(),
          lines: list(),
          position: Mudbrick.coords(),
          leading: number()
        }

  defstruct align: :left,
            font: nil,
            font_size: 12,
            lines: [],
            position: {0, 0},
            leading: nil

  alias Mudbrick.TextBlock.Line
  alias Mudbrick.TextBlock.Line.Part

  @spec new(options()) :: t()
  def new(opts \\ []) do
    struct!(__MODULE__, opts)
  end

  def write(tb, text, opts \\ []) do
    Map.update!(tb, :lines, fn
      [] ->
        for text <- String.split(text, "\n"), reduce: [] do
          acc ->
            [Line.wrap(text, opts) | acc]
        end

      [%Line{} = previous_line | existing_lines] ->
        [first_new_line_text | new_line_texts] = String.split(text, "\n")

        new_previous_line =
          if first_new_line_text == "" do
            previous_line
          else
            Map.update!(previous_line, :parts, fn
              parts ->
                [Part.wrap(first_new_line_text, opts) | parts]
            end)
          end

        for text <- new_line_texts, reduce: [new_previous_line | existing_lines] do
          acc ->
            [Line.wrap(text, opts) | acc]
        end
    end)
  end
end
