defmodule TestHelper do
  @bodoni System.fetch_env!("FONT_LIBRE_BODONI_REGULAR") |> File.read!()
  @flower Path.join(__DIR__, "fixtures/JPEG_example_flower.jpg") |> File.read!()

  def show(o) do
    Mudbrick.Object.from(o) |> to_string()
  end

  def bodoni do
    @bodoni
  end

  def flower do
    @flower
  end
end

ExUnit.start()
