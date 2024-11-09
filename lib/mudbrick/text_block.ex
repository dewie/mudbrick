defmodule Mudbrick.TextBlock do
  @type alignment :: :left | :right

  @type option ::
          {:align, alignment()}
          | {:colour, Mudbrick.colour()}
          | {:font, atom()}
          | {:font_size, number()}
          | {:leading, number()}
          | {:position, Mudbrick.coords()}

  @type options :: [option()]

  @type part_option ::
          {:colour, Mudbrick.colour()}
          | {:font, atom()}
          | {:font_size, number()}
          | {:leading, number()}

  @type part_options :: [part_option()]

  @type write_tuple :: {String.t(), part_options()}

  @type write ::
          String.t()
          | write_tuple()
          | list(write_tuple())

  @type t :: %__MODULE__{
          align: alignment(),
          colour: Mudbrick.colour(),
          font: atom(),
          font_size: number(),
          lines: list(),
          position: Mudbrick.coords(),
          leading: number()
        }

  defstruct align: :left,
            colour: {0, 0, 0},
            font: nil,
            font_size: 12,
            lines: [],
            position: {0, 0},
            leading: nil

  alias Mudbrick.TextBlock.Line

  @doc false
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

  @doc false
  @spec write(t(), String.t(), options()) :: t()
  def write(tb, text, opts \\ []) do
    line_texts = String.split(text, "\n")

    text_block_opts = [
      colour: tb.colour,
      font_size: tb.font_size,
      font: tb.font,
      leading: tb.leading
    ]

    opts =
      Keyword.merge(
        text_block_opts,
        opts,
        &prefer_lhs_over_nil/3
      )

    Map.update!(tb, :lines, fn
      [] ->
        add_texts([], line_texts, opts, text_block_opts)

      existing_lines ->
        case line_texts do
          # \n at beginning of new line
          ["" | new_line_texts] ->
            existing_lines
            |> add_texts(new_line_texts, opts, text_block_opts)

          # didn't start with \n, so first part belongs to previous line
          [first_new_line_text | new_line_texts] ->
            existing_lines
            |> update_previous_line(first_new_line_text, opts)
            |> add_texts(new_line_texts, opts, text_block_opts)
        end
    end)
  end

  defp update_previous_line([previous_line | existing_lines], first_new_line_text, opts) do
    [
      Line.append(previous_line, first_new_line_text, opts)
      | existing_lines
    ]
  end

  defp add_texts(existing_lines, new_line_texts, opts, opts_for_empty_lines) do
    for text <- new_line_texts, reduce: existing_lines do
      acc ->
        if text == "" do
          [Line.wrap(text, opts_for_empty_lines) | acc]
        else
          [Line.wrap(text, opts) | acc]
        end
    end
  end

  defp prefer_lhs_over_nil(_key, lhs, nil), do: lhs
  defp prefer_lhs_over_nil(_key, _lhs, rhs), do: rhs
end
