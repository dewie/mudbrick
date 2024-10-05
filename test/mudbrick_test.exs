defmodule MudbrickTest do
  use ExUnit.Case, async: true

  test "can serialise with multiple pages" do
    assert Mudbrick.new(page_size: :a4)
           |> Mudbrick.page()
           |> Mudbrick.text("hello, world!")
           |> Mudbrick.page()
           |> Mudbrick.render() ==
             """
             %PDF-2.0
             1 0 obj
             <</Count 2
               /Kids [3 0 R 6 0 R]
               /Type /Pages
             >>
             endobj
             2 0 obj
             <</Pages 1 0 R
               /Type /Catalog
             >>
             endobj
             3 0 obj
             <</Contents 4 0 R
               /MediaBox [0 0 597.6 842.4]
               /Parent 1 0 R
               /Resources <</Font <</F1 5 0 R
             >>
             >>
               /Type /Page
             >>
             endobj
             4 0 obj
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
             5 0 obj
             <</BaseFont /Helvetica
               /Encoding /Identity-H
               /Subtype /TrueType
               /Type /Font
             >>
             endobj
             6 0 obj
             <</MediaBox [0 0 597.6 842.4]
               /Parent 1 0 R
               /Type /Page
             >>
             endobj
             xref
             0 7
             0000000000 65535 f 
             0000000009 00000 n 
             0000000075 00000 n 
             0000000125 00000 n 
             0000000260 00000 n 
             0000000354 00000 n 
             0000000454 00000 n 
             trailer
             <</Root 2 0 R
               /Size 7
             >>
             startxref
             532
             %%EOF\
             """
  end

  test "can serialise with one empty page" do
    assert Mudbrick.new()
           |> Mudbrick.page()
           |> Mudbrick.render() ==
             """
             %PDF-2.0
             1 0 obj
             <</Count 1
               /Kids [3 0 R]
               /Type /Pages
             >>
             endobj
             2 0 obj
             <</Pages 1 0 R
               /Type /Catalog
             >>
             endobj
             3 0 obj
             <</MediaBox [0 0 597.6 842.4]
               /Parent 1 0 R
               /Type /Page
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
    assert Mudbrick.new()
           |> Mudbrick.render() ==
             """
             %PDF-2.0
             1 0 obj
             <</Count 0
               /Kids []
               /Type /Pages
             >>
             endobj
             2 0 obj
             <</Pages 1 0 R
               /Type /Catalog
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
    end)
  end
end
