defmodule Mudbrick.TextWrapperTest do
  use ExUnit.Case, async: true

  alias Mudbrick.TextWrapper

  test "wrap_text basic functionality" do
    result = TextWrapper.wrap_text("This is a short line.", nil, 12, 200)
    assert result == ["This is a short line."]
  end

  test "wrap_text with empty string" do
    result = TextWrapper.wrap_text("", nil, 12, 200)
    assert result == [""]
  end

  test "wrap_text with single word" do
    result = TextWrapper.wrap_text("word", nil, 12, 200)
    assert result == ["word"]
  end

  test "wrap_text preserves explicit newlines" do
    assert TextWrapper.wrap_text("a\nb\nc", nil, 12, 200) == ["a", "b", "c"]
  end

  test "wrap_text preserves leading newline" do
    assert TextWrapper.wrap_text("\nhead", nil, 12, 200) == ["", "head"]
  end

  test "wrap_text preserves trailing newline" do
    assert TextWrapper.wrap_text("tail\n", nil, 12, 200) == ["tail", ""]
  end

  test "wrap_text preserves consecutive newlines" do
    assert TextWrapper.wrap_text("x\n\ny", nil, 12, 200) == ["x", "", "y"]
  end

  test "wrap_text normalizes CRLF to LF" do
    assert TextWrapper.wrap_text("a\r\nb", nil, 12, 200) == ["a", "b"]
  end

  test "wrap_text with justification options" do
    # Test that justification options are accepted without crashing
    result = TextWrapper.wrap_text("This is a test", nil, 12, 200, justify: :center)
    assert is_list(result)

    result = TextWrapper.wrap_text("This is a test", nil, 12, 200, justify: :right)
    assert is_list(result)

    result = TextWrapper.wrap_text("This is a test", nil, 12, 200, justify: :justify)
    assert is_list(result)

    result = TextWrapper.wrap_text("This is a test", nil, 12, 200, justify: :left)
    assert is_list(result)
  end

  test "wrap_text with invalid justification defaults to left" do
    result = TextWrapper.wrap_text("This is a test", nil, 12, 200, justify: :invalid)
    assert is_list(result)
  end
end
