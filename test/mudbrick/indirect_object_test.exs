defmodule Mudbrick.IndirectObjectTest do
  use ExUnit.Case, async: true

  alias Mudbrick.IndirectObject

  @brillig "Brillig"
           |> Mudbrick.String.new()
           |> IndirectObject.new(number: 12)

  test "includes object number, static generation and contents" do
    assert "#{@brillig}" ==
             """
             12 0 obj
             (Brillig)
             endobj
             """
  end

  test "has a reference" do
    assert "#{IndirectObject.reference(@brillig)}" == "12 0 R"
  end
end
