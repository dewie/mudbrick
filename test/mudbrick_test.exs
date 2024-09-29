defmodule MudbrickTest do
  use ExUnit.Case, async: true

  test "can roundtrip" do
    assert Mudbrick.new()
           |> Mudbrick.render()
           |> Mudbrick.parse() == Mudbrick.new()
  end
end
