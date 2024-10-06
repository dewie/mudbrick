defmodule Mudbrick.CatalogTest do
  use ExUnit.Case, async: true

  alias Mudbrick.Catalog
  alias Mudbrick.Indirect
  alias Mudbrick.Object

  test "is a dictionary with a ref to a page tree" do
    ref = Indirect.Ref.new(42)

    assert Indirect.Ref.new(999)
           |> Indirect.Object.new(Catalog.new(page_tree: ref))
           |> Object.from() == """
           999 0 obj
           <</Type /Catalog
             /Pages 42 0 R
           >>
           endobj\
           """
  end
end
