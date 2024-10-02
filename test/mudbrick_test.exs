defmodule MudbrickTest do
  use ExUnit.Case, async: true

  test "can serialise with multiple pages" do
    assert Mudbrick.new()
           |> Mudbrick.page(text: "hello, world!")
           |> Mudbrick.page()
           |> to_string() ==
             """
             %PDF-2.0
             1 0 obj
             <</Pages 2 0 R
               /Type /Catalog
             >>
             endobj
             2 0 obj
             <</Count 2
               /Kids [3 0 R 5 0 R]
               /Type /Pages
             >>
             endobj
             3 0 obj
             <</Contents 4 0 R
               /MediaBox [0 0 612 792]
               /Parent 2 0 R
               /Type /Page
             >>
             endobj
             4 0 obj
             <</Length 35
             >>
             stream
             BT
             300 400 Td
             (hello, world!) Tj
             ET
             endstream
             endobj
             5 0 obj
             <</MediaBox [0 0 612 792]
               /Parent 2 0 R
               /Type /Page
             >>
             endobj
             xref
             0 6
             0000000000 65535 f 
             0000000009 00000 n 
             0000000059 00000 n 
             0000000125 00000 n 
             0000000217 00000 n 
             0000000301 00000 n 
             trailer
             <</Root 1 0 R
               /Size 6
             >>
             startxref
             375
             %%EOF\
             """
  end

  test "can serialise with one empty page" do
    assert Mudbrick.new()
           |> Mudbrick.page()
           |> to_string() ==
             """
             %PDF-2.0
             1 0 obj
             <</Pages 2 0 R
               /Type /Catalog
             >>
             endobj
             2 0 obj
             <</Count 1
               /Kids [3 0 R]
               /Type /Pages
             >>
             endobj
             3 0 obj
             <</MediaBox [0 0 612 792]
               /Parent 2 0 R
               /Type /Page
             >>
             endobj
             xref
             0 4
             0000000000 65535 f 
             0000000009 00000 n 
             0000000059 00000 n 
             0000000119 00000 n 
             trailer
             <</Root 1 0 R
               /Size 4
             >>
             startxref
             193
             %%EOF\
             """
  end

  test "can serialise with no pages" do
    assert Mudbrick.new()
           |> to_string() ==
             """
             %PDF-2.0
             1 0 obj
             <</Pages 2 0 R
               /Type /Catalog
             >>
             endobj
             2 0 obj
             <</Count 0
               /Kids []
               /Type /Pages
             >>
             endobj
             xref
             0 3
             0000000000 65535 f 
             0000000009 00000 n 
             0000000059 00000 n 
             trailer
             <</Root 1 0 R
               /Size 3
             >>
             startxref
             114
             %%EOF\
             """
  end
end
