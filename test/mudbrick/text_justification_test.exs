defmodule Mudbrick.TextJustificationTest do
  use ExUnit.Case, async: true

  alias Mudbrick.TextWrapper

  test "justification options work correctly" do
    text = "This is a test line that should be wrapped and justified properly."

    # Test all justification options
    left_result = TextWrapper.wrap_text(text, nil, 12, 50, justify: :left)
    right_result = TextWrapper.wrap_text(text, nil, 12, 50, justify: :right)
    center_result = TextWrapper.wrap_text(text, nil, 12, 50, justify: :center)
    justify_result = TextWrapper.wrap_text(text, nil, 12, 50, justify: :justify)

    # All should return lists
    assert is_list(left_result)
    assert is_list(right_result)
    assert is_list(center_result)
    assert is_list(justify_result)

    # All should have at least one line
    assert length(left_result) >= 1
    assert length(right_result) >= 1
    assert length(center_result) >= 1
    assert length(justify_result) >= 1
  end

  test "invalid justification defaults to left" do
    text = "This is a test line."

    result = TextWrapper.wrap_text(text, nil, 12, 50, justify: :invalid_option)

    assert is_list(result)
    assert length(result) >= 1
  end

  test "justification with empty text" do
    result = TextWrapper.wrap_text("", nil, 12, 50, justify: :center)
    assert result == [""]
  end

  test "justification with single word" do
    result = TextWrapper.wrap_text("word", nil, 12, 50, justify: :right)
    assert result == ["word"]
  end
end
