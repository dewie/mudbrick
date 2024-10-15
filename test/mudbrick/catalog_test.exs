defmodule Mudbrick.CatalogTest do
  use ExUnit.Case, async: true

  import TestHelper

  alias Mudbrick.Catalog
  alias Mudbrick.Indirect

  test "is a dictionary with a ref to a page tree" do
    ref = Indirect.Ref.new(42)

    assert Indirect.Ref.new(999)
           |> Indirect.Object.new(Catalog.new(page_tree: ref))
           |> show() == """
           999 0 obj
           <</Type /Catalog
             /Pages 42 0 R
           >>
           endobj\
           """
  end
end
