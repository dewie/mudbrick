defmodule Mudbrick.TextBlockTest do
  alias Mudbrick.ContentStream.Apostrophe
  use ExUnit.Case, async: true

  import Mudbrick.TestHelper, only: [bodoni: 0]

  alias Mudbrick.ContentStream.{BT, ET}
  alias Mudbrick.ContentStream.Td
  alias Mudbrick.ContentStream.Tf
  alias Mudbrick.ContentStream.{Tj, Apostrophe}
  alias Mudbrick.ContentStream.TL
  alias Mudbrick.Page

  test "left-aligned newlines become apostrophes" do
    assert [
             %BT{},
             %Td{tx: 400, ty: 500},
             %Tf{size: 10},
             %TL{leading: 12.0},
             %Tj{text: "first line"},
             %Apostrophe{text: "second line"},
             %Apostrophe{text: ""},
             %ET{}
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

  defp operations(block) do
    Enum.reverse(block.operations)
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
