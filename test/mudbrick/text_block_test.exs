defmodule Mudbrick.TextBlockTest do
  use ExUnit.Case, async: true

  import Mudbrick.TestHelper,
    only: [
      bodoni_regular: 0,
      bodoni_bold: 0,
      franklin_regular: 0
    ]

  alias Mudbrick.Page
  alias Mudbrick.TextBlock
  alias Mudbrick.TextBlock.Line
  alias Mudbrick.TextBlock.Line.Part
  alias Mudbrick.TextBlock.Output

  test "single write is divided into lines" do
    block =
      TextBlock.new(
        font_size: 10,
        position: {400, 500}
      )
      |> TextBlock.write("first\nsecond\nthird", colour: {0, 0, 0})

    assert block.lines == [
             %Line{parts: [%Part{text: "third"}]},
             %Line{parts: [%Part{text: "second"}]},
             %Line{parts: [%Part{text: "first"}]}
           ]
  end

  test "writes get divided into lines and parts" do
    block =
      TextBlock.new(
        font_size: 10,
        position: {400, 500}
      )
      |> TextBlock.write("first ", colour: {1, 0, 0})
      |> TextBlock.write("""
      line
      second line
      """)
      |> TextBlock.write("third ")
      |> TextBlock.write("line")
      |> TextBlock.write("\nfourth", colour: {0, 1, 0}, font_size: 24)

    assert block.lines == [
             %Line{parts: [%Part{text: "fourth", colour: {0, 1, 0}, font_size: 24}]},
             %Line{parts: [%Part{text: "line"}, %Part{text: "third "}]},
             %Line{parts: [%Part{text: "second line"}]},
             %Line{parts: [%Part{text: "line"}, %Part{text: "first ", colour: {1, 0, 0}}]}
           ]
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
               output(fn font, _, _ ->
                 TextBlock.new(
                   font: font,
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
               output(fn font, _, _ ->
                 TextBlock.new(
                   font: font,
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
               output(fn regular, bold, franklin ->
                 TextBlock.new(
                   font: regular,
                   font_size: 10,
                   position: {400, 500}
                 )
                 |> TextBlock.write("this is ", font_size: 14)
                 |> TextBlock.write("bold ", font: bold)
                 |> TextBlock.write("but this isn't ")
                 |> TextBlock.write("this is franklin", font: franklin)
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
               "400 464.0 Td",
               "ET",
               "BT",
               "390.74 452.0 Td",
               "0 0 0 rg",
               "<00D500D9> Tj",
               "ET"
             ] =
               output(fn font, _, _ ->
                 Mudbrick.TextBlock.new(
                   font: font,
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
               "225.89999999999998 500.0 Td",
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
               output(fn regular, bold, franklin ->
                 TextBlock.new(
                   font: regular,
                   font_size: 10,
                   position: {400, 500},
                   align: :right
                 )
                 |> TextBlock.write("this is ")
                 |> TextBlock.write("bold ", font: bold)
                 |> TextBlock.write("but this isn't ")
                 |> TextBlock.write("this is franklin", font: franklin)
               end)
               |> operations()
    end
  end

  defp operations(ops) do
    Enum.map(ops, &Mudbrick.TestHelper.show/1)
  end

  defp output(f) when is_function(f) do
    import Mudbrick

    {doc, _contents_obj} =
      context =
      Mudbrick.new(
        title: "My thing",
        compress: false,
        fonts: %{
          a: [file: bodoni_regular()],
          b: [file: bodoni_bold()],
          c: [file: franklin_regular()]
        }
      )
      |> page(size: Page.size(:letter))

    fonts = Mudbrick.Document.root_page_tree(doc).value.fonts
    regular_font = Map.fetch!(fonts, :a).value
    bold_font = Map.fetch!(fonts, :b).value
    franklin_regular_font = Map.fetch!(fonts, :c).value
    block = f.(regular_font, bold_font, franklin_regular_font)

    ops = Output.from(block).operations

    context
    |> Mudbrick.ContentStream.put(operations: Enum.reverse(ops))
    |> render()
    |> output()

    ops
  end

  defp output(chain) do
    tap(chain, fn rendered ->
      File.write("test.pdf", rendered)
    end)
  end
end
