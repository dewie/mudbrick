defmodule TestHelper do
  @bodoni System.fetch_env!("FONT_LIBRE_BODONI_REGULAR") |> File.read!()
  @flower Path.join(__DIR__, "fixtures/JPEG_example_flower.jpg") |> File.read!()
  @example_png Path.join(__DIR__, "fixtures/Example.png") |> File.read!()

  def show(o) do
    Mudbrick.Object.from(o) |> to_string()
  end

  def operations({_doc, content_stream}) do
    content_stream.value.operations
    |> Enum.reverse()
    |> Enum.map(&show/1)
  end

  def bodoni do
    @bodoni
  end

  def flower do
    @flower
  end

  def example_png do
    @example_png
  end
end

ExUnit.start()
