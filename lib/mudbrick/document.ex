defmodule Mudbrick.Document do
  defstruct [:objects]

  alias Mudbrick.Catalog
  alias Mudbrick.ContentStream
  alias Mudbrick.Document
  alias Mudbrick.Indirect
  alias Mudbrick.Page
  alias Mudbrick.PageTree

  def new do
    page_tree =
      page_tree_root_ref()
      |> Indirect.Object.new(PageTree.new(kids: []))

    catalog =
      catalog_ref()
      |> Indirect.Object.new(Catalog.new(page_tree: page_tree.reference))

    %Document{objects: [catalog, page_tree]}
  end

  def add_page(doc, opts) do
    page_reference = Indirect.Reference.new(next_object_number(doc))

    contents =
      Indirect.Reference.new(page_reference.number + 1)
      |> Indirect.Object.new(ContentStream.new(opts))

    {additional_objects, opts} =
      case opts[:text] do
        nil ->
          {[], opts}

        _text ->
          {[contents], Keyword.put(opts, :contents_reference, contents.reference)}
      end

    page = Indirect.Object.new(page_reference, Page.new(opts))

    Map.update!(doc, :objects, fn objects ->
      (objects ++ [page] ++ additional_objects)
      |> List.update_at(1, &add_page_ref(&1, page))
    end)
  end

  def page_tree_root_ref do
    Indirect.Reference.new(2)
  end

  defp catalog_ref do
    Indirect.Reference.new(1)
  end

  defp next_object_number(doc) do
    length(doc.objects) + 1
  end

  defp add_page_ref(%Indirect.Object{value: tree} = tree_obj, page) do
    %{tree_obj | value: PageTree.add_page_ref(tree, page.reference)}
  end
end
