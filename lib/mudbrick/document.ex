defmodule Mudbrick.Document do
  defstruct objects: []

  alias Mudbrick.Catalog
  alias Mudbrick.Document
  alias Mudbrick.Indirect
  alias Mudbrick.PageTree

  def new do
    %Document{}
    |> add_object(PageTree.new())
    |> add_object(fn [page_tree] ->
      Catalog.new(page_tree: page_tree.reference)
    end)
    |> finish()
  end

  def add_objects(doc, values) do
    for value <- values, reduce: {doc, []} do
      {acc_doc, acc_objects} ->
        acc_doc = add_object(acc_doc, value) |> finish()
        {acc_doc, acc_objects ++ [List.last(acc_doc.objects)]}
    end
  end

  def add_object(%Document{objects: objects} = doc, value) do
    obj = next_object(doc, value)
    {%Document{doc | objects: objects ++ [obj]}, [obj]}
  end

  def add_object({doc, just_added_objects}, fun) do
    add_object(doc, fun.(just_added_objects))
  end

  def add_page_ref(%Indirect.Object{value: tree} = tree_obj, page) do
    %{tree_obj | value: PageTree.add_page_ref(tree, page.reference)}
  end

  def finish({doc, _objects}) do
    doc
  end

  defp next_object(doc, value) do
    doc |> next_ref() |> Indirect.Object.new(value)
  end

  defp next_ref(doc) do
    doc |> next_object_number() |> Indirect.Reference.new()
  end

  defp next_object_number(doc) do
    length(doc.objects) + 1
  end

  def page_tree_root_ref do
    Indirect.Reference.new(1)
  end

  def catalog_ref do
    Indirect.Reference.new(2)
  end
end
