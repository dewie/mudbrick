defmodule Mudbrick.IndirectTest do
  use ExUnit.Case, async: true

  import Mudbrick.TestHelper

  alias Mudbrick.Indirect

  test "object includes object number, static generation and contents" do
    assert Indirect.Ref.new(12)
           |> Indirect.Object.new("Brillig")
           |> show() ==
             """
             12 0 obj
             (Brillig)
             endobj\
             """
  end

  test "ref has number, static generation and letter R" do
    assert 12 |> Indirect.Ref.new() |> show() == "12 0 R"
  end
end
