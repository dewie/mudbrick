defmodule Mudbrick.TextWrapper do
  @moduledoc false

  # Breaks text into lines that fit within a maximum width, measured with the
  # given font's own metrics (including kerning). Existing newlines in the text
  # are preserved as hard breaks, and so are runs of spaces inside a line, so
  # that indentation and space-aligned columns survive wrapping. Only the run of
  # spaces that a line is actually broken on is dropped.
  #
  # Tabs are normalised to a single space: none of the usual embedded fonts
  # carries a tab glyph, so passing one through would draw a .notdef box.

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
    |> String.replace("\t", " ")
    |> String.split("\n")
    |> Enum.flat_map(fn
      "" ->
        [""]

      paragraph ->
        {indent, tokens} = split_indent(paragraph)
        wrap_tokens(tokens, indent, [], font, font_size, max_width, break_words?)
    end)
  end

  # Split a paragraph into its leading indentation and an alternating list of
  # word, separator, word, separator, ... tokens.
  defp split_indent(paragraph) do
    case Regex.split(~r/ +/, paragraph, include_captures: true) do
      ["", indent | tokens] -> {indent, tokens}
      tokens -> {"", tokens}
    end
  end

  defp wrap_tokens([], current, lines, _font, _font_size, _max_width, _break_words?) do
    Enum.reverse(flush(current, lines))
  end

  defp wrap_tokens([word | rest], current, lines, font, font_size, max_width, break_words?) do
    place(word, "", rest, current, lines, font, font_size, max_width, break_words?)
  end

  # Place `word` on the current line, preceded by `separator`: the run of spaces
  # that stood between it and the previous word. When the word has to move to a
  # new line that separator is dropped, so no line ends or starts with the
  # spaces it was broken on.
  defp place(word, separator, rest, current, lines, font, font_size, max_width, break_words?) do
    candidate = current <> separator <> word

    cond do
      fits?(candidate, font, font_size, max_width) ->
        continue(rest, candidate, lines, font, font_size, max_width, break_words?)

      # The current line already has a word on it; start a fresh line.
      String.trim(current) != "" ->
        place(word, "", rest, "", [current | lines], font, font_size, max_width, break_words?)

      # Only indentation so far, which we give up to make room for the word.
      current != "" ->
        place(word, "", rest, "", lines, font, font_size, max_width, break_words?)

      # A single word too wide for an empty line, and we're allowed to break it.
      break_words? ->
        {full_lines, remainder} = break_word(word, font, font_size, max_width)
        continue(rest, remainder, full_lines ++ lines, font, font_size, max_width, break_words?)

      # Can't break it; let it overflow on a line of its own.
      true ->
        continue(rest, word, lines, font, font_size, max_width, break_words?)
    end
  end

  defp continue(
         [separator, word | rest],
         current,
         lines,
         font,
         font_size,
         max_width,
         break_words?
       ) do
    place(word, separator, rest, current, lines, font, font_size, max_width, break_words?)
  end

  # Nothing left but possibly a trailing run of spaces.
  defp continue(rest, current, lines, _font, _font_size, _max_width, _break_words?) do
    Enum.reverse(flush(current <> Enum.join(rest), lines))
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
