defmodule MudbrickTest do
  use ExUnit.Case, async: true
  doctest Mudbrick

  import Mudbrick
  import Mudbrick.TestHelper

  alias Mudbrick.Page

  test "playground" do
    assert new(
             title: "My thing",
             compress: true,
             fonts: %{bodoni: [file: bodoni()]},
             images: %{flower: [file: flower()]}
           )
           |> page(size: Page.size(:letter))
           |> image(
             :flower,
             scale: Page.size(:letter),
             position: {0, 0}
           )
           |> text_position(200, 700)
           |> font(:bodoni, size: 14)
           |> colour({1, 0, 0})
           |> text("CO₂ ", align: :right)
           |> colour({0, 0, 0})
           |> text("""
           is Carbon Dioxide
           and HNO₃ is Nitric Acid
           """)
           |> text("wide stuff", align: :right)
           |> text("wider stuff", align: :right)
           |> text("z", align: :right)
           |> text_position(400, 600)
           |> font(:bodoni, size: 14, leading: 14)
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
           |> page(size: Page.size(:letter))
           |> text_position(300, 400)
           |> font(:helvetica, size: 100)
           |> text("hello, world!")
           |> font(:courier, size: 10)
           |> text("""

           a new line!\
           """)
           |> page(size: Page.size(:a4))
           |> render()
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
             <</Type /Metadata
               /Subtype /XML
               /Length 1042
             >>
             stream
             <?xpacket begin="﻿" id="W5M0MpCehiHzreSzNTczkc9d"?>
             <x:xmpmeta xmlns:x="adobe:ns:meta/">
               <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                 <rdf:Description rdf:about="" xmlns:pdf="http://ns.adobe.com/pdf/1.3/">
                   <pdf:Producer>Mudbrick</pdf:Producer>
                 </rdf:Description>
                 <rdf:Description rdf:about="" xmlns:xmp="http://ns.adobe.com/xap/1.0/">
                   <xmp:CreatorTool>Mudbrick</xmp:CreatorTool>
                 </rdf:Description>
                 <rdf:Description rdf:about="" xmlns:dc="http://purl.org/dc/elements/1.1/">
                   <dc:format>application/pdf</dc:format>
                   <dc:title>
                     <rdf:Alt>
                       <rdf:li xml:lang="x-default"></rdf:li>
                     </rdf:Alt>
                   </dc:title>
                 </rdf:Description>
                 <rdf:Description rdf:about="" xmlns:xmpMM="http://ns.adobe.com/xap/1.0/mm/">
                   <xmpMM:DocumentID>/aqULtTrBy1/G8uKIgoObFx4RRZpMG/nCojsDy26YOc</xmpMM:DocumentID>
                  <xmpMM:InstanceID>ZzBsu+wjW0fPjubUZGQhCkklz6Jw67Gx+Qj0Nc4L4Uk</xmpMM:InstanceID>
                 </rdf:Description>
               </rdf:RDF>
             </x:xmpmeta>

             <?xpacket end="w"?>
             endstream
             endobj
             4 0 obj
             <</Type /Pages
               /Count 2
               /Kids [6 0 R 8 0 R]
               /Resources <</Font <</F1 1 0 R
               /F2 2 0 R
             >>
               /XObject <<
             >>
             >>
             >>
             endobj
             5 0 obj
             <</Type /Catalog
               /Metadata 3 0 R
               /Pages 4 0 R
             >>
             endobj
             6 0 obj
             <</Type /Page
               /Contents 7 0 R
               /MediaBox [0 0 612.0 792]
               /Parent 4 0 R
             >>
             endobj
             7 0 obj
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
             8 0 obj
             <</Type /Page
               /Contents 9 0 R
               /MediaBox [0 0 597.6 842.4]
               /Parent 4 0 R
             >>
             endobj
             9 0 obj
             <</Length 5
             >>
             stream
             BT
             ET
             endstream
             endobj
             xref
             0 10
             0000000000 65535 f 
             0000000023 00000 n 
             0000000125 00000 n 
             0000000229 00000 n 
             0000001356 00000 n 
             0000001490 00000 n 
             0000001558 00000 n 
             0000001652 00000 n 
             0000001790 00000 n 
             0000001886 00000 n 
             trailer
             <</Root 5 0 R
               /Size 10
             >>
             startxref
             1939
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
             <</Type /Metadata
               /Subtype /XML
               /Length 1042
             >>
             stream
             <?xpacket begin="﻿" id="W5M0MpCehiHzreSzNTczkc9d"?>
             <x:xmpmeta xmlns:x="adobe:ns:meta/">
               <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                 <rdf:Description rdf:about="" xmlns:pdf="http://ns.adobe.com/pdf/1.3/">
                   <pdf:Producer>Mudbrick</pdf:Producer>
                 </rdf:Description>
                 <rdf:Description rdf:about="" xmlns:xmp="http://ns.adobe.com/xap/1.0/">
                   <xmp:CreatorTool>Mudbrick</xmp:CreatorTool>
                 </rdf:Description>
                 <rdf:Description rdf:about="" xmlns:dc="http://purl.org/dc/elements/1.1/">
                   <dc:format>application/pdf</dc:format>
                   <dc:title>
                     <rdf:Alt>
                       <rdf:li xml:lang="x-default"></rdf:li>
                     </rdf:Alt>
                   </dc:title>
                 </rdf:Description>
                 <rdf:Description rdf:about="" xmlns:xmpMM="http://ns.adobe.com/xap/1.0/mm/">
                   <xmpMM:DocumentID>T1PNoYwrqgwDVLtfmj7L5e0Sq02OEbqHPC8RFhICuUU</xmpMM:DocumentID>
                  <xmpMM:InstanceID>KMdbFiJuJL2vUCqI9jJB/TN84ka0KLXNcewGIRwbZyc</xmpMM:InstanceID>
                 </rdf:Description>
               </rdf:RDF>
             </x:xmpmeta>

             <?xpacket end="w"?>
             endstream
             endobj
             2 0 obj
             <</Type /Pages
               /Count 1
               /Kids [4 0 R]
               /Resources <</Font <<
             >>
               /XObject <<
             >>
             >>
             >>
             endobj
             3 0 obj
             <</Type /Catalog
               /Metadata 1 0 R
               /Pages 2 0 R
             >>
             endobj
             4 0 obj
             <</Type /Page
               /Contents 5 0 R
               /MediaBox [0 0 597.6 842.4]
               /Parent 2 0 R
             >>
             endobj
             5 0 obj
             <</Length 5
             >>
             stream
             BT
             ET
             endstream
             endobj
             xref
             0 6
             0000000000 65535 f 
             0000000023 00000 n 
             0000001150 00000 n 
             0000001257 00000 n 
             0000001325 00000 n 
             0000001421 00000 n 
             trailer
             <</Root 3 0 R
               /Size 6
             >>
             startxref
             1474
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
             <</Type /Metadata
               /Subtype /XML
               /Length 1042
             >>
             stream
             <?xpacket begin="﻿" id="W5M0MpCehiHzreSzNTczkc9d"?>
             <x:xmpmeta xmlns:x="adobe:ns:meta/">
               <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                 <rdf:Description rdf:about="" xmlns:pdf="http://ns.adobe.com/pdf/1.3/">
                   <pdf:Producer>Mudbrick</pdf:Producer>
                 </rdf:Description>
                 <rdf:Description rdf:about="" xmlns:xmp="http://ns.adobe.com/xap/1.0/">
                   <xmp:CreatorTool>Mudbrick</xmp:CreatorTool>
                 </rdf:Description>
                 <rdf:Description rdf:about="" xmlns:dc="http://purl.org/dc/elements/1.1/">
                   <dc:format>application/pdf</dc:format>
                   <dc:title>
                     <rdf:Alt>
                       <rdf:li xml:lang="x-default"></rdf:li>
                     </rdf:Alt>
                   </dc:title>
                 </rdf:Description>
                 <rdf:Description rdf:about="" xmlns:xmpMM="http://ns.adobe.com/xap/1.0/mm/">
                   <xmpMM:DocumentID>T1PNoYwrqgwDVLtfmj7L5e0Sq02OEbqHPC8RFhICuUU</xmpMM:DocumentID>
                  <xmpMM:InstanceID>KMdbFiJuJL2vUCqI9jJB/TN84ka0KLXNcewGIRwbZyc</xmpMM:InstanceID>
                 </rdf:Description>
               </rdf:RDF>
             </x:xmpmeta>

             <?xpacket end="w"?>
             endstream
             endobj
             2 0 obj
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
             3 0 obj
             <</Type /Catalog
               /Metadata 1 0 R
               /Pages 2 0 R
             >>
             endobj
             xref
             0 4
             0000000000 65535 f 
             0000000023 00000 n 
             0000001150 00000 n 
             0000001252 00000 n 
             trailer
             <</Root 3 0 R
               /Size 4
             >>
             startxref
             1320
             %%EOF\
             """
  end

  def output(chain) do
    tap(chain, fn rendered ->
      File.write("test.pdf", rendered)
    end)
  end
end
