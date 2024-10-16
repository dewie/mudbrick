defmodule TestHelper do
  @bodoni System.fetch_env!("FONT_LIBRE_BODONI_REGULAR") |> File.read!()

  def show(o) do
    Mudbrick.Object.from(o) |> to_string()
  end

  def bodoni do
    @bodoni
  end
end

ExUnit.start()
