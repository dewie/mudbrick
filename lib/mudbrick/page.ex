defmodule Mudbrick.Page do
  defstruct contents_ref: nil,
            font_ref: nil,
            size: nil,
            parent: nil

  alias Mudbrick.Document

  def new(opts \\ []) do
    struct(Mudbrick.Page, opts)
  end

  def add(doc, opts) do
    add_empty_page(doc, opts)
    |> add_to_page_tree()
  end

  defp add_empty_page(doc, opts) do
    Document.add(
      doc,
      new(Keyword.put(opts, :parent, Document.root_page_tree(doc).ref))
    )
  end

  defp add_to_page_tree({doc, [page]}) do
    {
      Document.update_root_page_tree(doc, fn page_tree ->
        Document.add_page_ref(page_tree, page)
      end),
      page
    }
  end
end
