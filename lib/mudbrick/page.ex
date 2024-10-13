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
              font_opts =
                Keyword.put(font_opts, :resource_identifier, :"F#{id + 1}")

              {doc, font} =
                case Keyword.pop(font_opts, :file) do
                  {nil, font_opts} ->
                    Document.add(doc, Font.new(font_opts))

                  {file_contents, font_opts} ->
                    opentype =
                      OpenType.new()
                      |> OpenType.parse(file_contents)

                    font_name = String.to_atom(opentype.name)

                    doc
                    |> Document.add(
                      Mudbrick.Stream.new(
                        data: file_contents,
                        additional_entries: %{
                          Length1: byte_size(file_contents),
                          Subtype: :OpenType
                        }
                      )
                    )
                    |> Document.add(
                      &Font.Descriptor.new(
                        file: &1,
                        flags: opentype.flags,
                        font_name: font_name
                      )
                    )
                    |> Document.add(
                      &Font.CIDFont.new(
                        descriptor: &1,
                        type: :CIDFontType0,
                        font_name: font_name
                      )
                    )
                    |> Document.add(
                      &Font.new(
                        Keyword.merge(font_opts,
                          descendant: &1,
                          name: font_name,
                          parsed: opentype
                        )
                      )
                    )
                end

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
