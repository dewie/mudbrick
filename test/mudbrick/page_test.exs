defmodule Mudbrick.PageTest do
  use ExUnit.Case, async: true

  test "if no parent provided, assumes root" do
    assert Mudbrick.Page.new().parent == Mudbrick.Document.page_tree_root_ref()
  end
end
