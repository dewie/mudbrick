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

  def text(context, text, opts \\ []) do
    context =
      case Keyword.get(opts, :colour) do
        {r, g, b} ->
          ContentStream.add(context, ContentStream.Rg, r: r, g: g, b: b)

        _ ->
          context
      end

    write_text(context, text, opts)
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

  defp align(context, "", _opts) when not is_nil(context) do
    context
  end

  defp align({_doc, content_stream} = context, text, opts) do
    case Keyword.get(opts, :align, :left) do
      :left ->
        context

      :right ->
        tf = latest_font_operation!(content_stream)

        {glyph_ids, _positions} = OpenType.layout_text(tf.font.parsed, text)

        width =
          for id <- glyph_ids, reduce: 0 do
            acc ->
              glyph_width = Enum.at(tf.font.parsed.glyphWidths, id)
              width_in_points = glyph_width / 1000 * tf.size

              acc + width_in_points
          end

        ContentStream.add(context, ContentStream.Td, tx: -width, ty: 0, purpose: :align_right)
    end
  end

  defp negate_right_alignment({_doc, cs} = context) do
    if td = current_right_alignment(cs) do
      ContentStream.add(context, %{td | tx: -td.tx, purpose: :negate_align_right})
    else
      context
    end
  end

  defp write_text({_doc, content_stream} = context, text, opts) do
    import ContentStream

    tf = latest_font_operation!(content_stream)
    old_alignment = if currently_right_aligned?(content_stream), do: :right, else: :left
    new_alignment = Keyword.get(opts, :align, :left)

    [first_part | parts] = String.split(text, "\n")

    context = align(context, first_part, opts)

    case {first_part, old_alignment, new_alignment} do
      {"", _, _} ->
        context

      {text, :left, _} ->
        context
        |> add(ContentStream.Tj, font: tf.font, text: text)
        |> negate_right_alignment()

      {text, :right, :right} ->
        context
        |> add(ContentStream.Apostrophe, font: tf.font, text: text)
        |> negate_right_alignment()

      {text, :right, :left} ->
        add(context, ContentStream.Apostrophe, font: tf.font, text: text)
    end
    |> then(fn context ->
      for part <- parts, reduce: context do
        acc ->
          context =
            acc
            |> align(part, opts)
            |> add(ContentStream.Apostrophe, font: tf.font, text: part)

          if new_alignment == :right do
            context
            |> negate_right_alignment()
          else
            context
          end
      end
    end)
  end

  defp currently_right_aligned?(content_stream) do
    case Enum.find(
           content_stream.value.operations,
           &match?(%ContentStream.Td{}, &1)
         ) do
      %ContentStream.Td{purpose: :align_right} -> true
      %ContentStream.Td{purpose: :negate_align_right} -> true
      _ -> false
    end
  end

  defp current_right_alignment(content_stream) do
    case Enum.find(
           content_stream.value.operations,
           &match?(%ContentStream.Td{}, &1)
         ) do
      %ContentStream.Td{purpose: :align_right} = td -> td
      _ -> nil
    end
  end

  defp latest_font_operation!(content_stream) do
    Enum.find(
      content_stream.value.operations,
      &match?(%ContentStream.Tf{}, &1)
    ) || raise Font.NotSet, "No font chosen"
  end
end
