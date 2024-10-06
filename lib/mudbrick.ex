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
    Page.add(
      doc,
      Keyword.update(
        opts,
        :size,
        @page_sizes.a4,
        &Map.fetch!(@page_sizes, &1)
      )
    )
  end

  def contents({doc, page}) do
    {doc, page} =
      doc
      |> Document.add(ContentStream.new(page: page.value))
      |> Document.update(page, fn contents, %Page{} = p ->
        %{p | contents: contents}
      end)

    {doc, page.value.contents}
  end

  def font({_document, content_stream_object} = context, opts) do
    ContentStream.add(
      context,
      ContentStream.Tf,
      Keyword.update!(opts, :font, fn user_identifier ->
        content_stream_object.value.page.fonts[user_identifier].value.resource_identifier
      end)
    )
  end

  def text_position(context, x, y) do
    ContentStream.add(context, ContentStream.Td, tx: x, ty: y)
  end

  def text(context, text) do
    ContentStream.add(context, ContentStream.Tj, text: text)
  end

  def render({doc, _page}) do
    render(doc)
  end

  def render(doc) do
    Mudbrick.Serialisation.Document.render(doc)
  end
end
