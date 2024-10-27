defmodule Mudbrick.TestHelper do
  @bodoni_regular System.fetch_env!("FONT_LIBRE_BODONI_REGULAR") |> File.read!()
  @bodoni_bold System.fetch_env!("FONT_LIBRE_BODONI_BOLD") |> File.read!()
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

  def bodoni_regular do
    @bodoni_regular
  end

  def bodoni_bold do
    @bodoni_bold
  end

  def flower do
    @flower
  end

  def example_png do
    @example_png
  end
end

ExUnit.start()
