defmodule Mudbrick.TestHelper do
  @bodoni_regular System.fetch_env!("FONT_LIBRE_BODONI_REGULAR") |> File.read!()
  @bodoni_bold System.fetch_env!("FONT_LIBRE_BODONI_BOLD") |> File.read!()
  @franklin_regular System.fetch_env!("FONT_LIBRE_FRANKLIN_REGULAR") |> File.read!()
  @flower Path.join(__DIR__, "fixtures/JPEG_example_flower.jpg") |> File.read!()
  @example_png Path.join(__DIR__, "fixtures/Example.png") |> File.read!()

  alias Mudbrick.Page

  def show(o) do
    Mudbrick.Object.from(o) |> to_string()
  end

  def operations({_doc, content_stream}) do
    content_stream.value.operations
    |> Enum.reverse()
    |> Enum.map(&show/1)
  end

  def bodoni_regular do
    @bodoni_regular
  end

  def bodoni_bold do
    @bodoni_bold
  end

  def franklin_regular do
    @franklin_regular
  end

  def flower do
    @flower
  end

  def example_png do
    @example_png
  end

  def output(f, output_mod) when is_function(f) do
    import Mudbrick

    {doc, _contents_obj} =
      context =
      Mudbrick.new(
        title: "My thing",
        compress: false,
        fonts: %{
          a: [file: bodoni_regular()],
          b: [file: bodoni_bold()],
          c: [file: franklin_regular()]
        }
      )
      |> page(size: Page.size(:letter))

    fonts = Mudbrick.Document.root_page_tree(doc).value.fonts

    block =
      f.(%{
        fonts: %{
          regular: Map.fetch!(fonts, :a).value,
          bold: Map.fetch!(fonts, :b).value,
          franklin_regular: Map.fetch!(fonts, :c).value
        }
      })

    ops = output_mod.from(block).operations

    context
    |> Mudbrick.ContentStream.put(operations: ops)
    |> render()
    |> output()

    ops
  end

  def output(chain) do
    tap(chain, fn rendered ->
      File.write("test.pdf", rendered)
    end)
  end
end

ExUnit.start()
