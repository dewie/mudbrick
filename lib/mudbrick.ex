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
    import ContentStream

    case Map.fetch(content_stream_object.value.page.fonts, user_identifier) do
      {:ok, font} ->
        context
        |> add(
          ContentStream.Tf,
          Keyword.put(
            opts,
            :font,
            font.value
          )
        )
        |> add(ContentStream.TL, leading: Keyword.fetch!(opts, :size) * 1.2)

      :error ->
        raise Font.Unregistered, "Unregistered font: #{user_identifier}"
    end
  end

  def text_position(context, x, y) do
    ContentStream.add(context, ContentStream.Td, tx: x, ty: y)
  end

  defp latest_font_operation!(content_stream) do
    Enum.find(
      content_stream.value.operations,
      &match?(%ContentStream.Tf{}, &1)
    ) || raise Font.NotSet, "No font chosen"
  end

  def text({_doc, content_stream} = context, text, colour: {r, g, b}) do
    context
    |> ContentStream.add(ContentStream.QPush, [])
    |> ContentStream.add(ContentStream.Rg, r: r, g: g, b: b)
    |> text(text)
    |> ContentStream.add(ContentStream.QPop, [])
    |> ContentStream.add(latest_font_operation!(content_stream))
  end

  def text({_doc, content_stream} = context, text) do
    import ContentStream

    tf = latest_font_operation!(content_stream)

    [first_part | parts] = String.split(text, "\n")

    context
    |> add(ContentStream.Tj, font: tf.font, text: first_part)
    |> then(fn context ->
      for part <- parts, reduce: context do
        acc ->
          add(acc, ContentStream.Apostrophe, font: tf.font, text: part)
      end
    end)
  end

  def render({doc, _page}) do
    render(doc)
  end

  def render(doc) do
    Mudbrick.Object.from(doc)
  end

  def to_hex(n) do
    n
    |> Integer.to_string(16)
    |> String.pad_leading(4, "0")
  end

  def join(a, separator \\ " ")

  def join(tuple, separator) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> join(separator)
  end

  def join(list, separator) do
    Enum.map_join(list, separator, &Mudbrick.Object.from/1)
  end
end
