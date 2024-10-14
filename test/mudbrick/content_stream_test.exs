defmodule Mudbrick.ContentStreamTest do
  use ExUnit.Case, async: true

  import Mudbrick

  alias Mudbrick.ContentStream
  alias Mudbrick.Font
  alias Mudbrick.Indirect
  alias Mudbrick.Object

  @font_data System.fetch_env!("FONT_LIBRE_BODONI_REGULAR") |> File.read!()

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

    assert %ContentStream.Tj{
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
