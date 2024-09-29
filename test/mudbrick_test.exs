defmodule MudbrickTest do
  use ExUnit.Case

  test "can roundtrip" do
    assert Mudbrick.new() |> Mudbrick.parse() == Mudbrick.new()
  end
end
