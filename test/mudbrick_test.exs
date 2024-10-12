defmodule MudbrickTest do
  use ExUnit.Case, async: true

  import Mudbrick

  test "playground" do
    data = System.fetch_env!("FONT_LIBRE_BODONI_REGULAR") |> File.read!()

    assert new()
           |> page(
             size: :letter,
             fonts: %{
               bodoni: [
                 file: data,
                 encoding: :"Identity-H"
               ]
             }
           )
           |> contents()
           |> font(:bodoni, size: 13)
           |> text_position(0, 700)
           |> text("CO₂ is Carbon Dioxide and HNO₃ is Nitric Acid")
           |> render()
           |> output()
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
               ],
               courier: [
                 name: :Courier,
                 type: :TrueType,
                 encoding: :PDFDocEncoding
               ]
             }
           )
           |> contents()
           |> font(:helvetica, size: 24)
           |> text_position(300, 400)
           |> text("hello, world!")
           |> font(:courier, size: 12)
           |> text_position(0, -24)
           |> text("a new line!")
           |> page(size: :a4)
           |> render()
           |> output
           |> to_string() ==
             """
             %PDF-2.0
             %����
             1 0 obj
             <</Type /Pages
               /Count 2
               /Kids [5 0 R 7 0 R]
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
               /BaseFont /Courier
               /Encoding /PDFDocEncoding
             >>
             endobj
             4 0 obj
             <</Type /Font
               /Subtype /TrueType
               /BaseFont /Helvetica
               /Encoding /PDFDocEncoding
             >>
             endobj
             5 0 obj
             <</Type /Page
               /Contents 6 0 R
               /MediaBox [0 0 612.0 792]
               /Parent 1 0 R
               /Resources <</Font <</F1 3 0 R
               /F2 4 0 R
             >>
             >>
             >>
             endobj
             6 0 obj
             <</Length 81
             >>
             stream
             BT
             /F2 24 Tf
             300 400 Td
             (hello, world!) Tj
             /F1 12 Tf
             0 -24 Td
             (a new line!) Tj
             ET
             endstream
             endobj
             7 0 obj
             <</Type /Page
               /MediaBox [0 0 597.6 842.4]
               /Parent 1 0 R
             >>
             endobj
             xref
             0 8
             0000000000 65535 f 
             0000000023 00000 n 
             0000000089 00000 n 
             0000000139 00000 n 
             0000000241 00000 n 
             0000000345 00000 n 
             0000000490 00000 n 
             0000000620 00000 n 
             trailer
             <</Root 2 0 R
               /Size 8
             >>
             startxref
             698
             %%EOF\
             """
  end

  test "can serialise with one empty page" do
    assert new()
           |> page()
           |> render()
           |> to_string() ==
             """
             %PDF-2.0
             %����
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
             0000000023 00000 n 
             0000000083 00000 n 
             0000000133 00000 n 
             trailer
             <</Root 2 0 R
               /Size 4
             >>
             startxref
             211
             %%EOF\
             """
  end

  test "can serialise with no pages" do
    assert new()
           |> render()
           |> to_string() ==
             """
             %PDF-2.0
             %����
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
             0000000023 00000 n 
             0000000078 00000 n 
             trailer
             <</Root 2 0 R
               /Size 3
             >>
             startxref
             128
             %%EOF\
             """
  end

  def output(chain) do
    tap(chain, fn rendered ->
      File.write("test.pdf", rendered)
    end)
  end
end
