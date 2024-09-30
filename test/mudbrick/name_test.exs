defmodule Mudbrick.NameTest do
  use ExUnit.Case, async: true

  alias Mudbrick.Name

  test "can't be created with nil" do
    assert_raise(FunctionClauseError, fn ->
      Name.new(nil)
    end)
  end
end
