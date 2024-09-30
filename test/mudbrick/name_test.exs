defmodule Mudbrick.NameTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Mudbrick.Name

  test "is prefixed with a solidus" do
    assert "#{Name.new("Name1")}" == "/Name1"
    assert "#{Name.new("ASomewhatLongerName")}" == "/ASomewhatLongerName"

    assert "#{Name.new("A;Name_With-Various***Characters?")}" ==
             "/A;Name_With-Various***Characters?"

    assert "#{Name.new("1.2")}" == "/1.2"
  end

  test "literal whitespace is escaped as hex" do
    assert "#{Name.new("hi there")}" == "/hi#20there"
  end

  property "characters outside of ! to ~ don't appear as literals" do
    check all s <- string([0..(?! - 1), (?~ + 1)..999], min_length: 1),
              rendered <- constant("#{Name.new(s)}") do
      refute rendered =~ s
      assert rendered =~ "#"
    end
  end

  test "can't be created with nil" do
    assert_raise(FunctionClauseError, fn ->
      Name.new(nil)
    end)
  end
end
