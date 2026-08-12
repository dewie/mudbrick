defmodule Mudbrick.TextWrapper do
  @moduledoc false

  # Breaks text into lines that fit within a maximum width, measured with the
  # given font's own metrics (including kerning). Existing newlines in the text
  # are preserved as hard breaks.

  alias Mudbrick.Font

  @doc """
  Wrap `text` into a list of lines, each fitting within `max_width` points when
  set in `font` at `font_size`.

  Options:

    - `:break_words` - when a single word is wider than `max_width`, break it
      across lines instead of letting it overflow. Default: `false`.
  """
  @spec wrap(String.t(), Font.t(), number(), number(), keyword()) :: [String.t()]
  def wrap(text, font, font_size, max_width, opts \\ []) do
    break_words? = Keyword.get(opts, :break_words, false)

    text
    |> String.replace("\r\n", "\n")
    |> String.split("\n")
    |> Enum.flat_map(fn
      "" ->
        [""]

      paragraph ->
        paragraph
        |> String.split(~r/[ \t]+/, trim: true)
        |> wrap_words("", [], font, font_size, max_width, break_words?)
    end)
  end

  defp wrap_words([], current, lines, _font, _font_size, _max_width, _break_words?) do
    Enum.reverse(flush(current, lines))
  end

  defp wrap_words([word | rest], current, lines, font, font_size, max_width, break_words?) do
    candidate = if current == "", do: word, else: current <> " " <> word

    cond do
      fits?(candidate, font, font_size, max_width) ->
        wrap_words(rest, candidate, lines, font, font_size, max_width, break_words?)

      # The current line already has content; start a fresh line with this word.
      current != "" ->
        wrap_words([word | rest], "", [current | lines], font, font_size, max_width, break_words?)

      # A single word too wide for an empty line, and we're allowed to break it.
      break_words? ->
        {full_lines, remainder} = break_word(word, font, font_size, max_width)
        wrap_words(rest, remainder, full_lines ++ lines, font, font_size, max_width, break_words?)

      # Can't break it; let it overflow on a line of its own.
      true ->
        wrap_words(rest, "", [word | lines], font, font_size, max_width, break_words?)
    end
  end

  # Hard-break a word into chunks that each fit within max_width. Returns the
  # completed chunks (newest first, ready to prepend to the accumulator) and the
  # trailing remainder to continue the next line with.
  defp break_word(word, font, font_size, max_width) do
    word
    |> String.graphemes()
    |> Enum.reduce({[], ""}, fn grapheme, {lines, current} ->
      candidate = current <> grapheme

      if current != "" and not fits?(candidate, font, font_size, max_width) do
        {[current | lines], grapheme}
      else
        {lines, candidate}
      end
    end)
  end

  defp flush("", lines), do: lines
  defp flush(current, lines), do: [current | lines]

  defp fits?(text, font, font_size, max_width) do
    Font.width(font, font_size, text, auto_kern: true) <= max_width
  end
end
