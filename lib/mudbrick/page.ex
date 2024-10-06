defmodule Mudbrick.Page do
  defstruct contents_ref: nil,
            font_ref: nil,
            size: nil,
            parent: nil

  alias Mudbrick.Document
  alias Mudbrick.Font

  def new(opts \\ []) do
    struct!(Mudbrick.Page, opts)
  end

  def add(doc, opts) do
    add_empty_page(doc, opts)
    |> add_to_page_tree()
  end

  defp add_empty_page(doc, opts) do
    case Keyword.pop(opts, :fonts) do
      {nil, opts} ->
        Document.add(doc, new_at_root(opts, doc))

      {[font_opts], opts} ->
        doc
        |> Document.add(Font.new(font_opts))
        |> Document.add(fn
          [font] ->
            opts
            |> Keyword.put(:font_ref, font.ref)
            |> new_at_root(doc)
        end)
    end
  end

  defp new_at_root(opts, doc) do
    Keyword.put(opts, :parent, Document.root_page_tree(doc).ref) |> new()
  end

  defp add_to_page_tree({doc, [page]}) do
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
          case page.contents_ref do
            nil -> %{}
            ref -> %{Contents: ref, Resources: %{Font: %{F1: page.font_ref}}}
          end
        )
      )
    end
  end
end
