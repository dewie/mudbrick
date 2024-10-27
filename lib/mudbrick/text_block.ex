defmodule Mudbrick.TextBlock do
  @moduledoc false

  defstruct align: :left,
            font: nil,
            font_size: 12,
            lines: [],
            position: {0, 0},
            leading: nil

  alias Mudbrick.TextBlock.Line
  alias Mudbrick.TextBlock.Line.Part

  def new(opts \\ []) do
    struct!(__MODULE__, opts)
  end

  def write(tb, text, opts \\ []) do
    Map.update!(tb, :lines, fn
      [] ->
        for text <- String.split(text, "\n"), reduce: [] do
          acc -> [Line.wrap(text, opts) | acc]
        end

      [%Line{} = previous_line | existing_lines] ->
        [first_new_line_text | new_line_texts] = String.split(text, "\n")

        previous_line =
          Map.update!(previous_line, :parts, &[Part.wrap(first_new_line_text, opts) | &1])

        for text <- new_line_texts, reduce: [previous_line | existing_lines] do
          acc -> [Line.wrap(text, opts) | acc]
        end
    end)
  end
end
