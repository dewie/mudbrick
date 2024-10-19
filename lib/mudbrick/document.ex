defmodule Mudbrick.Document do
  defstruct objects: []

  alias Mudbrick.Catalog
  alias Mudbrick.Document
  alias Mudbrick.Indirect
  alias Mudbrick.PageTree

  def new do
    %Document{}
    |> add(PageTree.new())
    |> add(&Catalog.new(page_tree: &1.ref))
    |> finish()
  end

  def add(%Document{objects: objects} = doc, value) do
    object = next_object(doc, value)
    {%Document{doc | objects: [object | objects]}, object}
  end

  def add({doc, just_added_object}, fun) do
    add(doc, fun.(just_added_object))
  end

  def add_page_ref(%Indirect.Object{value: tree} = tree_obj, page) do
    %{tree_obj | value: PageTree.add_page_ref(tree, page.ref)}
  end

  def update({doc, just_added_object}, object, fun) do
    put(doc, %{object | value: fun.(just_added_object, object.value)})
  end

  def update(doc, object, fun) do
    put(doc, %{object | value: fun.(object.value)})
  end

  def finish({doc, object}, fun) do
    {doc, fun.(object)}
  end

  def finish({doc, _objects}) do
    doc
  end

  def root_page_tree(doc) do
    find_object(doc, &match?(%PageTree{}, &1))
  end

  def update_root_page_tree(doc, fun) do
    Map.update!(doc, :objects, fn objects ->
      update_in(objects, [Access.find(&match?(%PageTree{}, &1.value))], &fun.(&1))
    end)
  end

  def catalog(doc) do
    find_object(doc, &match?(%Catalog{}, &1))
  end

  def object_with_ref(doc, ref) do
    Enum.at(doc.objects, -ref.number)
  end

  def find_object(%Document{objects: objects}, f) do
    Enum.find(objects, fn object ->
      f.(object.value)
    end)
  end

  defp put(doc, updated_object) do
    {
      Map.update!(doc, :objects, fn objects ->
        List.replace_at(objects, -updated_object.ref.number, updated_object)
      end),
      updated_object
    }
  end

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
