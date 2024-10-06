defmodule Mudbrick do
  alias Mudbrick.ContentStream
  alias Mudbrick.Document
  alias Mudbrick.Page

  @dpi 72

  @page_sizes %{
    a4: {8.3 * @dpi, 11.7 * @dpi},
    letter: {8.5 * @dpi, 11 * @dpi}
  }

  def new do
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
      ContentStream.new(
        operations: [
          %ContentStream.Tf{font: :F1, size: 24},
          %ContentStream.Td{tx: 300, ty: 400},
          %ContentStream.Tj{text: text}
        ]
      )
    ])
    |> Document.update(page, fn [contents], %Page{} = p ->
      %{p | contents_ref: contents.ref}
    end)
  end

  def render({doc, _page}) do
    to_string(doc)
  end

  def render(doc) do
    to_string(doc)
  end
end
