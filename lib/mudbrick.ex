defmodule Mudbrick do
  @moduledoc """
  Top-level API for creating documents.

  ## Examples

      iex> import Mudbrick.TestHelper                 # import some example fonts and images
      ...> import Mudbrick
      ...> alias Mudbrick.Page
      ...> new(
      ...>   compress: true,                          # flate compression for fonts, text etc.
      ...>   fonts: %{bodoni: [file: bodoni()]},      # register an OTF font
      ...>   images: %{flower: [file: flower()]}      # register a JPEG
      ...> )
      ...> |> page(size: Page.size(:letter))
      ...> |> image(                                  # place preregistered JPEG
      ...>   :flower,
      ...>   scale: {100, 100},
      ...>   position: {50, 600}                      # in points (1/72 inch), starts at bottom left
      ...> )
      ...> |> text_position(200, 700)                 # set text start position from bottom left
      ...> |> font(:bodoni, size: 14)                 # choose preregistered font
      ...> |> colour({1, 0, 0})                       # make text red
      ...> |> text("CO₂", align: :right)              # write text in current font, with right side
      ...>                                            # anchored to 200 points from left of page
      ...> |> render()                                # produces iodata, can go straight to File.write/2
      ...> |> IO.iodata_to_binary()                   # or turned into a (non-String) binary
  """

  alias Mudbrick.ContentStream
  alias Mudbrick.Document
  alias Mudbrick.Font
  alias Mudbrick.Image
  alias Mudbrick.Page

  @doc """
  Start a new document.

  ## Options

  - `:compress` - when set to `true`, apply deflate compression to streams (if compression saves space).
  - `:fonts` - register OTF or built-in fonts for later use.
  - `:images` - register images for later use.

  ## Examples

  Register an OTF font. Pass the file's raw data to the `:file` option.

      iex> Mudbrick.new(fonts: %{bodoni: [file: Mudbrick.TestHelper.bodoni()]})

  Or a built-in font. Note that these don't support right-alignment or special characters.

      iex> Mudbrick.new(fonts: %{helvetica: [name: :Helvetica, type: :TrueType, encoding: :PDFDocEncoding]})

  Register an image.

      iex> Mudbrick.new(images: %{flower: [file: Mudbrick.TestHelper.flower()]})
  """

  @spec new(opts :: Keyword.t()) :: Document.t()
  def new(opts \\ []) do
    Document.new(opts)
  end

  @doc """
  Start a new page upon which future operators should apply.

  ## Options

  - `:size` - a tuple of `{width, height}`
  """
  def page(context, opts \\ [])

  def page({doc, _page}, opts) do
    page(doc, opts)
  end

  def page(doc, opts) do
    Page.add(
      doc,
      Keyword.put_new(
        opts,
        :size,
        Page.size(:a4)
      )
    )
    |> contents()
  end

  @doc """
  Set the current font using a name previously registered in `new/1`.

  ## Example

      iex> Mudbrick.new(fonts: %{my_bodoni: [file: Mudbrick.TestHelper.bodoni()]})
      ...> |> Mudbrick.page()
      ...> |> Mudbrick.font(:my_bodoni, size: 14)
  """
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

  @doc """
  Set the current fill colour (currently only for text).

  Takes an `{r, g, b}` tuple.

  ## Examples

  Green text:

      iex> Mudbrick.new(fonts: %{my_bodoni: [file: Mudbrick.TestHelper.bodoni()]})
      ...> |> Mudbrick.page()
      ...> |> Mudbrick.colour({0, 1, 0})

  Invalid:

      iex> Mudbrick.new(fonts: %{my_bodoni: [file: Mudbrick.TestHelper.bodoni()]})
      ...> |> Mudbrick.page()
      ...> |> Mudbrick.colour({2, 0, 0})
      ** (Mudbrick.ContentStream.InvalidColour) tuple must be made of floats or integers between 0 and 1
  """
  def colour(context, {r, g, b}) do
    ContentStream.add(context, ContentStream.Rg.new(r: r, g: g, b: b))
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

  @doc false
  def to_hex(n) do
    n
    |> Integer.to_string(16)
    |> String.pad_leading(4, "0")
  end

  @doc false
  def join(a, separator \\ " ")

  def join(tuple, separator) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> join(separator)
  end

  def join(list, separator) do
    Enum.map_join(list, separator, &Mudbrick.Object.from/1)
  end

  @doc """
  Compress data with the same method that PDF generation does. Useful for testing.

  ## Example

      iex> Mudbrick.compress(["hi", "there", ["you"]])
      [<<120, 156, 203, 200, 44, 201, 72, 45, 74, 173, 204, 47, 5, 0, 23, 45, 4, 71>>]
  """
  def compress(data) do
    z = :zlib.open()
    :ok = :zlib.deflateInit(z)
    deflated = :zlib.deflate(z, data, :finish)
    :zlib.deflateEnd(z)
    :zlib.close(z)
    deflated
  end

  @doc """
  Decompress data with the same method that PDF generation does. Useful for testing.

  ## Example

      iex> Mudbrick.decompress([<<120, 156, 203, 200, 44, 201, 72, 45, 74, 173, 204, 47, 5, 0, 23, 45, 4, 71>>])
      ["hithereyou"]
  """
  def decompress(data) do
    z = :zlib.open()
    :zlib.inflateInit(z)
    inflated = :zlib.inflate(z, data)
    :zlib.inflateEnd(z)
    :zlib.close(z)
    inflated
  end

  defp contents({doc, page}) do
    import Document

    doc
    |> add(ContentStream.new(compress: doc.compress, page: page.value))
    |> update(page, fn contents, %Page{} = p ->
      %{p | contents: contents}
    end)
    |> finish(& &1.value.contents)
  end
end
