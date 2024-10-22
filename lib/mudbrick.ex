defmodule Mudbrick do
  @moduledoc """
  Top-level API for creating documents.

  ## Example

  Compression, OTF font with special characters and image placement:

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

  - `:compress` - when set to `true`, apply deflate compression to streams (if
    compression saves space). Default: `false`
  - `:fonts` - register OTF or built-in fonts for later use.
  - `:images` - register images for later use.

  The following options define metadata for the document:

  - `:producer` - software used to create the document, default: `"Mudbrick"`
  - `:creator_tool` - tool used to create the document, default: `"Mudbrick"`
  - `:create_date` - `DateTime` representing the document's creation time
  - `:modify_date` - `DateTime` representing the document's last update time
  - `:title` - title (can change e.g. browser window title), default: `nil`
  - `:creators` - list of names of the creators of the document, default: `[]`

  ## Examples

  Register an OTF font. Pass the file's raw data to the `:file` option.

      iex> Mudbrick.new(fonts: %{bodoni: [file: Mudbrick.TestHelper.bodoni()]})

  Or a built-in font. Note that these don't support right-alignment or special characters.

      iex> Mudbrick.new(fonts: %{helvetica: [name: :Helvetica, type: :TrueType, encoding: :PDFDocEncoding]})

  Register an image.

      iex> Mudbrick.new(images: %{flower: [file: Mudbrick.TestHelper.flower()]})

  Set document metadata.

      iex> Mudbrick.new(title: "The best PDF", producer: "My cool software")
  """

  @spec new(opts :: Document.options()) :: Document.t()
  def new(opts \\ []) do
    Document.new(opts)
  end

  @doc """
  Start a new page upon which future operators should apply.

  ## Options

  - `:size` - a tuple of `{width, height}`. Some standard sizes available in `Mudbrick.Page.size/1`.
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

  Forgetting to set the font is an error:

      iex> Mudbrick.new(fonts: %{my_bodoni: [file: Mudbrick.TestHelper.bodoni()]})
      ...> |> Mudbrick.page()
      ...> |> Mudbrick.text("oops!")
      ** (Mudbrick.Font.NotSet) No font chosen

  Forgetting to register the font is an error:

      iex> Mudbrick.new()
      ...> |> Mudbrick.page()
      ...> |> Mudbrick.font(:helvetica, size: 21)
      ** (Mudbrick.Font.Unregistered) Unregistered font: helvetica
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

  @doc """
  Insert image previously registered in `new/1` at the given coordinates.

  ## Options

  - `:position` - `{x, y}` in points, relative to bottom-left corner.
  - `:scale` - `{w, h}` in points.
  - `:skew` - `{x, y}`, passed through to PDF `cm` operator.

  All options default to `{0, 0}`.

  ## Examples

      iex> Mudbrick.new(images: %{lovely_flower: [file: Mudbrick.TestHelper.flower()]})
      ...> |> Mudbrick.page()
      ...> |> Mudbrick.image(:lovely_flower, position: {100, 100}, scale: {100, 100})

      iex> Mudbrick.new()
      ...> |> Mudbrick.page()
      ...> |> Mudbrick.image(:my_face, position: {100, 100}, scale: {100, 100})
      ** (Mudbrick.Image.Unregistered) Unregistered image: my_face

  Tip: to make the image fit the page, pass e.g. `Page.size(:a4)` as the
  `scale` and `{0, 0}` as the `position`.
  """
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

  @doc """
  Set the position for future calls to `text/3`, relative to the current page's
  bottom left corner. Starts a new PDF text object (`BT`/`ET`).
  """
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

  @doc """
  Write text at the current position. Repeated calls to this do not produce newlines.

  ## Options

  - `:align` - either `:left` or `:right`. When `:right`, text is right-aligned
    to the current position set with `text_position/3`. Default: `:left`.
  """
  def text(context, text, opts \\ []) do
    ContentStream.write_text(context, text, opts)
  end

  @doc """
  Produce `iodata` from the current document.
  """
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
