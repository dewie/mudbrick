defmodule Mudbrick.PredicatesTest do
  use ExUnit.Case, async: true
  doctest Mudbrick.Predicates

  import Mudbrick
  import Mudbrick.Predicates
  import Mudbrick.TestHelper

  test "with compression, can assert/refute that a piece of text appears" do
    raw_pdf =
      new(compress: true, fonts: %{bodoni: bodoni_regular()})
      |> page()
      |> text(
        "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWhello, CO₂!WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
        font_size: 100
      )
      |> render()
      |> IO.iodata_to_binary()

    assert raw_pdf |> has_text?("hello, CO₂!", in_font: bodoni_regular())
    refute raw_pdf |> has_text?("good morning!", in_font: bodoni_regular())
  end

  test "without compression, can assert/refute that a piece of text appears" do
    raw_pdf =
      new(fonts: %{bodoni: bodoni_regular()})
      |> page()
      |> text("hello, world!", font_size: 100)
      |> render()

    assert raw_pdf |> has_text?("hello, world!", in_font: bodoni_regular())
    refute raw_pdf |> has_text?("good morning!", in_font: bodoni_regular())
  end
end
