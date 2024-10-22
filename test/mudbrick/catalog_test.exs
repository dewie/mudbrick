defmodule Mudbrick.CatalogTest do
  use ExUnit.Case, async: true

  import Mudbrick.TestHelper

  alias Mudbrick.Catalog
  alias Mudbrick.Indirect
  alias Mudbrick.PageTree
  alias Mudbrick.Stream

  test "is a dictionary with a ref to a page tree and metadata" do
    page_tree_obj = Indirect.Ref.new(42) |> Indirect.Object.new(PageTree.new())

    metadata_obj =
      Indirect.Ref.new(43) |> Indirect.Object.new(Stream.new(data: "<somemetadata/>"))

    assert Indirect.Ref.new(999)
           |> Indirect.Object.new(Catalog.new(page_tree: page_tree_obj, metadata: metadata_obj))
           |> show() == """
           999 0 obj
           <</Type /Catalog
             /Metadata 43 0 R
             /Pages 42 0 R
           >>
           endobj\
           """
  end
end
