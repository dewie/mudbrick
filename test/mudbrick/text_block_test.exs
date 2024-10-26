defmodule Mudbrick.TextBlockTest do
  use ExUnit.Case, async: true

  import Mudbrick.TestHelper, only: [bodoni: 0]

  alias Mudbrick.Page

  test "left-aligned newlines become apostrophes" do
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
               Mudbrick.TextBlock.new(
                 font: font,
                 font_size: 10,
                 position: {400, 500}
               )
               |> Mudbrick.TextBlock.write("""
               first line
               second line
               """)
             end)
             |> operations()
  end

  test "right-aligned newlines become Tjs with offsets" do
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
               """)
             end)
             |> operations()
  end
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
               """)
             end)
             |> operations()
  end

  defp operations(block) do
    Enum.reverse(block.operations) |> Enum.map(&Mudbrick.TestHelper.show/1)
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
    |> Mudbrick.ContentStream.put(operations: block.operations)
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
