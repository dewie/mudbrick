defmodule Mudbrick.IndirectObjectTest do
  use ExUnit.Case, async: true

  alias Mudbrick.IndirectObject
  alias Mudbrick.PDFObject

  @brillig "Brillig"
           |> IndirectObject.new(number: 12)

  test "includes object number, static generation and contents" do
    assert PDFObject.from(@brillig) ==
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
