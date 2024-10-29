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

  @spec new(options()) :: t()
  def new(opts \\ []) do
    block = struct!(__MODULE__, opts)

    Map.update!(block, :leading, fn
      nil ->
        block.font_size * 1.2

      leading ->
        leading
    end)
  end

  def write(tb, text, opts \\ []) do
    line_texts = String.split(text, "\n")
    opts = Keyword.put_new(opts, :leading, tb.leading)

    Map.update!(tb, :lines, fn
      [] ->
        add_texts([], line_texts, opts)

      existing_lines ->
        case line_texts do
          # \n at beginning of new line
          ["" | new_line_texts] ->
            existing_lines
            |> add_texts(new_line_texts, opts)

          # didn't start with \n, so first part belongs to previous line
          [first_new_line_text | new_line_texts] ->
            existing_lines
            |> update_previous_line(first_new_line_text, opts)
            |> add_texts(new_line_texts, opts)
        end
    end)
  end

  defp update_previous_line([previous_line | existing_lines], first_new_line_text, opts) do
    [
      Line.append(previous_line, first_new_line_text, opts)
      | existing_lines
    ]
  end

  defp add_texts(existing_lines, new_line_texts, opts) do
    for text <- new_line_texts, reduce: existing_lines do
      acc -> [Line.wrap(text, opts) | acc]
    end
  end
end
