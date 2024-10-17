defmodule Mudbrick.ContentStreamTest do
  use ExUnit.Case, async: true

  import Mudbrick
  import TestHelper

  alias Mudbrick.ContentStream.Tj
  alias Mudbrick.Font
  alias Mudbrick.Indirect

  describe "aligned text" do
    test "when it changes, start fresh Tj, to keep same line" do
      {_doc, content_stream} =
        new()
        |> page(
          size: :letter,
          fonts: %{bodoni: [file: TestHelper.bodoni()]}
        )
        |> font(:bodoni, size: 10)
        |> text_position(400, 0)
        |> text("a", align: :right)
        |> text("b")

      assert [
               _font,
               _leading,
               _initial_position,
               # offset for a
               "-5.0600000000000005 0 Td",
               # a
               "<00A5> Tj",
               # reset a's offset
               "5.0600000000000005 0 Td",
               # b
               "<00B4> Tj"
             ] =
               content_stream.value.operations
               |> Enum.reverse()
               |> Enum.map(&show/1)
    end

    test "continues same-alignment text on same lines unless newline found" do
      {_doc, content_stream} =
        new()
        |> page(
          size: :letter,
          fonts: %{bodoni: [file: TestHelper.bodoni()]}
        )
        |> font(:bodoni, size: 10)
        |> text_position(400, 0)
        |> text("a")
        |> text("\nb", align: :right)
        |> text("c", align: :right)
        |> text("d")

      assert_in_delta 10.75 - 5.699999999999999 - 5.05, 0, 0.001

      assert [
               _font,
               _leading,
               _initial_position,
               # a
               "<00A5> Tj",
               # offset for right-aligned b = b width + c width
               "-10.75 0 Td",
               # b
               "<00B4> '",
               # reset b's offset, putting us in the correct place for c
               "5.699999999999999 0 Td",
               # c
               "<00B5> Tj",
               # reset c's offset
               "5.05 0 Td",
               # d
               "<00BB> Tj"
             ] =
               content_stream.value.operations
               |> Enum.reverse()
               |> Enum.map(&show/1)
    end

    test "can switch between alignments" do
      {_doc, content_stream} =
        new()
        |> page(
          size: :letter,
          fonts: %{bodoni: [file: TestHelper.bodoni()]}
        )
        |> font(:bodoni, size: 14)
        |> text_position(200, 700)
        |> text("z", align: :right)
        |> text("""
        I am left again


        """)
        |> text(
          """
          I am right again
          """,
          align: :right
        )
        |> text("left again!")

      assert [
               "/F1 14 Tf",
               "16.8 TL",
               "200 700 Td",
               "-6.72 0 Td",
               _z,
               "6.72 0 Td",
               _i_am_left_again,
               "() '",
               "() '",
               "() '",
               "-98.91 0 Td",
               _i_am_right_again,
               "98.91 0 Td",
               "() '",
               _left_again
             ] =
               content_stream.value.operations
               |> Enum.reverse()
               |> Enum.map(&show/1)
    end

    test "is unsupported for built-in fonts right now" do
      assert_raise(Font.NotMeasured, fn ->
        new()
        |> page(
          size: :letter,
          fonts: %{
            helvetica: [
              name: :Helvetica,
              type: :TrueType,
              encoding: :PDFDocEncoding
            ]
          }
        )
        |> font(:helvetica, size: 10)
        |> text("hi", align: :right)
      end)
    end
  end

  test "built-in font linebreaks are converted to the ' operator" do
    {_doc, content_stream} =
      new()
      |> page(
        size: :letter,
        fonts: %{
          helvetica: [
            name: :Helvetica,
            type: :TrueType,
            encoding: :PDFDocEncoding
          ]
        }
      )
      |> font(:helvetica, size: 10)
      |> text_position(0, 700)
      |> text("""
      a
      b\
      """)

    assert content_stream.value.operations
           |> render(2) ==
             """
             (a) Tj
             (b) '\
             """
  end

  test "CID font linebreaks are converted to the ' operator" do
    {_doc, content_stream} =
      new()
      |> page(
        size: :letter,
        fonts: %{bodoni: [file: TestHelper.bodoni()]}
      )
      |> font(:bodoni, size: 10)
      |> text_position(0, 700)
      |> text("""
      a
      b\
      """)

    assert content_stream.value.operations
           |> render(2) ==
             """
             <00A5> Tj
             <00B4> '\
             """
  end

  test "font is assigned to the operator struct when font descendant present" do
    {_doc, content_stream} =
      new()
      |> page(
        size: :letter,
        fonts: %{bodoni: [file: TestHelper.bodoni()]}
      )
      |> font(:bodoni, size: 24)
      |> text_position(0, 700)
      |> text("CO₂")

    [show_text_operation | _] = content_stream.value.operations

    assert %Tj{
             text: "CO₂",
             font: %Font{
               name: :"LibreBodoni-Regular",
               descendant: %Indirect.Object{value: %Font.CIDFont{}}
             }
           } = show_text_operation
  end

  describe "serialisation" do
    test "converts Tj text to the assigned font's glyph IDs in hex" do
      {_doc, content_stream} =
        new()
        |> page(
          size: :letter,
          fonts: %{bodoni: [file: TestHelper.bodoni()]}
        )
        |> font(:bodoni, size: 24)
        |> text_position(0, 700)
        |> text("CO₂")

      assert content_stream.value.operations
             |> render(1) ==
               """
               <001100550174> Tj\
               """
    end

    test "copes with trailing newlines in CID font text" do
      assert new()
             |> page(size: :letter, fonts: %{bodoni: [file: TestHelper.bodoni()]})
             |> font(:bodoni, size: 13)
             |> text("\n")
             |> render()
    end
  end

  defp render(ops, n) do
    ops
    |> Enum.take(n)
    |> Enum.reverse()
    |> Mudbrick.join("\n")
  end
end
