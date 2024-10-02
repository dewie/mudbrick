defmodule Mudbrick.Document do
  defstruct [:objects]

  alias Mudbrick.Catalog
  alias Mudbrick.Document
  alias Mudbrick.Indirect
  alias Mudbrick.PageTree

  def new(opts \\ [pages: []]) do
    pages =
      opts
      |> Keyword.fetch!(:pages)
      |> Enum.with_index()
      |> Enum.map(fn {page, idx} ->
        Indirect.Reference.new(idx + first_page_number())
        |> Indirect.Object.new(page)
      end)

    page_tree =
      page_tree_root_ref()
      |> Indirect.Object.new(PageTree.new(kids: Enum.map(pages, & &1.reference)))

    catalog =
      catalog_ref()
      |> Indirect.Object.new(Catalog.new(page_tree: page_tree.reference))

    %Document{objects: [catalog, page_tree] ++ pages}
  end

  def page_tree_root_ref do
    Indirect.Reference.new(2)
  end

  defp catalog_ref do
    Indirect.Reference.new(1)
  end

  defp first_page_number do
    page_tree_root_ref().number + 1
  end
end
