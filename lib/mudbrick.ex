defmodule Mudbrick do
  alias Mudbrick.ContentStream
  alias Mudbrick.Document
  alias Mudbrick.Font
  alias Mudbrick.Page

  @dpi 72

  @page_sizes %{
    a4: {8.3 * @dpi, 11.7 * @dpi},
    letter: {8.5 * @dpi, 11 * @dpi}
  }

  def new() do
    Document.new()
  end

  def page(a, opts \\ [])

  def page({doc, _page}, opts) do
    page(doc, opts)
  end

  def page(doc, opts) do
    opts =
      opts
      |> Keyword.update(
        :size,
        @page_sizes.a4,
        &Map.fetch!(@page_sizes, &1)
      )

    Page.add(doc, opts)
  end

  def text({doc, page}, text) do
    doc
    |> Document.add([
      ContentStream.new(text: text),
      Font.new(
        name: :Helvetica,
        encoding: :"Identity-H",
        subtype: :TrueType
      )
    ])
    |> Document.update(page, fn [contents, font], %Page{} = p ->
      %{p | contents_ref: contents.ref, font_ref: font.ref}
    end)
  end

  def render({doc, _page}) do
    to_string(doc)
  end

  def render(doc) do
    to_string(doc)
  end
end
