defmodule Mudbrick.TextBlockTest do
  use ExUnit.Case, async: true

  import Mudbrick.TestHelper, only: [bodoni: 0]

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
      |> TextBlock.write("""
      third line\
      """)
      |> TextBlock.write("\nfourth", colour: {0, 1, 0})

    assert block.lines == [
             %Line{parts: [%Part{text: "fourth", colour: {0, 1, 0}}]},
             %Line{
               parts: [
                 %Part{text: "", colour: {0, 1, 0}},
                 %Part{text: "third line"},
                 %Part{text: ""}
               ]
             },
             %Line{parts: [%Part{text: "second line"}]},
             %Line{parts: [%Part{text: "line"}, %Part{text: "first ", colour: {1, 0, 0}}]}
           ]
  end

  describe "left-aligned" do
    test "newlines become apostrophes" do
      assert [
               "BT",
               "/F1 10 Tf",
               "12.0 TL",
               "400 500 Td",
               "<014C010F0116011D01B700ED00D900F400C0> Tj",
               "<011600C000B500FC00F400BB01B700ED00D900F400C0> '",
               "() '",
               "ET"
             ] =
               output(fn font ->
                 TextBlock.new(
                   font: font,
                   font_size: 10,
                   position: {400, 500}
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
               "<00A5> Tj",
               "1 0 0 rg",
               "<00B4> Tj",
               "0 1 0 rg",
               "() Tj",
               "<00B5> '",
               "<00BB> '",
               "0 0 1 rg",
               "<00C0> Tj",
               "ET"
             ] =
               output(fn font ->
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
  end

  describe "right-aligned" do
    test "newlines become Tjs with offsets" do
      assert [
               "BT",
               "/F1 10 Tf",
               "12.0 TL",
               "384.82 500.0 Td",
               "<00A500A500A5> Tj",
               "ET",
               "BT",
               "379.42 488.0 Td",
               "<013801380138> Tj",
               "ET",
               "BT",
               "306.48 476.0 Td",
               "<00880055008800550088005500880055008800550088> Tj",
               "ET",
               "BT",
               "400 464.0 Td",
               "() Tj",
               "ET",
               "BT",
               "390.74 452.0 Td",
               "<00D500D9> Tj",
               "ET"
             ] =
               output(fn font ->
                 Mudbrick.TextBlock.new(
                   font: font,
                   font_size: 10,
                   position: {400, 500},
                   align: :right
                 )
                 |> Mudbrick.TextBlock.write("""
                 aaa
                 www
                 WOWOWOWOWOW

                 hi\
                 """)
               end)
               |> operations()
    end
  end

  defp operations(tb) do
    tb
    |> Output.from()
    |> Enum.reverse()
    |> Enum.map(&Mudbrick.TestHelper.show/1)
  end

  defp output(f) when is_function(f) do
    import Mudbrick

    {_doc, contents_obj} =
      context =
      Mudbrick.new(
        title: "My thing",
        compress: false,
        fonts: %{bodoni: [file: bodoni()]}
      )
      |> page(size: Page.size(:letter))
      |> font(:bodoni, size: 14)

    block = f.(contents_obj.value.current_tf.font)

    context
    |> Mudbrick.ContentStream.put(operations: Output.from(block))
    |> render()
    |> output()

    block
  end

  defp output(chain) do
    tap(chain, fn rendered ->
      File.write("test.pdf", rendered)
    end)
  end
end
