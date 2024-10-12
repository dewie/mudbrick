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
    import Document

    doc
    |> add(ContentStream.new(page: page.value))
    |> update(page, fn contents, %Page{} = p ->
      %{p | contents: contents}
    end)
    |> finish(& &1.value.contents)
  end

  def font({_document, content_stream_object} = context, user_identifier, opts) do
    case Map.fetch(content_stream_object.value.page.fonts, user_identifier) do
      {:ok, font} ->
        ContentStream.add(
          context,
          ContentStream.Tf,
          Keyword.put(
            opts,
            :font,
            font.value
          )
        )

      :error ->
        raise Mudbrick.Font.Unregistered, "Unregistered font: #{user_identifier}"
    end
  end

  def text_position(context, x, y) do
    ContentStream.add(context, ContentStream.Td, tx: x, ty: y)
  end

  def text(context, text) do
    {_doc, content_stream} = context

    latest_font_setting =
      Enum.find(content_stream.value.operations, fn
        %ContentStream.Tf{} -> true
        _ -> false
      end)

    if latest_font_setting.font.descendant do
      ContentStream.add(
        context,
        ContentStream.TJ,
        font: latest_font_setting.font,
        text: text
      )
    else
      ContentStream.add(
        context,
        ContentStream.Tj,
        text: text
      )
    end
  end

  def render({doc, _page}) do
    render(doc)
  end

  def render(doc) do
    Mudbrick.Object.from(doc)
  end
end
