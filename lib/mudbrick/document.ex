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
    content_stream = ContentStream.new(opts)

    contents =
      Indirect.Reference.new(page_reference.number + 1)
      |> Indirect.Object.new(content_stream)

    {additional_objects, page_opts} = additional_objects(contents)

    page = Indirect.Object.new(page_reference, Page.new(page_opts))

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

  def additional_objects(%Indirect.Object{value: stream}) when is_nil(stream.text) do
    {[], []}
  end

  def additional_objects(%Indirect.Object{value: stream} = indirect_contents) do
    [font] =
      renumbered =
      renumber_refs(ContentStream.objects(stream), indirect_contents.reference.number)

    {
      [indirect_contents] ++
        renumbered,
      contents_reference: indirect_contents.reference, font_reference: font.reference
    }
  end

  defp renumber_refs(indirect_objects, previous_number) do
    indirect_objects
    |> Enum.with_index()
    |> Enum.map(fn {o, idx} -> Indirect.Object.renumber(o, previous_number + idx + 1) end)
  end

  defp next_object_number(doc) do
    length(doc.objects) + 1
  end

  defp add_page_ref(%Indirect.Object{value: tree} = tree_obj, page) do
    %{tree_obj | value: PageTree.add_page_ref(tree, page.reference)}
  end
end
