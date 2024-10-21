defmodule Mudbrick.Page do
  defstruct contents: nil,
            parent: nil,
            size: nil

  alias Mudbrick.Document

  @dpi 72

  @page_sizes %{
    a4: {8.3 * @dpi, 11.7 * @dpi},
    letter: {8.5 * @dpi, 11 * @dpi}
  }

  @doc false
  def new(opts \\ []) do
    struct!(__MODULE__, opts)
  end

  def size(name) do
    @page_sizes[name]
  end

  @doc false
  def add(doc, opts) do
    add_empty_page(doc, opts)
    |> add_to_page_tree()
  end

  defp add_empty_page(doc, opts) do
    Document.add(doc, new_at_root(opts, doc))
  end

  defp new_at_root(opts, doc) do
    Keyword.put(opts, :parent, Document.root_page_tree(doc).ref) |> new()
  end

  defp add_to_page_tree({doc, page}) do
    {
      Document.update_root_page_tree(doc, fn page_tree ->
        Document.add_page_ref(page_tree, page)
      end),
      page
    }
  end

  defimpl Mudbrick.Object do
    def from(page) do
      {width, height} = page.size

      Mudbrick.Object.from(
        %{
          Type: :Page,
          Parent: page.parent,
          MediaBox: [0, 0, width, height]
        }
        |> Map.merge(
          case page.contents do
            nil -> %{}
            contents -> %{Contents: contents.ref}
          end
        )
      )
    end
  end
end
