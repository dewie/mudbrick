defmodule Mbc.PredicatesTest do
  use ExUnit.Case, async: true

  import Mudbrick
  import Mudbrick.Predicates

  describe "with direct glyph encoding" do
    test "with compression, can assert/refute that a piece of text appears" do
      raw_pdf =
        new(compress: true, fonts: %{bodoni: [file: TestHelper.bodoni()]})
        |> page(size: :letter)
        |> font(:bodoni, size: 100)
        |> text(
          "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWhello, CO₂!WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW"
        )
        |> render()
        |> IO.iodata_to_binary()

      assert raw_pdf |> has_text?("hello, CO₂!", in_font: TestHelper.bodoni())
      refute raw_pdf |> has_text?("good morning!", in_font: TestHelper.bodoni())
    end

    test "without compression, can assert/refute that a piece of text appears" do
      raw_pdf =
        new(fonts: %{bodoni: [file: TestHelper.bodoni()]})
        |> page(size: :letter)
        |> font(:bodoni, size: 100)
        |> text("hello, world!")
        |> render()

      assert raw_pdf |> has_text?("hello, world!", in_font: TestHelper.bodoni())
      refute raw_pdf |> has_text?("good morning!", in_font: TestHelper.bodoni())
    end
  end

  describe "with standard encoding, no compression" do
    test "without compression, can assert/refute that a piece of text appears" do
      raw_pdf =
        new(
          fonts: %{
            helvetica: [
              name: :Helvetica,
              type: :TrueType,
              encoding: :PDFDocEncoding
            ]
          }
        )
        |> page(size: :letter)
        |> font(:helvetica, size: 100)
        |> text("hello, world!")
        |> render()

      assert raw_pdf |> has_text?("hello, world!")
      refute raw_pdf |> has_text?("good morning!")
    end
  end
end
