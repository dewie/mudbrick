defmodule MudbrickTest do
  use ExUnit.Case
  doctest Mudbrick

  test "greets the world" do
    assert Mudbrick.hello() == :world
  end
end
