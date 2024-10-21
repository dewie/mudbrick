defmodule Mudbrick.TextTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Mudbrick
  import Mudbrick.TestHelper

  alias Mudbrick.ContentStream.Tj
  alias Mudbrick.Font
  alias Mudbrick.Indirect

  @fonts_helvetica %{
    helvetica: [
      name: :Helvetica,
      type: :TrueType,
      encoding: :PDFDocEncoding
    ]
  }

  describe "with compression enabled" do
    test "compresses text stream" do
      text = "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW"

      {_doc, compressed_content_stream} =
        new(compress: true, fonts: @fonts_helvetica)
        |> page()
        |> font(:helvetica, size: 10, leading: 14)
        |> text(text)

      {_doc, uncompressed_content_stream} =
        new(compress: false, fonts: @fonts_helvetica)
        |> page()
        |> font(:helvetica, size: 10, leading: 14)
        |> text(text)

      assert IO.iodata_length(Mudbrick.Object.from(compressed_content_stream)) <
               IO.iodata_length(Mudbrick.Object.from(uncompressed_content_stream))
    end
  end

  test "can set leading" do
    assert [
             "/F1 10 Tf",
             "14 TL",
             "(black and ) Tj"
           ] =
             new(fonts: @fonts_helvetica)
             |> page()
             |> font(:helvetica, size: 10, leading: 14)
             |> text("black and ")
             |> operations()
  end

  describe "colour" do
    property "it's an error to set a colour above 1" do
      valid_colour = float(min: 0, max: 1)

      check all initial_list <- list_of(valid_colour, length: 2),
                insertion_point <- integer(0..2),
                invalid_colour <- float(min: 1.00001),
                colour <-
                  initial_list
                  |> List.insert_at(insertion_point, invalid_colour)
                  |> List.to_tuple()
                  |> constant() do
        e =
          assert_raise(Mudbrick.ContentStream.InvalidColour, fn ->
            new(fonts: %{my_bodoni: [file: Mudbrick.TestHelper.bodoni()]})
            |> page()
            |> colour(colour)
          end)

        assert e.message == "tuple must be made of floats or integers between 0 and 1"
      end
    end

    test "can be set on a piece of text" do
      {_doc, content_stream} =
        new(fonts: @fonts_helvetica)
        |> page()
        |> font(:helvetica, size: 10)
        |> text("black and ")
        |> colour({1.0, 0.0, 0.0})
        |> text("""
        red
        text\
        """)

      assert show(content_stream) =~
               """
               BT
               /F1 10 Tf
               12.0 TL
               (black and ) Tj
               1.0 0.0 0.0 rg
               (red) Tj
               (text) '
               ET
               """
    end
  end

  describe "positioning text" do
    test "starts a new text object" do
      assert [
               _font,
               _leading,
               _text,
               "ET",
               "BT",
               "200 700 Td",
               _text2
             ] =
               new(fonts: %{bodoni: [file: bodoni()]})
               |> page()
               |> font(:bodoni, size: 14)
               |> text("hi")
               |> text_position(200, 700)
               |> text("there")
               |> operations()
    end

    test "doesn't produce empty objects" do
      assert [
               "200 700 Td"
             ] =
               new(fonts: %{bodoni: [file: bodoni()]})
               |> page()
               |> text_position(200, 700)
               |> operations()
    end
  end

  describe "aligned text" do
    test "when it changes, starts fresh Tj, to keep same line" do
      assert [
               _initial_position,
               _font,
               _leading,
               # offset for a
               "-5.0600000000000005 0 Td",
               # a
               "<00A5> Tj",
               # reset a's offset
               "5.0600000000000005 0 Td",
               # b
               "<00B4> Tj"
             ] =
               new(fonts: %{bodoni: [file: bodoni()]})
               |> page(size: :letter)
               |> text_position(400, 0)
               |> font(:bodoni, size: 10)
               |> text("a", align: :right)
               |> text("b")
               |> operations()
    end

    test "continues same-alignment text on same lines unless newline found" do
      assert_in_delta 10.75 - 5.699999999999999 - 5.05, 0, 0.001

      assert [
               _initial_position,
               _font,
               _leading,
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
               new(fonts: %{bodoni: [file: bodoni()]})
               |> page(size: :letter)
               |> text_position(400, 0)
               |> font(:bodoni, size: 10)
               |> text("a")
               |> text("\nb", align: :right)
               |> text("c", align: :right)
               |> text("d")
               |> operations()
    end

    test "can switch between alignments" do
      assert [
               "200 700 Td",
               "/F1 14 Tf",
               "16.8 TL",
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
               new(fonts: %{bodoni: [file: bodoni()]})
               |> page(size: :letter)
               |> text_position(200, 700)
               |> font(:bodoni, size: 14)
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
               |> operations()
    end

    test "is unsupported for built-in fonts right now" do
      assert_raise(Font.NotMeasured, fn ->
        new(fonts: @fonts_helvetica)
        |> page(size: :letter)
        |> font(:helvetica, size: 10)
        |> text("hi", align: :right)
      end)
    end
  end

  test "built-in font linebreaks are converted to the ' operator" do
    assert ["(a) Tj", "(b) '"] =
             new(fonts: @fonts_helvetica)
             |> page(size: :letter)
             |> font(:helvetica, size: 10)
             |> text_position(0, 700)
             |> text("""
             a
             b\
             """)
             |> operations()
             |> Enum.take(-2)
  end

  test "CID font linebreaks are converted to the ' operator" do
    assert [
             "<00A5> Tj",
             "<00B4> '"
           ] =
             new(fonts: %{bodoni: [file: bodoni()]})
             |> page(size: :letter)
             |> font(:bodoni, size: 10)
             |> text_position(0, 700)
             |> text("""
             a
             b\
             """)
             |> operations()
             |> Enum.take(-2)
  end

  test "font is assigned to the operator struct when font descendant present" do
    {_doc, content_stream} =
      new(fonts: %{bodoni: [file: bodoni()]})
      |> page(size: :letter)
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
      assert ["<001100550174> Tj"] =
               new(fonts: %{bodoni: [file: bodoni()]})
               |> page()
               |> font(:bodoni, size: 24)
               |> text_position(0, 700)
               |> text("CO₂")
               |> operations()
               |> Enum.take(-1)
    end

    test "copes with trailing newlines in CID font text" do
      assert new(fonts: %{bodoni: [file: bodoni()]})
             |> page()
             |> font(:bodoni, size: 13)
             |> text("\n")
             |> render()
    end
  end
end
