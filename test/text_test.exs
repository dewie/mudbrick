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
        |> text(text, font: :helvetica, font_size: 10)

      {_doc, uncompressed_content_stream} =
        new(compress: false, fonts: @fonts_helvetica)
        |> page()
        |> text(text, font: :helvetica, font_size: 10)

      assert IO.iodata_length(Mudbrick.Object.from(compressed_content_stream)) <
               IO.iodata_length(Mudbrick.Object.from(uncompressed_content_stream))
    end
  end

  test "can set leading" do
    assert [
             "BT",
             "/F1 10 Tf",
             "14 TL",
             "0 0 Td",
             "0 0 0 rg",
             "(hello there) Tj",
             "ET"
           ] =
             new(fonts: @fonts_helvetica)
             |> page()
             |> text(
               "hello there",
               font: :helvetica,
               font_size: 10,
               leading: 14
             )
             |> operations()
  end

  describe "colour" do
    property "it's an error to set a colour above 1" do
      check all colour <- invalid_colour() do
        e =
          assert_raise(Mudbrick.ContentStream.InvalidColour, fn ->
            new(fonts: %{my_bodoni: [file: Mudbrick.TestHelper.bodoni_regular()]})
            |> page()
            |> text({"hi there", colour: colour}, font: :my_bodoni)
          end)

        assert e.message == "tuple must be made of floats or integers between 0 and 1"
      end
    end

    test "can be set on a piece of text" do
      {_doc, content_stream} =
        new(fonts: @fonts_helvetica)
        |> page()
        |> text(
          [
            "black and ",
            {"""
             red
             text\
             """, colour: {1.0, 0.0, 0.0}}
          ],
          font: :helvetica,
          font_size: 10
        )

      assert show(content_stream) =~
               """
               BT
               /F1 10 Tf
               12.0 TL
               0 0 Td
               0 0 0 rg
               (black and ) Tj
               1.0 0.0 0.0 rg
               (red) Tj
               (text) '
               ET
               """
    end
  end

  test "right-alignment is unsupported for built-in fonts right now" do
    assert_raise(Font.NotMeasured, fn ->
      new(fonts: @fonts_helvetica)
      |> page(size: :letter)
      |> text("hi", font: :helvetica, font_size: 10, align: :right)
    end)
  end

  test "built-in font linebreaks are converted to the ' operator" do
    assert [
             "BT",
             "/F1 10 Tf",
             "12.0 TL",
             "0 700 Td",
             "0 0 0 rg",
             "(a) Tj",
             "(b) '",
             "ET"
           ] =
             new(fonts: @fonts_helvetica)
             |> page(size: :letter)
             |> text(
               """
               a
               b\
               """,
               font: :helvetica,
               font_size: 10,
               position: {0, 700}
             )
             |> operations()
  end

  test "CID font linebreaks are converted to the ' operator" do
    assert [
             "<00A5> Tj",
             "<00B4> '"
             | _
           ] =
             new(fonts: %{bodoni: [file: bodoni_regular()]})
             |> page(size: :letter)
             |> text(
               """
               a
               b\
               """,
               font: :bodoni,
               font_size: 10,
               position: {0, 700}
             )
             |> operations()
             |> Enum.take(-3)
  end

  test "font is assigned to the operator struct when font descendant present" do
    {_doc, content_stream} =
      new(fonts: %{bodoni: [file: bodoni_regular()]})
      |> page(size: :letter)
      |> text("CO₂", font: :bodoni, font_size: 24, position: {0, 700})

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
               new(fonts: %{bodoni: [file: bodoni_regular()]})
               |> page()
               |> text("CO₂", font: :bodoni, font_size: 24, position: {0, 700})
               |> operations()
               |> Enum.take(-2)
    end

    test "copes with trailing newlines in CID font text" do
      assert new(fonts: %{bodoni: [file: bodoni_regular()]})
             |> page()
             |> text("\n", font: :bodoni, font_size: 13)
             |> render()
    end
  end
end
