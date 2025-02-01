defmodule Mudbrick.ParseTextContentTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Mudbrick
  import Mudbrick.TestHelper

  alias Mudbrick.Parser

  setup do
    doc =
      new(fonts: %{bodoni: bodoni_regular(), franklin: franklin_regular()})
      |> page()
      |> text(
        {
          "hello, world!",
          underline: [width: 1]
        },
        font: :bodoni
      )
      |> text("hello in another font", font: :franklin)
      |> Mudbrick.Document.finish()

    obj = Enum.find(doc.objects, &(%Mudbrick.ContentStream{} = &1.value))

    [
      {:dictionary, [pair: [name: "Length", integer: [_]]]},
      "stream",
      stream
    ] =
      obj.value
      |> Mudbrick.Object.to_iodata()
      |> IO.iodata_to_binary()
      |> Parser.parse(:stream)

    %{stream: stream}
  end

  test "can parse a text block with negative kerns" do
    raw =
      """
      BT
      [ <00F3> -32 <0010> ] TJ
      ET
      """

    assert Parser.parse(raw, :content_blocks) == [
             text_block: [
               BT: [],
               TJ: [glyph_id: "00F3", offset: {:integer, ["-", "32"]}, glyph_id: "0010"],
               ET: []
             ]
           ]
  end

  test "can turn text content to Mudbrick", %{stream: stream} do
    assert %Mudbrick.ContentStream{
             compress: false,
             operations: [
               %Mudbrick.ContentStream.ET{},
               %Mudbrick.ContentStream.TJ{
                 auto_kern: true,
                 kerned_text: _
               },
               %Mudbrick.ContentStream.Rg{stroking: false, r: 0, g: 0, b: 0},
               %Mudbrick.ContentStream.TL{leading: 14.399999999999999},
               %Mudbrick.ContentStream.Tf{font_identifier: :F2, size: "12"},
               %Mudbrick.ContentStream.BT{},
               %Mudbrick.ContentStream.ET{},
               %Mudbrick.ContentStream.TJ{
                 auto_kern: true,
                 kerned_text: _
               },
               %Mudbrick.ContentStream.Rg{stroking: false, r: 0, g: 0, b: 0},
               %Mudbrick.ContentStream.TL{leading: 14.399999999999999},
               %Mudbrick.ContentStream.Tf{font_identifier: :F1, size: "12"},
               %Mudbrick.ContentStream.BT{},
               %Mudbrick.ContentStream.QPop{},
               %Mudbrick.ContentStream.S{},
               %Mudbrick.ContentStream.L{coords: {65.46, -1.2}},
               %Mudbrick.ContentStream.W{width: 1},
               %Mudbrick.ContentStream.Rg{stroking: true, r: 0, g: 0, b: 0},
               %Mudbrick.ContentStream.M{coords: {+0.0, -1.2}},
               %Mudbrick.ContentStream.QPush{}
             ],
             page: nil
           } = Parser.to_mudbrick(stream, :content_blocks)
  end

  test "can parse text content to AST", %{stream: stream} do
    assert [
             {:graphics_block,
              [
                q: [],
                m: [real: ["0", ".", "0"], real: ["-", "1", ".", "2"]],
                RG: [integer: ["0"], integer: ["0"], integer: ["0"]],
                w: [integer: ["1"]],
                l: [real: ["65", ".", "46"], real: ["-", "1", ".", "2"]],
                S: [],
                Q: []
              ]},
             {:text_block,
              [
                BT: [],
                Tf: ["1", "12"],
                TL: [real: ["14", ".", "399999999999999"]],
                rg: [integer: ["0"], integer: ["0"], integer: ["0"]],
                TJ: [
                  glyph_id: "00D5",
                  offset: {:integer, ["24"]},
                  glyph_id: "00C0",
                  glyph_id: "00ED",
                  glyph_id: "00ED",
                  glyph_id: "00FC",
                  glyph_id: "0195",
                  glyph_id: "01B7",
                  glyph_id: "0138",
                  glyph_id: "00FC",
                  glyph_id: "010F",
                  offset: {:integer, ["12"]},
                  glyph_id: "00ED",
                  glyph_id: "00BB",
                  glyph_id: "0197"
                ],
                ET: []
              ]},
             {:text_block,
              [
                BT: [],
                Tf: ["2", "12"],
                TL: [real: ["14", ".", "399999999999999"]],
                rg: [integer: ["0"], integer: ["0"], integer: ["0"]],
                TJ: [
                  glyph_id: "0105",
                  offset: {:integer, ["44"]},
                  glyph_id: "00EA",
                  glyph_id: "011E",
                  glyph_id: "011E",
                  glyph_id: "012C",
                  glyph_id: "01F0",
                  glyph_id: "0109",
                  glyph_id: "0125",
                  glyph_id: "01F0",
                  glyph_id: "00C3",
                  glyph_id: "0125",
                  glyph_id: "012C",
                  offset: {:integer, ["35"]},
                  glyph_id: "015A",
                  offset: {:integer, ["13"]},
                  glyph_id: "0105",
                  offset: {:integer, ["13"]},
                  glyph_id: "00EA",
                  offset: {:integer, ["63"]},
                  glyph_id: "014B",
                  glyph_id: "01F0",
                  offset: {:integer, ["13"]},
                  glyph_id: "00FF",
                  glyph_id: "012C",
                  glyph_id: "0125",
                  glyph_id: "015A"
                ],
                ET: []
              ]}
           ] =
             stream
             |> Parser.parse(:content_blocks)
  end
end
