defmodule Mudbrick.IndirectTest do
  use ExUnit.Case, async: true

  alias Mudbrick.Indirect
  alias Mudbrick.Object

  test "object includes object number, static generation and contents" do
    assert Indirect.Ref.new(12)
           |> Indirect.Object.new("Brillig")
           |> Object.from() ==
             """
             12 0 obj
             (Brillig)
             endobj\
             """
  end

  test "ref has number, static generation and letter R" do
    assert Object.from(Indirect.Ref.new(12)) == "12 0 R"
  end
end
