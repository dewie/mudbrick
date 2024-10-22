defmodule Mudbrick.CatalogTest do
  use ExUnit.Case, async: true

  import Mudbrick.TestHelper

  alias Mudbrick.Catalog
  alias Mudbrick.Indirect
  alias Mudbrick.PageTree

  test "is a dictionary with a ref to a page tree" do
    page_tree_obj = Indirect.Ref.new(42) |> Indirect.Object.new(PageTree.new())

    assert Indirect.Ref.new(999)
           |> Indirect.Object.new(Catalog.new(page_tree: page_tree_obj))
           |> show() == """
           999 0 obj
           <</Type /Catalog
             /Pages 42 0 R
           >>
           endobj\
           """
  end
end
