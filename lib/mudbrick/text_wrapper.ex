defmodule Mudbrick.TextWrapper do
  @moduledoc """
  Automatic text wrapping utilities for Mudbrick TextBlocks.

  Provides functions to automatically wrap long text into multiple lines
  that fit within specified width constraints.
  """

  @doc """
  Wrap text to fit within a maximum width using font metrics.

  ## Parameters
  - `text`: The text to wrap
  - `font`: The font to use for width calculations
  - `font_size`: The font size
  - `max_width`: Maximum width in points
  - `opts`: Additional options

  ## Options
  - `:break_words` - Whether to break long words (default: false)
  - `:hyphenate` - Whether to add hyphens when breaking words (default: false)
  - `:indent` - Indentation for wrapped lines (default: 0)
  - `:justify` - Text justification (:left, :right, :center, :justify) (default: :left)

  ## Examples

      text = "This is a very long line of text that should be wrapped automatically to fit within the specified width constraints."

      wrapped_lines = Mudbrick.TextWrapper.wrap_text(
        text,
        font,
        12,
        200,
        break_words: true,
        justify: :justify
      )

      # Returns justified lines with proper spacing
  """
  def wrap_text(text, font, font_size, max_width, opts \\ [])

  # Handle nil font case for testing
  def wrap_text(text, nil, _font_size, _max_width, _opts) do
    text
    |> String.replace("\r\n", "\n")
    |> String.split("\n")
  end

  def wrap_text(text, font, font_size, max_width, opts) do
    break_words = Keyword.get(opts, :break_words, false)
    hyphenate = Keyword.get(opts, :hyphenate, false)
    indent = Keyword.get(opts, :indent, 0)
    justify = Keyword.get(opts, :justify, :left)

    text
    |> String.replace("\r\n", "\n")
    |> String.split("\n")
    |> Enum.flat_map(fn
      "" ->
        [""]

      paragraph ->
        words = String.split(paragraph, ~r/[ \t]+/, trim: true)
        raw_lines = wrap_words(words, font, font_size, max_width, indent, break_words, hyphenate, [], "")
        justify_lines(raw_lines, font, font_size, max_width, indent, justify)
    end)
  end

  @doc """
  Wrap text and return a TextBlock with proper formatting.

  ## Examples

      text_block = Mudbrick.TextWrapper.wrap_to_text_block(
        "Long text here...",
        font: font,
        font_size: 12,
        max_width: 200,
        position: {50, 700}
      )
  """
  def wrap_to_text_block(text, opts) do
    font = Keyword.fetch!(opts, :font)
    font_size = Keyword.fetch!(opts, :font_size)
    max_width = Keyword.fetch!(opts, :max_width)
    wrap_opts = Keyword.take(opts, [:break_words, :hyphenate, :indent])

    wrapped_lines = wrap_text(text, font, font_size, max_width, wrap_opts)

    text_block_opts = Keyword.drop(opts, [:max_width, :break_words, :hyphenate, :indent])

    text_block = Mudbrick.TextBlock.new(text_block_opts)

    Enum.reduce(wrapped_lines, text_block, fn line, tb ->
      Mudbrick.TextBlock.write(tb, line)
    end)
  end

  # Private helper functions

  defp wrap_words([], _font, _font_size, _max_width, _indent, _break_words, _hyphenate, acc, current_line) do
    if current_line == "" do
      Enum.reverse(acc)
    else
      Enum.reverse([current_line | acc])
    end
  end

  defp wrap_words([word | rest], font, font_size, max_width, indent, break_words, hyphenate, acc, current_line) do
    # Calculate width of current line + word + space
    test_line = if current_line == "", do: word, else: current_line <> " " <> word
    test_width = Mudbrick.Font.width(font, font_size, test_line, auto_kern: true)

    # Add indentation to wrapped lines (except first line)
    indent_width = if current_line == "", do: 0, else: indent
    total_width = test_width + indent_width

    cond do
      total_width <= max_width ->
        # Word fits, add it to current line
        wrap_words(rest, font, font_size, max_width, indent, break_words, hyphenate, acc, test_line)

      current_line == "" ->
        # Single word is too long
        if break_words do
          {broken_lines, remaining_word} = break_word(word, font, font_size, max_width, indent, hyphenate)
          wrap_words(rest, font, font_size, max_width, indent, break_words, hyphenate,
                    Enum.reverse(broken_lines) ++ acc, remaining_word)
        else
          # Keep the word as-is (it will overflow)
          wrap_words(rest, font, font_size, max_width, indent, break_words, hyphenate, [word | acc], "")
        end

      true ->
        # Current line is full, start new line
        new_acc = [current_line | acc]
        wrap_words(rest, font, font_size, max_width, indent, break_words, hyphenate, new_acc, word)
    end
  end

  defp break_word(word, font, font_size, max_width, indent, hyphenate) do
    break_word_recursive(word, font, font_size, max_width, indent, hyphenate, [], "")
  end

  defp break_word_recursive("", _font, _font_size, _max_width, _indent, _hyphenate, acc, remaining) do
    {Enum.reverse(acc), remaining}
  end

  defp break_word_recursive(word, font, font_size, max_width, indent, hyphenate, acc, current) do
    <<char::utf8, rest::binary>> = word
    test_current = current <> <<char::utf8>>
    test_width = Mudbrick.Font.width(font, font_size, test_current, auto_kern: true)

    # Add indentation to wrapped lines
    indent_width = if current == "", do: 0, else: indent
    total_width = test_width + indent_width

    if total_width <= max_width do
      break_word_recursive(rest, font, font_size, max_width, indent, hyphenate, acc, test_current)
    else
      # Current segment is full
      hyphenated_current = if hyphenate and current != "", do: current <> "-", else: current
      new_acc = [hyphenated_current | acc]
      break_word_recursive(rest, font, font_size, max_width, indent, hyphenate, new_acc, <<char::utf8>>)
    end
  end

  # Apply justification to wrapped lines
  @doc false
  defp justify_lines(lines, font, font_size, max_width, indent, justify) do
    case justify do
      :left -> justify_left(lines, indent)
      :right -> justify_right(lines, font, font_size, max_width, indent)
      :center -> justify_center(lines, font, font_size, max_width, indent)
      :justify -> justify_text(lines, font, font_size, max_width, indent)
      _ -> justify_left(lines, indent)
    end
  end

  # Left justification (default) - just add indentation
  @doc false
  defp justify_left(lines, indent) do
    Enum.with_index(lines, fn line, index ->
      if index == 0 or line == "" do
        line
      else
        String.duplicate(" ", div(indent, 4)) <> line  # Approximate space width
      end
    end)
  end

  # Right justification - align text to the right edge
  @doc false
  defp justify_right(lines, font, font_size, max_width, indent) do
    Enum.map(lines, fn line ->
      if line == "" do
        ""
      else
        line_width = Mudbrick.Font.width(font, font_size, line, auto_kern: true)
        available_width = max_width - indent
        spaces_needed = max(0, available_width - line_width)

        # Calculate number of spaces needed (approximate)
        space_width = Mudbrick.Font.width(font, font_size, " ", auto_kern: true)
        num_spaces = max(0, trunc(spaces_needed / space_width))

        String.duplicate(" ", num_spaces) <> line
      end
    end)
  end

  # Center justification - center text between margins
  @doc false
  defp justify_center(lines, font, font_size, max_width, indent) do
    Enum.map(lines, fn line ->
      if line == "" do
        ""
      else
        line_width = Mudbrick.Font.width(font, font_size, line, auto_kern: true)
        available_width = max_width - indent
        spaces_needed = max(0, available_width - line_width)

        # Calculate number of spaces needed for centering
        space_width = Mudbrick.Font.width(font, font_size, " ", auto_kern: true)
        num_spaces = max(0, trunc(spaces_needed / (2 * space_width)))

        String.duplicate(" ", num_spaces) <> line
      end
    end)
  end

  # Justify text - distribute spaces evenly between words
  @doc false
  defp justify_text(lines, font, font_size, max_width, indent) do
    Enum.with_index(lines, fn line, index ->
      if line == "" or index == length(lines) - 1 do
        # Don't justify empty lines or the last line
        if index > 0 do
          String.duplicate(" ", div(indent, 4)) <> line
        else
          line
        end
      else
        justify_line(line, font, font_size, max_width, indent)
      end
    end)
  end

  # Justify a single line by distributing spaces between words
  @doc false
  defp justify_line(line, font, font_size, max_width, indent) do
    words = String.split(line, ~r/\s+/)

    if length(words) <= 1 do
      # Can't justify single words
      String.duplicate(" ", div(indent, 4)) <> line
    else
      # Calculate current width and needed width
      current_width = Mudbrick.Font.width(font, font_size, line, auto_kern: true)
      available_width = max_width - indent
      spaces_needed = max(0, available_width - current_width)

      # Calculate space width
      space_width = Mudbrick.Font.width(font, font_size, " ", auto_kern: true)

      # Distribute spaces between words
      gaps = length(words) - 1
      spaces_per_gap = if gaps > 0, do: trunc(spaces_needed / (gaps * space_width)), else: 0
      extra_spaces = if gaps > 0, do: rem(trunc(spaces_needed / space_width), gaps), else: 0

      # Build justified line
      justified_words =
        words
        |> Enum.with_index()
        |> Enum.map(fn {word, index} ->
          if index == 0 do
            word
          else
            spaces = spaces_per_gap + (if index <= extra_spaces, do: 1, else: 0)
            String.duplicate(" ", spaces) <> word
          end
        end)

      String.duplicate(" ", div(indent, 4)) <> Enum.join(justified_words, "")
    end
  end
end
