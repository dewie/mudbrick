defmodule Mudbrick.PredicatesTest do
  use ExUnit.Case, async: true
  doctest Mudbrick.Predicates

  import Mudbrick
  import Mudbrick.Predicates
  import Mudbrick.TestHelper

  describe "with direct glyph encoding" do
    test "with compression, can assert/refute that a piece of text appears" do
      raw_pdf =
        new(compress: true, fonts: %{bodoni: [file: bodoni()]})
        |> page()
        |> text(
          "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWhello, CO₂!WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
          font: :bodoni,
          font_size: 100
        )
        |> render()
        |> IO.iodata_to_binary()

      assert raw_pdf |> has_text?("hello, CO₂!", in_font: bodoni())
      refute raw_pdf |> has_text?("good morning!", in_font: bodoni())
    end

    test "without compression, can assert/refute that a piece of text appears" do
      raw_pdf =
        new(fonts: %{bodoni: [file: bodoni()]})
        |> page()
        |> text("hello, world!", font: :bodoni, font_size: 100)
        |> render()

      assert raw_pdf |> has_text?("hello, world!", in_font: bodoni())
      refute raw_pdf |> has_text?("good morning!", in_font: bodoni())
    end
  end

  describe "with standard encoding" do
    test "with compression, can assert/refute that a piece of text appears" do
      raw_pdf =
        new(
          compress: true,
          fonts: %{
            helvetica: [
              name: :Helvetica,
              type: :TrueType,
              encoding: :PDFDocEncoding
            ]
          }
        )
        |> page()
        |> text(
          "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWhello, world!WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
          font: :helvetica,
          font_size: 100
        )
        |> render()

      assert raw_pdf |> has_text?("hello, world!")
      refute raw_pdf |> has_text?("good morning!")
    end

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
        |> page()
        |> text(
          "hello, world!",
          font: :helvetica,
          font_size: 100
        )
        |> render()

      assert raw_pdf |> has_text?("hello, world!")
      refute raw_pdf |> has_text?("good morning!")
    end
  end
end
