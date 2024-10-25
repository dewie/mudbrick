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
        |> font(:helvetica, size: 10)
        |> text(text)

      {_doc, uncompressed_content_stream} =
        new(compress: false, fonts: @fonts_helvetica)
        |> page()
        |> font(:helvetica, size: 10)
        |> text(text)

      assert IO.iodata_length(Mudbrick.Object.from(compressed_content_stream)) <
               IO.iodata_length(Mudbrick.Object.from(uncompressed_content_stream))
    end
  end

  test "can set leading" do
    assert [
             "BT",
             "0 0 Td",
             "/F1 10 Tf",
             "14 TL",
             "(hello there) Tj",
             "ET"
           ] =
             new(fonts: @fonts_helvetica)
             |> page()
             |> font(:helvetica, size: 10, leading: 14)
             |> text("hello there")
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
               0 0 Td
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

  describe "text position" do
    test "gets written at start of subsequent text objects" do
      assert [
               "BT",
               "200 700 Td",
               "/F1 14 Tf",
               "16.8 TL",
               "(hi) Tj",
               "(there) Tj",
               "ET"
             ] =
               new(fonts: @fonts_helvetica)
               |> page()
               |> font(:helvetica, size: 14)
               |> text_position(200, 700)
               |> text("hi")
               |> text("there")
               |> operations()
    end

    test "doesn't produce empty objects" do
      assert [] =
               new(fonts: %{bodoni: [file: bodoni()]})
               |> page()
               |> text_position(200, 700)
               |> operations()
    end
  end

  describe "aligned text" do
    test "when it changes, starts fresh text object, but keeps same 'line'" do
      assert [
               "BT",
               "400 12 Td",
               "/F1 10 Tf",
               "12.0 TL",
               # offset for a
               "-5.0600000000000005 0 Td",
               # a
               "<00A5> Tj",
               # reset a's offset
               "ET",
               "BT",
               "400 12 Td",
               _font,
               "12.0 TL",
               # b
               "<00B4> Tj",
               "ET"
             ] =
               new(fonts: %{bodoni: [file: bodoni()]})
               |> page(size: :letter)
               |> text_position(400, 12)
               |> font(:bodoni, size: 10)
               |> text("a", align: :right)
               |> text("b")
               |> operations()
    end

    test "continues same-alignment text on same lines unless newline found" do
      assert [
               "BT",
               "400 100 Td",
               "/F1 10 Tf",
               "12.0 TL",
               _a,
               "ET",
               # 'useless' BT/ET
               "BT",
               "400 100 Td",
               "/F1 10 Tf",
               "12.0 TL",
               "ET",
               "BT",
               "400 88.0 Td",
               "-16.43 0 Td",
               _b,
               _c,
               "ET",
               "BT",
               "400 76.0 Td",
               _d,
               "ET",
               "BT",
               "400 76.0 Td",
               "/F1 10 Tf",
               "12.0 TL",
               _e,
               "ET"
             ] =
               new(fonts: %{bodoni: [file: bodoni()]})
               |> page(size: :letter)
               |> text_position(400, 100)
               |> font(:bodoni, size: 10)
               |> text("a")
               |> text("\nb", align: :right)
               |> text("c\nd", align: :right)
               |> text("e")
               |> operations()
    end

    test "can switch between alignments" do
      assert [
               "BT",
               "200 700 Td",
               "/F1 14 Tf",
               "16.8 TL",
               "-6.72 0 Td",
               _z,
               "ET",
               "BT",
               "200 700 Td",
               "/F1 14 Tf",
               "16.8 TL",
               _i_am_left_again,
               "() '",
               "() '",
               "() '",
               "ET",
               "BT",
               "200 649.6000000000001 Td",
               "/F1 14 Tf",
               "16.8 TL",
               "-98.91 0 Td",
               _i_am_right_again,
               "ET",
               "BT",
               "200 632.8000000000002 Td",
               "() Tj",
               "ET",
               "BT",
               "200 632.8000000000002 Td",
               "/F1 14 Tf",
               "16.8 TL",
               _left_again,
               "ET"
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
    assert [
             "BT",
             "0 700 Td",
             "/F1 10 Tf",
             "12.0 TL",
             "(a) Tj",
             "(b) '",
             "ET"
           ] =
             new(fonts: @fonts_helvetica)
             |> page(size: :letter)
             |> font(:helvetica, size: 10)
             |> text_position(0, 700)
             |> text("""
             a
             b\
             """)
             |> operations()
  end

  test "CID font linebreaks are converted to the ' operator" do
    assert [
             "<00A5> Tj",
             "<00B4> '"
             | _
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
             |> Enum.take(-3)
  end

  test "font is assigned to the operator struct when font descendant present" do
    {_doc, content_stream} =
      new(fonts: %{bodoni: [file: bodoni()]})
      |> page(size: :letter)
      |> font(:bodoni, size: 24)
      |> text_position(0, 700)
      |> text("CO₂")

    [_et, show_text_operation | _] = content_stream.value.operations

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
      assert ["<001100550174> Tj" | _] =
               new(fonts: %{bodoni: [file: bodoni()]})
               |> page()
               |> font(:bodoni, size: 24)
               |> text_position(0, 700)
               |> text("CO₂")
               |> operations()
               |> Enum.take(-2)
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
