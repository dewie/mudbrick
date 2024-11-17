defmodule Mudbrick do
  @moduledoc """
  API for creating and exporting PDF documents.

  ## General example

  Compression, OTF font with special characters, JPEG and line drawing:

      iex> import Mudbrick.TestHelper                     # import some example fonts and images
      ...> import Mudbrick
      ...> alias Mudbrick.Path
      ...> new(
      ...>   compress: true,                              # flate compression for fonts, text etc.
      ...>   fonts: %{bodoni: bodoni_regular()},          # register an OTF font
      ...>   images: %{flower: flower()}                  # register a JPEG
      ...> )
      ...> |> page(size: {100, 100})
      ...> |> image(                                      # place preregistered JPEG
      ...>   :flower,
      ...>   scale: {100, 100},                           # full page size
      ...>   position: {0, 0}                             # in points (1/72 inch), starts at bottom left
      ...> )
      ...> |> path(fn path ->                             # draw a line
      ...>   import Path
      ...>   path
      ...>   |> move(to: {55, 40})                        # starting near the middle of the page
      ...>   |> line(
      ...>     to: {95, 5},                               # ending near the bottom right
      ...>     width: 6.0,                                # make it fat
      ...>     colour: {1, 0, 0}                          # make it red
      ...>   )
      ...> end)
      ...> |> text(
      ...>   {"CO₂", colour: {0, 0, 1}},                  # write blue text
      ...>   font: :bodoni,                               # in the bodoni font
      ...>   font_size: 14,                               # size 14 points
      ...>   position: {35, 45}                           # 60 points from left, 45 from bottom of page
      ...> )
      ...> |> render()                                    # produce iodata, ready for File.write/2
      ...> |> then(&File.write("examples/compression_font_special_chars.pdf", &1))

  Produces [this](examples/compression_font_special_chars.pdf).

  <object width="400" height="215" data="examples/compression_font_special_chars.pdf?#navpanes=0" type="application/pdf"></object>

  ## Auto-kerning

      iex> import Mudbrick.TestHelper
      ...> import Mudbrick
      ...> new(fonts: %{bodoni: bodoni_bold()})
      ...> |> page(size: {600, 200})
      ...> |> text(
      ...>   [{"Warning\\n", underline: [width: 0.5]}, "MORE ", {"efficiency", underline: [width: 0.5]}],
      ...>   font: :bodoni,
      ...>   font_size: 70,
      ...>   position: {7, 130}
      ...> )
      ...> |> render()
      ...> |> then(&File.write("examples/auto_kerning.pdf", &1))

  Produces [this](examples/auto_kerning.pdf). Notice how the 'a' is underneath the 'W' in 'Warning'.

  <object width="400" height="215" data="examples/auto_kerning.pdf?#navpanes=0" type="application/pdf"></object>
  """

  alias Mudbrick.{
    ContentStream,
    Document,
    Font,
    Image,
    Indirect,
    Page,
    Path,
    TextBlock
  }

  @type context :: {Document.t(), Indirect.Object.t()}
  @type coords :: {number(), number()}
  @type colour :: {number(), number(), number()}

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

  Register an OTF font. Pass the file's raw data.

      iex> Mudbrick.new(fonts: %{bodoni: Mudbrick.TestHelper.bodoni_regular()})

  Register an image.

      iex> Mudbrick.new(images: %{flower: Mudbrick.TestHelper.flower()})

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
  @spec page(Document.t() | context(), Keyword.t()) :: context()
  def page(context, opts \\ [])

  def page({doc, _contents_obj}, opts) do
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
  Insert image previously registered in `new/1` at the given coordinates.

  ## Options

  - `:position` - `{x, y}` in points, relative to bottom-left corner.
  - `:scale` - `{w, h}` in points. To preserve aspect ratio, set either, but not both, to `:auto`.
  - `:skew` - `{x, y}`, passed through to PDF `cm` operator.

  All options default to `{0, 0}`.

  ## Examples

      iex> Mudbrick.new(images: %{lovely_flower: Mudbrick.TestHelper.flower()})
      ...> |> Mudbrick.page()
      ...> |> Mudbrick.image(:lovely_flower, position: {100, 100}, scale: {100, 100})

  Forgetting to register the image:

      iex> Mudbrick.new()
      ...> |> Mudbrick.page()
      ...> |> Mudbrick.image(:my_face, position: {100, 100}, scale: {100, 100})
      ** (Mudbrick.Image.Unregistered) Unregistered image: my_face

  Auto height:

      iex> Mudbrick.new(images: %{lovely_flower: Mudbrick.TestHelper.flower()})
      ...> |> Mudbrick.page(size: {50, 50})
      ...> |> Mudbrick.image(:lovely_flower, position: {0, 0}, scale: {50, :auto})
      ...> |> Mudbrick.render()
      ...> |> then(&File.write("examples/image_auto_aspect_scale.pdf", &1))

  <object width="400" height="100" data="examples/image_auto_aspect_scale.pdf?#navpanes=0" type="application/pdf"></object>

  Attempting to set both width and height to `:auto`:

      iex> Mudbrick.new(images: %{lovely_flower: Mudbrick.TestHelper.flower()})
      ...> |> Mudbrick.page()
      ...> |> Mudbrick.image(:lovely_flower, position: {100, 100}, scale: {:auto, :auto})
      ** (Mudbrick.Image.AutoScalingError) Auto scaling works with width or height, but not both.

  Tip: to make the image fit the page, pass e.g. `Page.size(:a4)` as the
  `scale` and `{0, 0}` as the `position`.
  """

  @spec image(context(), atom(), Image.image_options()) :: context()
  def image({doc, _content_stream_obj} = context, user_identifier, opts \\ []) do
    import ContentStream

    case Map.fetch(Document.root_page_tree(doc).value.images, user_identifier) do
      {:ok, image} ->
        context
        |> add(%ContentStream.QPush{})
        |> add(ContentStream.Cm.new(cm_opts(image.value, opts)))
        |> add(%ContentStream.Do{image: image.value})
        |> add(%ContentStream.QPop{})

      :error ->
        raise Image.Unregistered, "Unregistered image: #{user_identifier}"
    end
  end

  @doc """
  Write text at the given coordinates.

  ## Top-level options

  - `:colour` - `{r, g, b}` tuple. Each element is a number between 0 and 1. Default: `{0, 0, 0}`.
  - `:font` - Name of a font previously registered with `new/1`. Required unless you've only registered one font.
  - `:position` - Coordinates from bottom-left of page in points. Default: `{0, 0}`.
  - `:font_size` - Size in points. Default: `12`.
  - `:leading` - Leading in points. Default is 120% of `:font_size`.
  - `:align` - Either `:left` or `:right`. Default: `:left`. Note that the rightmost point of right-aligned text is the horizontal offset provided to `:position`.

  ## Individual write options

  When passing a `{text, opts}` tuple or list of tuples to this function, `opts` are:

  - `:colour` - `{r, g, b}` tuple. Each element is a number between 0 and 1. Overrides the top-level option.
  - `:font` - Name of a font previously registered with `new/1`. Overrides the top-level option.
  - `:font_size` - Size in points. Overrides the top-level option.
  - `:leading` - The number of points to move down the page on the following linebreak. Overrides the top-level option.

  ## Examples

  Write "CO₂" in the bottom-left corner of a default-sized page.

      iex> import Mudbrick.TestHelper
      ...> import Mudbrick
      ...> new(fonts: %{bodoni: bodoni_regular()})
      ...> |> page()
      ...> |> text("CO₂")

  Write "I am red" at 200, 200, where "red" is in red.

      iex> import Mudbrick.TestHelper
      ...> import Mudbrick
      ...> new(fonts: %{bodoni: bodoni_regular()})
      ...> |> page()
      ...> |> text(["I am ", {"red", colour: {1, 0, 0}}], position: {200, 200})

  Write "I am bold" at 200, 200, where "bold" is in bold.

      iex> import Mudbrick.TestHelper
      ...> import Mudbrick
      ...> new(fonts: %{regular: bodoni_regular(), bold: bodoni_bold()})
      ...> |> page()
      ...> |> text(["I am ", {"bold", font: :bold}], font: :regular, position: {200, 200})

  Underlined text.

      iex> import Mudbrick
      ...> new(fonts: %{bodoni: Mudbrick.TestHelper.bodoni_regular()})
      ...> |> page(size: {100, 50})
      ...> |> text([{"heading\\n", leading: 20}, "nounderline\\n", "now ", {"underline", underline: [width: 1]}, " that"], position: {8, 40}, font_size: 8)
      ...> |> render()
      ...> |> then(&File.write("examples/underlined_text.pdf", &1))

  Produces [this PDF](examples/underlined_text.pdf?#navpanes=0).

  <object width="400" height="130" data="examples/underlined_text.pdf?#navpanes=0" type="application/pdf"></object>

  Underlined, right-aligned text.

      iex> import Mudbrick
      ...> new(fonts: %{bodoni: Mudbrick.TestHelper.bodoni_regular()})
      ...> |> page(size: {100, 50})
      ...> |> text([{"heading\\n", leading: 20}, "nounderline\\n", "now ", {"underline", underline: [width: 1]}, " that"], position: {90, 40}, font_size: 8, align: :right)
      ...> |> render()
      ...> |> then(&File.write("examples/underlined_text_right_align.pdf", &1))

  Produces [this PDF](examples/underlined_text_right_align.pdf?#navpanes=0).

  <object width="400" height="130" data="examples/underlined_text_right_align.pdf?#navpanes=0" type="application/pdf"></object>
  """

  @spec text(context(), Mudbrick.TextBlock.write(), Mudbrick.TextBlock.options()) :: context()
  def text(context, write_or_writes, opts \\ [])

  def text({doc, _contents_obj} = context, writes, opts) when is_list(writes) do
    ContentStream.update_operations(context, fn ops ->
      output =
        doc
        |> text_block(writes, fetch_font(doc, opts))
        |> TextBlock.Output.from()

      output.operations ++ ops
    end)
  end

  def text(context, write, opts) do
    text(context, [write], opts)
  end

  @doc """
  Vector drawing. *f* is a function that takes a `Mudbrick.Path` and
  returns a `Mudbrick.Path`. See the functions in that module.

  ## Example

  A thick diagonal red line and a black rectangle with a thinner (default)
  line on top.

      iex> import Mudbrick
      ...> new()
      ...> |> page(size: {100, 100})
      ...> |> path(fn path ->
      ...>   import Mudbrick.Path
      ...>   path
      ...>   |> move(to: {0, 0})
      ...>   |> line(to: {50, 50}, colour: {1, 0, 0}, width: 9)
      ...>   |> rectangle(lower_left: {0, 0}, dimensions: {50, 60})
      ...> end)
      ...> |> render()
      ...> |> then(&File.write("examples/drawing.pdf", &1))

  Produces [this drawing](examples/drawing.pdf).

  <object width="400" height="215" data="examples/drawing.pdf?#navpanes=0" type="application/pdf"></object>
  """

  @spec path(context(), (Path.t() -> Path.t())) :: context()
  def path(context, f) do
    path = f.(Path.new())

    context
    |> ContentStream.update_operations(fn ops ->
      Path.Output.from(path).operations ++ ops
    end)
  end

  @doc """
  Produce `iodata` from the current document.
  """
  @spec render(Document.t() | context()) :: iodata()
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
  @spec compress(iodata()) :: iodata()
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
  @spec decompress(iodata()) :: iodata()
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

  defp text_block(doc, writes, top_level_opts) do
    Enum.reduce(writes, Mudbrick.TextBlock.new(top_level_opts), fn
      {text, opts}, acc ->
        Mudbrick.TextBlock.write(acc, text, fetch_font(doc, opts))

      text, acc ->
        Mudbrick.TextBlock.write(acc, text, [])
    end)
  end

  @spec cm_opts(Mudbrick.Image.t(), Image.image_options()) :: Mudbrick.ContentStream.Cm.options()
  defp cm_opts(image, image_opts) do
    scale =
      case image_opts[:scale] do
        {:auto, :auto} ->
          raise Mudbrick.Image.AutoScalingError,
                "Auto scaling works with width or height, but not both."

        {w, :auto} ->
          ratio = w / image.width
          {w, image.height * ratio}

        {:auto, h} ->
          ratio = h / image.height
          {image.width * ratio, h}

        otherwise ->
          otherwise
      end

    Keyword.put(image_opts, :scale, scale)
  end

  defp fetch_font(doc, opts) do
    default_font =
      case Map.values(Document.root_page_tree(doc).value.fonts) do
        [font] -> font.value
        _ -> nil
      end

    Keyword.update(opts, :font, default_font, fn user_identifier ->
      case Map.fetch(Document.root_page_tree(doc).value.fonts, user_identifier) do
        {:ok, font} ->
          font.value

        :error ->
          raise Font.Unregistered, "Unregistered font: #{user_identifier}"
      end
    end)
  end
end
