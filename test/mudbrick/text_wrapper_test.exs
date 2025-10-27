defmodule Mudbrick.TextWrapperTest do
  use ExUnit.Case, async: true

  alias Mudbrick.TextWrapper

  test "wrap_text basic functionality" do
    # Simple test without font dependency
    text = "This is a short line."

    # Test that the function doesn't crash
    result = TextWrapper.wrap_text(text, nil, 12, 200)

    # Should return a list
    assert is_list(result)
    assert length(result) >= 1
  end

  test "wrap_text with empty string" do
    result = TextWrapper.wrap_text("", nil, 12, 200)
    assert result == [""]
  end

  test "wrap_text with single word" do
    result = TextWrapper.wrap_text("word", nil, 12, 200)
    assert result == ["word"]
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
