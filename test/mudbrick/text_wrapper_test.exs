defmodule Mudbrick.TextWrapperTest do
  use ExUnit.Case, async: true

  import Mudbrick
  import Mudbrick.TestHelper, only: [bodoni_regular: 0, operations: 1]

  alias Mudbrick.Font
  alias Mudbrick.TextBlock
  alias Mudbrick.TextBlock.Line
  alias Mudbrick.TextBlock.Line.Part
  alias Mudbrick.TextWrapper

  @font (Mudbrick.new(fonts: %{bodoni: bodoni_regular()})
         |> Mudbrick.Document.find_object(&match?(%Font{}, &1))).value

  @long_text "This is a very long line of text that should wrap automatically to fit the width."

  describe "wrap/5" do
    test "breaks text at word boundaries so every line fits within the width" do
      lines = TextWrapper.wrap(@long_text, @font, 12, 200)

      assert length(lines) > 1

      for line <- lines do
        assert Font.width(@font, 12, line, auto_kern: true) <= 200
      end
    end

    test "keeps all the words, in order" do
      lines = TextWrapper.wrap(@long_text, @font, 12, 200)

      assert lines |> Enum.join(" ") |> String.split() == String.split(@long_text)
    end

    test "leaves text that already fits on a single line" do
      assert TextWrapper.wrap("short enough", @font, 12, 500) == ["short enough"]
    end

    test "preserves existing newlines as hard breaks" do
      assert TextWrapper.wrap("alpha\nbeta", @font, 12, 500) == ["alpha", "beta"]
    end

    test "a word wider than the width overflows on its own line by default" do
      assert [line] = TextWrapper.wrap("supercalifragilisticexpialidocious", @font, 12, 60)
      assert Font.width(@font, 12, line, auto_kern: true) > 60
    end

    test "break_words splits a word that is wider than the width" do
      word = "supercalifragilisticexpialidocious"

      lines = TextWrapper.wrap(word, @font, 12, 60, break_words: true)

      assert length(lines) > 1

      for line <- lines do
        assert Font.width(@font, 12, line, auto_kern: true) <= 60
      end

      # No characters are lost when the pieces are rejoined.
      assert Enum.join(lines) == word
    end

    test "keeps runs of spaces inside a line that already fits" do
      assert TextWrapper.wrap("1.    10,0    10,0", @font, 12, 500) == ["1.    10,0    10,0"]
    end

    test "keeps the indentation a line starts with" do
      assert TextWrapper.wrap("    indented", @font, 12, 500) == ["    indented"]
      assert TextWrapper.wrap("alpha\n    beta", @font, 12, 500) == ["alpha", "    beta"]
    end

    test "a line consisting only of spaces survives as its own line" do
      assert TextWrapper.wrap("alpha\n   \nbeta", @font, 12, 500) == ["alpha", "   ", "beta"]
    end

    test "drops only the run of spaces a line is broken on" do
      lines = TextWrapper.wrap("alpha    beta    #{@long_text}", @font, 12, 200)

      assert length(lines) > 1

      for line <- lines do
        assert line == String.trim(line)
        assert Font.width(@font, 12, line, auto_kern: true) <= 200
      end
    end

    test "gives up the indentation when the first word needs the whole width" do
      assert ["supercalifragilisticexpialidocious"] =
               TextWrapper.wrap("        supercalifragilisticexpialidocious", @font, 12, 60)
    end

    test "a tab becomes a single space" do
      assert TextWrapper.wrap("alpha\tbeta", @font, 12, 500) == ["alpha beta"]
    end
  end

  test "TextBlock.write_wrapped puts each wrapped line into its own line" do
    block =
      TextBlock.new(font: @font, font_size: 10, position: {0, 0})
      |> TextBlock.write_wrapped("one two three four five six", 40)

    texts =
      block.lines
      |> Enum.reverse()
      |> Enum.map(fn %Line{parts: [%Part{text: text}]} -> text end)

    assert length(texts) > 1
    assert Enum.join(texts, " ") == "one two three four five six"
  end

  describe ":max_width option on text/3" do
    test "wraps text into more than one line" do
      operations =
        new(fonts: %{f: bodoni_regular()})
        |> page()
        |> text(@long_text, font: :f, font_size: 12, position: {10, 330}, max_width: 200)
        |> operations()

      # Each line break after the first line is a T* operation.
      assert Enum.count(operations, &(&1 == "T*")) > 0
    end

    test "is equivalent to writing the wrapped lines with explicit newlines" do
      via_option =
        new(fonts: %{f: bodoni_regular()})
        |> page()
        |> text(@long_text, font: :f, font_size: 12, position: {10, 330}, max_width: 200)
        |> operations()

      pre_wrapped = TextWrapper.wrap(@long_text, @font, 12, 200) |> Enum.join("\n")

      writing_lines =
        new(fonts: %{f: bodoni_regular()})
        |> page()
        |> text(pre_wrapped, font: :f, font_size: 12, position: {10, 330})
        |> operations()

      assert via_option == writing_lines
    end
  end
end
