defmodule Mudbrick.Document do
  defstruct [:objects]

  alias Mudbrick.Catalog
  alias Mudbrick.Document
  alias Mudbrick.IndirectObject
  alias Mudbrick.IndirectObject.Reference
  alias Mudbrick.PageTree

  def new(opts \\ [pages: []]) do
    pages =
      case opts |> Keyword.fetch!(:pages) do
        [] -> []
        [page] -> [IndirectObject.new(page, number: 3)]
      end

    page_refs = Enum.map(pages, &Reference.new/1)

    page_tree =
      PageTree.new(kids: page_refs)
      |> IndirectObject.new(number: 2)

    catalog =
      Catalog.new(page_tree: Reference.new(page_tree))
      |> IndirectObject.new(number: 1)

    %Document{objects: [catalog, page_tree] ++ pages}
  end

  defimpl String.Chars do
    @initial_generation "00000"
    @free_entries_first_generation "65535"

    alias Mudbrick.Document
    alias Mudbrick.IndirectObject.Reference
    alias Mudbrick.PDFObject

    def to_string(%Document{objects: [catalog | _rest] = raw_objects}) do
      version = "%PDF-2.0"
      objects = Enum.map(raw_objects, &PDFObject.from/1)
      sections = [version] ++ objects

      trailer =
        PDFObject.from(%{
          Size: length(objects) + 1,
          Root: Reference.new(catalog)
        })

      """
      #{Enum.join(sections, "\n")}
      xref
      0 #{length(objects) + 1}
      #{offsets(sections)}
      trailer
      #{trailer}
      startxref
      #{offset(sections)}
      %%EOF\
      """
    end

    defp offsets(sections) do
      {_, retval} =
        for section <- sections, reduce: {[], ""} do
          {past_sections, ""} ->
            {[section | past_sections],
             "#{padded_offset(past_sections)} #{@free_entries_first_generation} f "}

          {past_sections, acc} ->
            {[section | past_sections],
             "#{acc}\n#{padded_offset(past_sections)} #{@initial_generation} n "}
        end

      retval
    end

    defp padded_offset(strings) do
      strings
      |> offset()
      |> String.pad_leading(10, "0")
    end

    defp offset(strings) do
      strings
      |> Enum.map(&byte_size("#{&1}\n"))
      |> Enum.sum()
      |> Kernel.to_string()
    end
  end
end
