defmodule Mudbrick.TextTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Mudbrick
  import Mudbrick.TestHelper

  alias Mudbrick.ContentStream.Tj
  alias Mudbrick.Font
  alias Mudbrick.Indirect

  test "with more than one registered font, it's an error not to choose one" do
    chain =
      new(
        compress: false,
        fonts: %{regular: bodoni_regular(), bold: bodoni_bold()}
      )
      |> page()

    assert_raise Font.MustBeChosen, fn ->
      text(chain, {"CO₂ ", colour: {1, 0, 0}},
        font_size: 14,
        align: :right,
        position: {200, 700}
      )
    end
  end

  test "parts inherit fonts" do
    assert [
             "/F1 14 Tf",
             "16.8 TL",
             "BT",
             "171.65 700.0 Td",
             "1 0 0 rg",
             "<00110055017401B7> Tj",
             "ET"
           ] =
             new(
               compress: false,
               fonts: %{bodoni: bodoni_regular()}
             )
             |> page()
             |> text({"CO₂ ", colour: {1, 0, 0}},
               font_size: 14,
               align: :right,
               position: {200, 700}
             )
             |> operations()
  end

  describe "with compression enabled" do
    test "compresses text stream" do
      text = "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW"

      {_doc, compressed_content_stream} =
        new(fonts: %{bodoni: bodoni_regular()}, compress: true)
        |> page()
        |> text(text, font_size: 10)

      {_doc, uncompressed_content_stream} =
        new(fonts: %{bodoni: bodoni_regular()}, compress: false)
        |> page()
        |> text(text, font_size: 10)

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
             "<00D500C000ED00ED00FC01B7011D00D500C0010F00C0> Tj",
             "ET"
           ] =
             new(fonts: %{bodoni: bodoni_regular()})
             |> page()
             |> text(
               "hello there",
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
            new(fonts: %{my_bodoni: Mudbrick.TestHelper.bodoni_regular()})
            |> page()
            |> text({"hi there", colour: colour})
          end)

        assert e.message == "tuple must be made of floats or integers between 0 and 1"
      end
    end

    test "can be set on a text block" do
      {_doc, content_stream} =
        new(fonts: %{bodoni: bodoni_regular()})
        |> page()
        |> text(
          [
            "this is all ",
            """
            red
            text\
            """
          ],
          font_size: 10,
          colour: {1.0, 0.0, 0.0}
        )

      assert show(content_stream) =~
               """
               BT
               /F1 10 Tf
               12.0 TL
               0 0 Td
               1.0 0.0 0.0 rg
               <011D00D500D9011601B700D9011601B700A500ED00ED01B7> Tj
               <010F00C000BB> Tj
               <011D00C0013D011D> '
               ET
               """
    end

    test "can be set on part of a text block" do
      {_doc, content_stream} =
        new(fonts: %{bodoni: bodoni_regular()})
        |> page()
        |> text(
          [
            "black and ",
            {"""
             red
             text\
             """, colour: {1.0, 0.0, 0.0}}
          ],
          font_size: 10
        )

      assert show(content_stream) =~
               """
               BT
               /F1 10 Tf
               12.0 TL
               0 0 Td
               0 0 0 rg
               <00B400ED00A500B500EA01B700A500F400BB01B7> Tj
               1.0 0.0 0.0 rg
               <010F00C000BB> Tj
               <011D00C0013D011D> '
               ET
               """
    end
  end

  test "CID font linebreaks are converted to the ' operator" do
    assert [
             "<00A5> Tj",
             "<00B4> '"
             | _
           ] =
             new(fonts: %{bodoni: bodoni_regular()})
             |> page(size: :letter)
             |> text(
               """
               a
               b\
               """,
               font_size: 10,
               position: {0, 700}
             )
             |> operations()
             |> Enum.take(-3)
  end

  test "font is assigned to the operator struct when font descendant present" do
    {_doc, content_stream} =
      new(fonts: %{bodoni: bodoni_regular()})
      |> page(size: :letter)
      |> text("CO₂", font_size: 24, position: {0, 700})

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
               new(fonts: %{bodoni: bodoni_regular()})
               |> page()
               |> text("CO₂", font_size: 24, position: {0, 700})
               |> operations()
               |> Enum.take(-2)
    end

    test "copes with trailing newlines in CID font text" do
      assert new(fonts: %{bodoni: bodoni_regular()})
             |> page()
             |> text("\n", font_size: 13)
             |> render()
    end
  end
end
