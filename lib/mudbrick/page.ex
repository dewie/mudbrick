defmodule Mudbrick.Page do
  defstruct [:parent, :contents_reference, :font_reference]

  alias Mudbrick.ContentStream
  alias Mudbrick.Document

  def new(opts \\ []) do
    struct(Mudbrick.Page, opts)
  end

  def add(doc, opts) do
    if opts[:text] do
      add_content_page(doc, opts)
    else
      add_empty_page(doc)
    end
    |> add_to_page_tree()
  end

  defp add_content_page(doc, opts) do
    doc
    |> Document.add_objects([
      ContentStream.new(opts),
      %{
        BaseFont: :Helvetica,
        Encoding: :"Identity-H",
        Subtype: :TrueType,
        Type: :Font
      }
    ])
    |> Document.add_object(fn [contents, font] ->
      new(
        contents_reference: contents.reference,
        font_reference: font.reference,
        parent: Document.page_tree_root_ref()
      )
    end)
    |> Document.finish()
  end

  defp add_empty_page(doc) do
    Document.add_object(doc, new(parent: Document.page_tree_root_ref()))
    |> Document.finish()
  end

  defp add_to_page_tree(doc) do
    doc
    |> Map.update!(:objects, fn [page_tree | objects] ->
      [Document.add_page_ref(page_tree, List.last(objects)) | objects]
    end)
  end
end
