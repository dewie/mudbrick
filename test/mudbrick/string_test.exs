defmodule Mudbrick.StringTest do
  use ExUnit.Case, async: true

  test "is enclosed in parentheses" do
    assert "#{Mudbrick.String.new("hi there")}" == "(hi there)"
  end

  test "escapes certain characters" do
    assert "#{Mudbrick.String.new("\n \r \t \b \f ) ( \\ #{[0xDDD]}")}" ==
             "(\\n \\r \\t \\b \\f \\) \\( \\ \\ddd)"
  end
end
