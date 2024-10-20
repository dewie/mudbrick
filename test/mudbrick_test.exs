defmodule MudbrickTest do
  use ExUnit.Case, async: true

  import Mudbrick

  test "playground" do
    assert new(
             fonts: %{bodoni: [file: TestHelper.bodoni()]},
             images: %{flower: [file: TestHelper.flower()]}
           )
           |> page(size: :letter)
           |> text_position(200, 700)
           |> font(:bodoni, size: 14)
           |> colour({1, 0, 0})
           |> text("CO₂ ", align: :right)
           |> colour({0, 0, 0})
           |> text("""
           is Carbon Dioxide
           and HNO₃ is Nitric Acid
           """)
           |> image(:flower)
           |> text("wide stuff", align: :right)
           |> text("wider stuff", align: :right)
           |> text("z", align: :right)
           |> text_position(400, 600)
           |> text("""
           I am left again

           """)
           |> text(
             """
             I am right again
             I am right again
             """,
             align: :right
           )
           |> text("""
           I am left again

           """)
           |> render()
           |> output()
  end

  test "can serialise with multiple pages" do
    assert new(
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
           |> page(size: :letter)
           |> text_position(300, 400)
           |> font(:helvetica, size: 100)
           |> text("hello, world!")
           |> font(:courier, size: 10)
           |> text("""

           a new line!\
           """)
           |> page(size: :a4)
           |> render()
           |> output()
           |> to_string() ==
             """
             %PDF-2.0
             %����
             1 0 obj
             <</Type /Font
               /Subtype /TrueType
               /BaseFont /Courier
               /Encoding /PDFDocEncoding
             >>
             endobj
             2 0 obj
             <</Type /Font
               /Subtype /TrueType
               /BaseFont /Helvetica
               /Encoding /PDFDocEncoding
             >>
             endobj
             3 0 obj
             <</Type /Pages
               /Count 2
               /Kids [5 0 R 7 0 R]
               /Resources <</Font <</F1 1 0 R
               /F2 2 0 R
             >>
               /XObject <<
             >>
             >>
             >>
             endobj
             4 0 obj
             <</Type /Catalog
               /Pages 3 0 R
             >>
             endobj
             5 0 obj
             <</Type /Page
               /Contents 6 0 R
               /MediaBox [0 0 612.0 792]
               /Parent 3 0 R
             >>
             endobj
             6 0 obj
             <</Length 89
             >>
             stream
             BT
             300 400 Td
             /F2 100 Tf
             120.0 TL
             (hello, world!) Tj
             /F1 10 Tf
             12.0 TL
             (a new line!) '
             ET
             endstream
             endobj
             7 0 obj
             <</Type /Page
               /Contents 8 0 R
               /MediaBox [0 0 597.6 842.4]
               /Parent 3 0 R
             >>
             endobj
             8 0 obj
             <</Length 5
             >>
             stream
             BT
             ET
             endstream
             endobj
             xref
             0 9
             0000000000 65535 f 
             0000000023 00000 n 
             0000000125 00000 n 
             0000000229 00000 n 
             0000000363 00000 n 
             0000000413 00000 n 
             0000000507 00000 n 
             0000000645 00000 n 
             0000000741 00000 n 
             trailer
             <</Root 4 0 R
               /Size 9
             >>
             startxref
             794
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
               /Resources <</Font <<
             >>
               /XObject <<
             >>
             >>
             >>
             endobj
             2 0 obj
             <</Type /Catalog
               /Pages 1 0 R
             >>
             endobj
             3 0 obj
             <</Type /Page
               /Contents 4 0 R
               /MediaBox [0 0 597.6 842.4]
               /Parent 1 0 R
             >>
             endobj
             4 0 obj
             <</Length 5
             >>
             stream
             BT
             ET
             endstream
             endobj
             xref
             0 5
             0000000000 65535 f 
             0000000023 00000 n 
             0000000130 00000 n 
             0000000180 00000 n 
             0000000276 00000 n 
             trailer
             <</Root 2 0 R
               /Size 5
             >>
             startxref
             329
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
               /Resources <</Font <<
             >>
               /XObject <<
             >>
             >>
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
             0000000125 00000 n 
             trailer
             <</Root 2 0 R
               /Size 3
             >>
             startxref
             175
             %%EOF\
             """
  end

  def output(chain) do
    tap(chain, fn rendered ->
      File.write("test.pdf", rendered)
    end)
  end
end
