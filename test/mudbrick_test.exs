defmodule MudbrickTest do
  use ExUnit.Case, async: true

  import Mudbrick

  test "can add and use fonts" do
    {doc, _} =
      new()
      |> page(
        size: :letter,
        fonts: %{
          helvetica: [
            name: :Helvetica,
            type: :TrueType,
            encoding: :PDFDocEncoding
          ]
        }
      )

    assert Enum.find(doc.objects, fn
             %Mudbrick.Indirect.Object{
               value: %Mudbrick.Font{
                 name: :Helvetica,
                 encoding: :PDFDocEncoding,
                 type: :TrueType
               }
             } ->
               true

             _ ->
               false
           end)
  end

  test "can serialise with multiple pages" do
    assert new()
           |> page(
             size: :letter,
             fonts: %{
               helvetica: [
                 name: :Helvetica,
                 type: :TrueType,
                 encoding: :PDFDocEncoding
               ]
             }
           )
           |> text("hello, world!")
           |> page(size: :a4)
           |> render() ==
             """
             %PDF-2.0
             1 0 obj
             <</Type /Pages
               /Count 2
               /Kids [4 0 R 6 0 R]
             >>
             endobj
             2 0 obj
             <</Type /Catalog
               /Pages 1 0 R
             >>
             endobj
             3 0 obj
             <</Type /Font
               /Subtype /TrueType
               /BaseFont /Helvetica
               /Encoding /PDFDocEncoding
             >>
             endobj
             4 0 obj
             <</Type /Page
               /Contents 5 0 R
               /MediaBox [0 0 612.0 792]
               /Parent 1 0 R
               /Resources <</Font <</F1 3 0 R
             >>
             >>
             >>
             endobj
             5 0 obj
             <</Length 45
             >>
             stream
             BT
             /F1 24 Tf
             300 400 Td
             (hello, world!) Tj
             ET
             endstream
             endobj
             6 0 obj
             <</Type /Page
               /MediaBox [0 0 597.6 842.4]
               /Parent 1 0 R
             >>
             endobj
             xref
             0 7
             0000000000 65535 f 
             0000000009 00000 n 
             0000000075 00000 n 
             0000000125 00000 n 
             0000000229 00000 n 
             0000000362 00000 n 
             0000000456 00000 n 
             trailer
             <</Root 2 0 R
               /Size 7
             >>
             startxref
             534
             %%EOF\
             """
  end

  test "can serialise with one empty page" do
    assert new()
           |> page()
           |> render() ==
             """
             %PDF-2.0
             1 0 obj
             <</Type /Pages
               /Count 1
               /Kids [3 0 R]
             >>
             endobj
             2 0 obj
             <</Type /Catalog
               /Pages 1 0 R
             >>
             endobj
             3 0 obj
             <</Type /Page
               /MediaBox [0 0 597.6 842.4]
               /Parent 1 0 R
             >>
             endobj
             xref
             0 4
             0000000000 65535 f 
             0000000009 00000 n 
             0000000069 00000 n 
             0000000119 00000 n 
             trailer
             <</Root 2 0 R
               /Size 4
             >>
             startxref
             197
             %%EOF\
             """
  end

  test "can serialise with no pages" do
    assert new()
           |> render() ==
             """
             %PDF-2.0
             1 0 obj
             <</Type /Pages
               /Count 0
               /Kids []
             >>
             endobj
             2 0 obj
             <</Type /Catalog
               /Pages 1 0 R
             >>
             endobj
             xref
             0 3
             0000000000 65535 f 
             0000000009 00000 n 
             0000000064 00000 n 
             trailer
             <</Root 2 0 R
               /Size 3
             >>
             startxref
             114
             %%EOF\
             """
  end

  def output(chain) do
    tap(chain, fn {doc, _} ->
      File.write("test.pdf", to_string(doc))
      System.cmd("gio", ~w(open test.pdf))
    end)
  end
end
