defmodule Mudbrick.Document do
  defstruct objects: []

  alias Mudbrick.Catalog
  alias Mudbrick.Document
  alias Mudbrick.Indirect
  alias Mudbrick.PageTree

  def new do
    %Document{}
    |> add(PageTree.new())
    |> add(fn [page_tree] ->
      Catalog.new(page_tree: page_tree.ref)
    end)
    |> finish()
  end

  def add(doc, values) when is_list(values) do
    for value <- values, reduce: {doc, []} do
      {acc_doc, acc_objects} ->
        acc_doc = add(acc_doc, value) |> finish()
        {acc_doc, acc_objects ++ [List.last(acc_doc.objects)]}
    end
  end

  def add(%Document{objects: objects} = doc, value) do
    obj = next_object(doc, value)
    {%Document{doc | objects: objects ++ [obj]}, [obj]}
  end

  def add({doc, just_added_objects}, fun) do
    add(doc, fun.(just_added_objects))
  end

  def add_page_ref(%Indirect.Object{value: tree} = tree_obj, page) do
    %{tree_obj | value: PageTree.add_page_ref(tree, page.ref)}
  end

  def update({doc, just_added_objects}, indirect_object, fun) do
    updated_obj = %{
      indirect_object
      | value: fun.(just_added_objects, indirect_object.value)
    }

    {
      Map.update!(doc, :objects, fn objs ->
        put_in(objs, [Access.find(&(&1 == indirect_object))], updated_obj)
      end),
      updated_obj
    }
  end

  def finish({doc, _objects}) do
    doc
  end

  def root_page_tree(%Document{objects: objects}) do
    Enum.find(objects, &page_tree?/1)
  end

  def update_root_page_tree(doc, fun) do
    Map.update!(doc, :objects, fn objs ->
      update_in(objs, [Access.find(&page_tree?/1)], &fun.(&1))
    end)
  end

  def catalog(%Document{objects: objects}) do
    Enum.find(objects, &catalog?/1)
  end

  defp catalog?(%Indirect.Object{value: %Catalog{}}), do: true
  defp catalog?(_), do: false

  defp page_tree?(%Indirect.Object{value: %PageTree{}}), do: true
  defp page_tree?(_), do: false

  defp next_object(doc, value) do
    doc |> next_ref() |> Indirect.Object.new(value)
  end

  defp next_ref(doc) do
    doc |> next_object_number() |> Indirect.Ref.new()
  end

  defp next_object_number(doc) do
    length(doc.objects) + 1
  end
end
