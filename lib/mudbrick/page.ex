defmodule Mudbrick.Page do
  defstruct contents_ref: nil,
            font_ref: nil,
            page_size: nil,
            parent: nil

  alias Mudbrick.Document

  def new(opts \\ []) do
    struct(Mudbrick.Page, opts)
  end

  def add(doc, _opts) do
    add_empty_page(doc)
    |> add_to_page_tree()
  end

  defp add_empty_page(doc) do
    Document.add(
      doc,
      new(
        page_size: doc.page_size,
        parent: Document.root_page_tree(doc).ref
      )
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
