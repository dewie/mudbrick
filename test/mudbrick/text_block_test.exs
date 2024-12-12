defmodule Mudbrick.TextBlockTest do
  use ExUnit.Case, async: true

  import Mudbrick.TestHelper, only: [bodoni_regular: 0]

  alias Mudbrick.Font
  alias Mudbrick.TextBlock
  alias Mudbrick.TextBlock.Line
  alias Mudbrick.TextBlock.Line.Part

  @font (Mudbrick.new(fonts: %{bodoni: bodoni_regular()})
         |> Mudbrick.Document.find_object(&match?(%Font{}, &1))).value

  test "single write is divided into lines" do
    block =
      TextBlock.new(
        font: @font,
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
                   font_size: 10,
                   text: "first"
                 }
               ]
             }
           ] = block.lines
  end

  test "offsets from left get set" do
    block =
      TextBlock.new(
        colour: {0, 0, 1},
        font: @font,
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
             [{"line", {25.38, -28.0}}, {"third ", {0.0, -28.0}}],
             [{"second line", {0.0, -14.0}}],
             [{"line", {20.31, 0.0}}, {"first ", {0.0, 0.0}}]
           ]
  end

  test "writes get divided into lines and parts" do
    block =
      TextBlock.new(
        colour: {0, 0, 1},
        font: @font,
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
                 %Part{colour: {0, 1, 0}, font_size: 24, text: "fourth"}
               ]
             },
             %Line{
               leading: 16,
               parts: [
                 %Part{colour: {0, 0, 1}, font_size: 10, text: "line"},
                 %Part{colour: {0, 0, 1}, font_size: 10, text: "third "}
               ]
             },
             %Line{
               leading: 14,
               parts: [%Part{colour: {0, 0, 1}, font_size: 10, text: "second line"}]
             },
             %Line{
               leading: 14,
               parts: [
                 %Part{colour: {0, 0, 1}, font_size: 10, text: "line"},
                 %Part{colour: {1, 0, 0}, font_size: 10, text: "first "}
               ]
             }
           ] = block.lines
  end

  describe "underline" do
    test "can be set on a single line" do
      block =
        TextBlock.new(
          font: @font,
          font_size: 10,
          position: {400, 500}
        )
        |> TextBlock.write("this is ")
        |> TextBlock.write("underlined", underline: [width: 1])

      assert [
               %Line{
                 leading: 12.0,
                 parts: [
                   %Part{
                     colour: {0, 0, 0},
                     font_size: 10,
                     text: "underlined",
                     underline: [width: 1]
                   },
                   %Part{colour: {0, 0, 0}, font_size: 10, text: "this is "}
                 ]
               }
             ] = block.lines
    end

    test "length of line is different when kerned" do
      line = fn opts ->
        output(fn %{fonts: fonts} ->
          TextBlock.new(Keyword.merge(opts, font: fonts.regular))
          |> TextBlock.write("underlined", underline: [width: 1])
        end)
        |> operations()
        |> Enum.find(fn op -> String.ends_with?(op, " l") end)
      end

      line_with_kerning = line.(auto_kern: true)
      line_without_kerning = line.(auto_kern: false)

      assert line_with_kerning != line_without_kerning
    end
  end

  describe "leading" do
    test "is set correctly for lines composed with writes" do
      output(fn %{fonts: fonts} ->
        heading_leading = 70
        overlap_leading = 20
        # 120% of default 80 font size
        expected_final_leading = 96.0

        text_block =
          TextBlock.new(
            align: :left,
            font: fonts.regular,
            font_size: 80,
            position: {0, 500}
          )
          |> TextBlock.write("Warning!\n", font_size: 140, leading: heading_leading)
          |> TextBlock.write("Leading ", leading: overlap_leading)
          |> TextBlock.write("changes")
          |> TextBlock.write("\nthis overlaps")

        assert [
                 ^expected_final_leading,
                 ^overlap_leading,
                 ^heading_leading
               ] =
                 Enum.map(text_block.lines, & &1.leading)

        text_block
      end)
    end

    test "is set correctly for linebreaks inside writes" do
      output(fn %{fonts: fonts} ->
        text_block =
          TextBlock.new(
            align: :left,
            font: fonts.regular,
            font_size: 80,
            position: {0, 500}
          )
          |> TextBlock.write("Warning!\n", font_size: 140, leading: 20)
          |> TextBlock.write("Steps under\nconstruction", leading: 70)

        assert [70, 70, 20] = Enum.map(text_block.lines, & &1.leading)

        text_block
      end)
    end

    test "can be set per line" do
      block =
        TextBlock.new(font: @font, font_size: 10)
        |> TextBlock.write("this is 14\n", leading: 14)
        |> TextBlock.write("this is 12")

      assert [
               %Line{leading: 12.0},
               %Line{leading: 14}
             ] = block.lines
    end
  end

  describe "left-aligned" do
    test "newlines are T*s without text" do
      assert [
               "BT",
               "/F1 10 Tf",
               "14 TL",
               "400 500 Td",
               "0 0 0 rg",
               "[ <014C> <010F> 12 <0116> <011D> <01B7> <00ED> <00D9> <00F4> 8 <00C0> ] TJ",
               "T*",
               "",
               "T*",
               "[ <0116> 24 <00C0> <00B5> <00FC> <00F4> <00BB> <01B7> <00ED> <00D9> <00F4> 8 <00C0> ] TJ",
               "T*",
               "",
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

    test "inline colours are written with rgs" do
      assert [
               "BT",
               "/F1 10 Tf",
               "12.0 TL",
               "400 500 Td",
               "0 0 0 rg",
               _,
               "1 0 0 rg",
               _,
               "T*",
               "0 1 0 rg",
               _,
               "T*",
               _,
               "0 0 1 rg",
               _,
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
               _,
               "/F1 10 Tf",
               "/F2 10 Tf",
               _,
               "/F1 10 Tf",
               _,
               "/F3 10 Tf",
               _,
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

    test "inline leading is written with TL, before T* that changes matrix" do
      assert [
               "BT",
               "/F1 10 Tf",
               "12.0 TL",
               "400 500 Td",
               "0 0 0 rg",
               "[ <011D> -12 <00D5> <00D9> <0116> <01B7> <00D9> <0116> <01B7> <0155> 40 <0158> ] TJ",
               "14 TL",
               "T*",
               "[ <011D> -12 <00D5> <00D9> <0116> <01B7> <00D9> <0116> <01B7> <0155> -20 <0156> ] TJ",
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

    test "underlines happen" do
      assert [
               "q",
               "0.0 470.0 m",
               "0 0 0 RG",
               "1 w",
               "91.344 470.0 l",
               "S",
               "Q",
               "q",
               "0.0 498.8 m",
               "1 0 0 RG",
               "0.6 w",
               "61.967999999999996 498.8 l",
               "S",
               "Q",
               "BT"
               | _
             ] =
               output(fn %{fonts: fonts} ->
                 TextBlock.new(font: fonts.regular, position: {0, 500})
                 |> TextBlock.write("underlined ", underline: [width: 0.6, colour: {1, 0, 0}])
                 |> TextBlock.write("\nnot underlined ")
                 |> TextBlock.write("\nunderlined again", underline: [width: 1])
               end)
               |> operations()
    end
  end

  describe "right-aligned" do
    test "newlines become T*s with offsets in Tds" do
      assert [
               "BT",
               "/F1 10 Tf",
               "12.0 TL",
               "400 500 Td",
               "-15.38 0 Td",
               "0 0 0 rg",
               "[ <00A5> ] TJ",
               "1 0 0 rg",
               "[ <00A5> -20 <00A5> ] TJ",
               "15.38 0 Td",
               "-20.14 0 Td",
               "T*",
               "0 0 0 rg",
               "[ <0138> 44 <0138> <0138> ] TJ",
               "20.14 0 Td",
               "-83.38000000000001 0 Td",
               "T*",
               "[ <0088> 48 <0055> <0088> ] TJ",
               "0 1 0 rg",
               "[ <0088> 48 <0055> <0088> 68 <0055> <0088> 68 <0055> <0088> ] TJ",
               "83.38000000000001 0 Td",
               "-0.0 0 Td",
               "T*",
               "",
               "0.0 0 Td",
               "-9.26 0 Td",
               "T*",
               "0 0 0 rg",
               "[ <00D5> <00D9> ] TJ",
               "9.26 0 Td",
               "ET"
             ] =
               output(fn %{fonts: fonts} ->
                 TextBlock.new(
                   font: fonts.regular,
                   font_size: 10,
                   position: {400, 500},
                   align: :right
                 )
                 |> TextBlock.write("a")
                 |> TextBlock.write(
                   """
                   aa
                   """,
                   colour: {1, 0, 0}
                 )
                 |> TextBlock.write("""
                 www
                 WOW\
                 """)
                 |> TextBlock.write(
                   """
                   WOWOWOW
                   """,
                   colour: {0, 1, 0}
                 )
                 |> TextBlock.write("""

                 hi\
                 """)
               end)
               |> operations()
    end

    test "inline font change is written with Tfs" do
      assert [
               "BT",
               "/F1 10 Tf",
               "12.0 TL",
               "400 500 Td",
               _,
               "0 0 0 rg",
               _,
               "/F2 10 Tf",
               _,
               "/F1 10 Tf",
               _,
               "/F3 10 Tf",
               _,
               "/F1 10 Tf",
               _,
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

    test "underlines are correctly aligned" do
      assert [
               "q",
               "-173.59199999999998 498.8 m",
               "0 0 0 RG",
               "1 w",
               "-111.624 498.8 l",
               "S",
               "Q"
               | _
             ] =
               output(fn %{fonts: fonts} ->
                 TextBlock.new(font: fonts.regular, position: {0, 500}, align: :right)
                 |> TextBlock.write("not underlined ")
                 |> TextBlock.write("underlined ", underline: [width: 1])
                 |> TextBlock.write("not underlined again")
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

  describe "centre-aligned" do
    test "offset of a line is half the right-aligned offset" do
      text = "aaaa"
      size = 12
      right_td = first_td(:right, text, size)
      centre_td = first_td(:centre, text, size)

      assert centre_td.tx == right_td.tx / 2
    end
  end

  defp first_td(align, text, size) do
    output(fn %{fonts: fonts} ->
      TextBlock.new(align: align, font: fonts.regular, font_size: size)
      |> TextBlock.write(text)
    end)
    |> Enum.find(&match?(%Mudbrick.ContentStream.Td{}, &1))
  end

  defp output(f) do
    Mudbrick.TestHelper.wrapped_output(f, TextBlock.Output) |> Enum.reverse()
  end

  defp operations(ops) do
    Enum.map(ops, &Mudbrick.TestHelper.show/1)
  end
end
