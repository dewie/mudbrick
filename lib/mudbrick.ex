defmodule Mudbrick do
  alias Mudbrick.ContentStream
  alias Mudbrick.Document
  alias Mudbrick.Font
  alias Mudbrick.Image
  alias Mudbrick.Page

  def new(opts \\ []) do
    Document.new(opts)
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
        Page.size(:a4),
        &Page.size(&1)
      )
    )
    |> contents()
  end

  def font({doc, _content_stream_obj} = context, user_identifier, opts) do
    import ContentStream

    {leading, opts} = Keyword.pop(opts, :leading, Keyword.fetch!(opts, :size) * 1.2)

    case Map.fetch(Document.root_page_tree(doc).value.fonts, user_identifier) do
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
        |> add(ContentStream.TL, leading: leading)

      :error ->
        raise Font.Unregistered, "Unregistered font: #{user_identifier}"
    end
  end

  def image({doc, _content_stream_obj} = context, user_identifier, opts \\ []) do
    import ContentStream

    case Map.fetch(Document.root_page_tree(doc).value.images, user_identifier) do
      {:ok, image} ->
        context
        |> add(%ContentStream.QPush{})
        |> add(ContentStream.Cm, opts)
        |> add(%ContentStream.Do{image: image.value})
        |> add(%ContentStream.QPop{})

      :error ->
        raise Image.Unregistered, "Unregistered image: #{user_identifier}"
    end
  end

  def text_position({_doc, content_stream_obj} = context, x, y) do
    case content_stream_obj.value.operations do
      [] ->
        context

      _ ->
        context
        |> ContentStream.add(%ContentStream.ET{})
        |> ContentStream.add(%ContentStream.BT{})
    end
    |> ContentStream.add(ContentStream.Td, tx: x, ty: y)
  end

  def colour(context, {r, g, b}) do
    ContentStream.add(context, ContentStream.Rg, r: r, g: g, b: b)
  end

  def text(context, text, opts \\ []) do
    ContentStream.write_text(context, text, opts)
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

  defp contents({doc, page}) do
    import Document

    doc
    |> add(ContentStream.new(page: page.value))
    |> update(page, fn contents, %Page{} = p ->
      %{p | contents: contents}
    end)
    |> finish(& &1.value.contents)
  end
end
