defmodule Mbc.PredicatesTest do
  use ExUnit.Case, async: true

  import Mudbrick
  import Mudbrick.Predicates
  import TestHelper

  describe "with direct glyph encoding" do
    test "with compression, can assert/refute that a piece of text appears" do
      raw_pdf =
        new(compress: true, fonts: %{bodoni: [file: bodoni()]})
        |> page()
        |> font(:bodoni, size: 100)
        |> text(
          "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWhello, CO₂!WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW"
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
        |> font(:bodoni, size: 100)
        |> text("hello, world!")
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
        |> font(:helvetica, size: 100)
        |> text(
          "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWhello, world!WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW"
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
        |> font(:helvetica, size: 100)
        |> text("hello, world!")
        |> render()

      assert raw_pdf |> has_text?("hello, world!")
      refute raw_pdf |> has_text?("good morning!")
    end
  end
end
