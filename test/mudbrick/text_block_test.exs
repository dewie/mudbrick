defmodule Mudbrick.TextBlockTest do
  use ExUnit.Case, async: true

  import Mudbrick.TestHelper, only: [output: 2, bodoni_regular: 0]

  alias Mudbrick.Font
  alias Mudbrick.TextBlock
  alias Mudbrick.TextBlock.Line
  alias Mudbrick.TextBlock.Line.Part

  test "single write is divided into lines" do
    block =
      TextBlock.new(
        font_size: 10,
        position: {400, 500}
      )
      |> TextBlock.write("first\nsecond\nthird", colour: {0, 0, 0})

    assert [
             %Line{
               leading: 12.0,
               parts: [
                 %Part{
                   colour: {0, 0, 0},
                   font: nil,
                   font_size: 10,
                   text: "third"
                 }
               ]
             },
             %Line{
               leading: 12.0,
               parts: [
                 %Part{
                   colour: {0, 0, 0},
                   font: nil,
                   font_size: 10,
                   text: "second"
                 }
               ]
             },
             %Line{
               leading: 12.0,
               parts: [
                 %Part{
                   colour: {0, 0, 0},
                   font: nil,
                   font_size: 10,
                   text: "first"
                 }
               ]
             }
           ] = block.lines
  end

  test "offsets from left get set" do
    font =
      (Mudbrick.new(fonts: %{bodoni: [file: bodoni_regular()]})
       |> Mudbrick.Document.find_object(&match?(%Font{}, &1))).value

    block =
      TextBlock.new(
        colour: {0, 0, 1},
        font: font,
        font_size: 10,
        position: {400, 500},
        leading: 14
      )
      |> TextBlock.write("first ", colour: {1, 0, 0})
      |> TextBlock.write("""
      line
      second line
      """)
      |> TextBlock.write("third ", leading: 16)
      |> TextBlock.write("line")
      |> TextBlock.write("\nfourth", colour: {0, 1, 0}, font_size: 24)

    part_offsets =
      for line <- block.lines do
        for part <- line.parts do
          {part.text, part.left_offset}
        end
      end

    assert part_offsets == [
             [{"fourth", {0.0, -44.0}}],
             [{"line", {24.86, -28.0}}, {"third ", {0.0, -28.0}}],
             [{"second line", {0.0, -14.0}}],
             [{"line", {20.429999999999996, 0.0}}, {"first ", {0.0, 0.0}}]
           ]
  end

  test "writes get divided into lines and parts" do
    block =
      TextBlock.new(
        colour: {0, 0, 1},
        font_size: 10,
        position: {400, 500},
        leading: 14
      )
      |> TextBlock.write("first ", colour: {1, 0, 0})
      |> TextBlock.write("""
      line
      second line
      """)
      |> TextBlock.write("third ", leading: 16)
      |> TextBlock.write("line")
      |> TextBlock.write("\nfourth", colour: {0, 1, 0}, font_size: 24)

    assert [
             %Line{
               leading: 14,
               parts: [
                 %Part{colour: {0, 1, 0}, font: nil, font_size: 24, text: "fourth"}
               ]
             },
             %Line{
               leading: 16,
               parts: [
                 %Part{colour: {0, 0, 1}, font: nil, font_size: 10, text: "line"},
                 %Part{colour: {0, 0, 1}, font: nil, font_size: 10, text: "third "}
               ]
             },
             %Line{
               leading: 14,
               parts: [%Part{colour: {0, 0, 1}, font: nil, font_size: 10, text: "second line"}]
             },
             %Line{
               leading: 14,
               parts: [
                 %Part{colour: {0, 0, 1}, font: nil, font_size: 10, text: "line"},
                 %Part{colour: {1, 0, 0}, font: nil, font_size: 10, text: "first "}
               ]
             }
           ] = block.lines
  end

  describe "leading" do
    test "can be set per line" do
      block =
        TextBlock.new(font_size: 10)
        |> TextBlock.write("this is 14\n", leading: 14)
        |> TextBlock.write("this is 12")

      assert [
               %Line{leading: 12.0},
               %Line{leading: 14}
             ] = block.lines
    end
  end

  describe "left-aligned" do
    test "newlines become apostrophes" do
      assert [
               "BT",
               "/F1 10 Tf",
               "14 TL",
               "400 500 Td",
               "0 0 0 rg",
               "<014C010F0116011D01B700ED00D900F400C0> Tj",
               "() '",
               "<011600C000B500FC00F400BB01B700ED00D900F400C0> '",
               "() '",
               "ET"
             ] =
               output(fn %{fonts: fonts} ->
                 TextBlock.new(
                   font: fonts.regular,
                   font_size: 10,
                   position: {400, 500},
                   leading: 14
                 )
                 |> TextBlock.write("""
                 first line

                 second line
                 """)
               end)
               |> operations()
    end

    test "inline colours are written with Tjs" do
      assert [
               "BT",
               "/F1 10 Tf",
               "12.0 TL",
               "400 500 Td",
               "0 0 0 rg",
               "<00A5> Tj",
               "1 0 0 rg",
               "<00B4> Tj",
               "0 1 0 rg",
               "<00B5> '",
               "<00BB> '",
               "0 0 1 rg",
               "<00C0> Tj",
               "ET"
             ] =
               output(fn %{fonts: fonts} ->
                 TextBlock.new(
                   font: fonts.regular,
                   font_size: 10,
                   position: {400, 500}
                 )
                 |> TextBlock.write("a")
                 |> TextBlock.write("b", colour: {1, 0, 0})
                 |> TextBlock.write("\nc\nd", colour: {0, 1, 0})
                 |> TextBlock.write("e", colour: {0, 0, 1})
               end)
               |> operations()
    end

    test "inline font change is written with Tfs" do
      assert [
               "BT",
               "/F1 10 Tf",
               "12.0 TL",
               "400 500 Td",
               "0 0 0 rg",
               "/F1 14 Tf",
               "<011D00D500D9011601B700D9011601B7> Tj",
               "/F1 10 Tf",
               "/F2 10 Tf",
               "<00B400FC00ED00BB01B7> Tj",
               "/F1 10 Tf",
               "<00B40121011D01B7011D00D500D9011601B700D9011600F4019E011D01B7> Tj",
               "/F3 10 Tf",
               "<015A01050109015201F00109015201F000FF014B00C30125011B011E01090125> Tj",
               "/F1 10 Tf",
               "ET"
             ] =
               output(fn %{fonts: fonts} ->
                 TextBlock.new(
                   font: fonts.regular,
                   font_size: 10,
                   position: {400, 500}
                 )
                 |> TextBlock.write("this is ", font_size: 14)
                 |> TextBlock.write("bold ", font: fonts.bold)
                 |> TextBlock.write("but this isn't ")
                 |> TextBlock.write("this is franklin", font: fonts.franklin_regular)
               end)
               |> operations()
    end

    test "inline leading is written with TL, before ' that changes matrix" do
      assert [
               "BT",
               "/F1 10 Tf",
               "12.0 TL",
               "400 500 Td",
               "0 0 0 rg",
               "<011D00D500D9011601B700D9011601B701550158> Tj",
               "14 TL",
               "<011D00D500D9011601B700D9011601B701550156> '",
               "12.0 TL",
               "ET"
             ] =
               output(fn %{fonts: fonts} ->
                 TextBlock.new(
                   font: fonts.regular,
                   font_size: 10,
                   position: {400, 500}
                 )
                 |> TextBlock.write("this is 14\n", leading: 14)
                 |> TextBlock.write("this is 12")
               end)
               |> operations()
    end
  end

  describe "right-aligned" do
    test "newlines become Tjs with offsets" do
      assert [
               "/F1 10 Tf",
               "12.0 TL",
               "BT",
               "384.82 500.0 Td",
               "0 0 0 rg",
               "<00A5> Tj",
               "1 0 0 rg",
               "<00A500A5> Tj",
               "ET",
               "BT",
               "379.42 488.0 Td",
               "0 0 0 rg",
               "<013801380138> Tj",
               "ET",
               "BT",
               "314.3 476.0 Td",
               "<008800550088> Tj",
               "0 1 0 rg",
               "<0088005500880055008800550088> Tj",
               "ET",
               "BT",
               "400.0 464.0 Td",
               "ET",
               "BT",
               "390.74 452.0 Td",
               "0 0 0 rg",
               "<00D500D9> Tj",
               "ET"
             ] =
               output(fn %{fonts: fonts} ->
                 Mudbrick.TextBlock.new(
                   font: fonts.regular,
                   font_size: 10,
                   position: {400, 500},
                   align: :right
                 )
                 |> Mudbrick.TextBlock.write("a")
                 |> Mudbrick.TextBlock.write(
                   """
                   aa
                   """,
                   colour: {1, 0, 0}
                 )
                 |> Mudbrick.TextBlock.write("""
                 www
                 WOW\
                 """)
                 |> Mudbrick.TextBlock.write(
                   """
                   WOWOWOW
                   """,
                   colour: {0, 1, 0}
                 )
                 |> Mudbrick.TextBlock.write("""

                 hi\
                 """)
               end)
               |> operations()
    end

    test "inline font change is written with Tfs" do
      assert [
               "/F1 10 Tf",
               "12.0 TL",
               "BT",
               "225.67999999999998 500.0 Td",
               "0 0 0 rg",
               "<011D00D500D9011601B700D9011601B7> Tj",
               "/F2 10 Tf",
               "<00B400FC00ED00BB01B7> Tj",
               "/F1 10 Tf",
               "<00B40121011D01B7011D00D500D9011601B700D9011600F4019E011D01B7> Tj",
               "/F3 10 Tf",
               "<015A01050109015201F00109015201F000FF014B00C30125011B011E01090125> Tj",
               "/F1 10 Tf",
               "ET"
             ] =
               output(fn %{fonts: fonts} ->
                 TextBlock.new(
                   font: fonts.regular,
                   font_size: 10,
                   position: {400, 500},
                   align: :right
                 )
                 |> TextBlock.write("this is ")
                 |> TextBlock.write("bold ", font: fonts.bold)
                 |> TextBlock.write("but this isn't ")
                 |> TextBlock.write("this is franklin", font: fonts.franklin_regular)
               end)
               |> operations()
    end

    test "inline font sizes affect alignment offset of whole line" do
      assert offset_with_partial_font_size(50) < offset_with_partial_font_size(12)
    end

    defp offset_with_partial_font_size(font_size) do
      operations =
        output(fn %{fonts: fonts} ->
          TextBlock.new(font: fonts.regular, align: :right)
          |> TextBlock.write("this is ")
          |> TextBlock.write("one line", font_size: font_size)
        end)
        |> operations()

      [offset, _y_offset, _operator] =
        operations |> Enum.find(&String.ends_with?(&1, "Td")) |> String.split(" ")

      {offset, ""} = Float.parse(offset)

      offset
    end
  end

  defp output(f), do: output(f, Mudbrick.TextBlock.Output)

  defp operations(ops) do
    Enum.map(ops, &Mudbrick.TestHelper.show/1)
  end
end
