defmodule Mudbrick.ContentStreamTest do
  use ExUnit.Case, async: true

  import Mudbrick

  alias Mudbrick.ContentStream.Tj
  alias Mudbrick.Font
  alias Mudbrick.Indirect
  alias Mudbrick.Object

  @font_data System.fetch_env!("FONT_LIBRE_BODONI_REGULAR") |> File.read!()

  test "linebreaks are converted to the ' operator" do
    {_doc, content_stream} =
      new()
      |> page(
        size: :letter,
        fonts: %{bodoni: [file: @font_data]}
      )
      |> contents()
      |> font(:bodoni, size: 10)
      |> text_position(0, 700)
      |> text("""
      a
      b\
      """)

    [apostrophe, tj, leading | _] = content_stream.value.operations

    assert Object.from(leading) |> to_string() == "12.0 TL"
    assert Object.from(tj) |> to_string() == "<00A5> Tj"
    assert Object.from(apostrophe) |> to_string() == "<00B4> '"
  end

  test "font is assigned to the operator struct when font descendant present" do
    {_doc, content_stream} =
      new()
      |> page(
        size: :letter,
        fonts: %{bodoni: [file: @font_data]}
      )
      |> contents()
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
          fonts: %{bodoni: [file: @font_data]}
        )
        |> contents()
        |> font(:bodoni, size: 24)
        |> text_position(0, 700)
        |> text("CO₂")

      [show_text_operation | _] = content_stream.value.operations

      assert Object.from(show_text_operation) |> to_string() == """
             <001100550174> Tj\
             """
    end
  end
end
