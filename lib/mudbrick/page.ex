defmodule Mudbrick.Page do
  defstruct contents: nil,
            fonts: %{},
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

      {fonts, opts} ->
        {doc, font_objects, _id} =
          for {human_name, font_opts} <- fonts, reduce: {doc, %{}, 0} do
            {doc, font_objects, id} ->
              {doc, font} =
                Document.add(
                  doc,
                  font_opts
                  |> Keyword.put(:resource_identifier, :"F#{id + 1}")
                  |> Font.new()
                )

              {doc, Map.put(font_objects, human_name, font), id + 1}
          end

        doc
        |> Document.add(
          opts
          |> Keyword.put(:fonts, font_objects)
          |> new_at_root(doc)
        )
    end
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
            nil ->
              %{}

            contents ->
              %{Contents: contents.ref, Resources: %{Font: font_dictionary(page.fonts)}}
          end
        )
      )
    end

    defp font_dictionary(fonts) do
      for {_human_identifier, object} <- fonts, into: %{} do
        {object.value.resource_identifier, object.ref}
      end
    end
  end
end
