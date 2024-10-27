defmodule MudbrickTest do
  use ExUnit.Case, async: true
  doctest Mudbrick

  import Mudbrick
  import Mudbrick.TestHelper

  alias Mudbrick.Page

  test "playground" do
    assert new(
             title: "My thing",
             compress: false,
             fonts: %{bodoni: [file: bodoni_regular()]},
             images: %{flower: [file: flower()]}
           )
           |> page(size: Page.size(:letter))
           |> image(
             :flower,
             scale: Page.size(:letter),
             position: {0, 0}
           )
           |> text({"CO₂ ", colour: {1, 0, 0}},
             font: :bodoni,
             font_size: 14,
             align: :right,
             position: {200, 700}
           )
           |> text(
             {
               """
               is Carbon Dioxide
               and HNO₃ is Nitric Acid
               for sure
               """,
               colour: {0, 0, 0}
             },
             font: :bodoni,
             font_size: 14,
             position: {200, 700}
           )
           |> text(
             [
               "wide stuff",
               "wider stuff",
               "z"
             ],
             align: :right,
             font: :bodoni,
             font_size: 14,
             position: {200, 649.6}
           )
           |> text(
             """
             I am left again

             """,
             font: :bodoni,
             font_size: 14,
             leading: 14,
             position: {400, 600}
           )
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
           |> text("hello, world!",
             position: {300, 400},
             font: :helvetica,
             font_size: 100
           )
           |> text("\na new line!",
             position: {300, 400},
             font: :courier,
             font_size: 10
           )
           |> page(size: Page.size(:a4))
           |> comparable() ==
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
               /Length 1043
             >>
             stream
             <?xpacket begin=\"\uFEFF\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>
             <x:xmpmeta xmlns:x=\"adobe:ns:meta/\">
               <rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">
                 <rdf:Description rdf:about=\"\" xmlns:pdf=\"http://ns.adobe.com/pdf/1.3/\">
                   <pdf:Producer>Mudbrick</pdf:Producer>
                 </rdf:Description>
                 <rdf:Description rdf:about=\"\" xmlns:xmp=\"http://ns.adobe.com/xap/1.0/\">
                   <xmp:CreatorTool>Mudbrick</xmp:CreatorTool>
                 </rdf:Description>
                 <rdf:Description rdf:about=\"\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\">
                   <dc:format>application/pdf</dc:format>
                   <dc:title>
                     <rdf:Alt>
                       <rdf:li xml:lang=\"x-default\"></rdf:li>
                     </rdf:Alt>
                   </dc:title>
                 </rdf:Description>
                 <rdf:Description rdf:about=\"\" xmlns:xmpMM=\"http://ns.adobe.com/xap/1.0/mm/\">
                   <xmpMM:DocumentID>0000000000000000000000000000000000000000000</xmpMM:DocumentID>
                   <xmpMM:InstanceID>0000000000000000000000000000000000000000000</xmpMM:InstanceID>
                 </rdf:Description>
               </rdf:RDF>
             </x:xmpmeta>

             <?xpacket end=\"w\"?>
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
             <</Length 130
             >>
             stream
             BT
             /F2 100 Tf
             120.0 TL
             300 400 Td
             0 0 0 rg
             (hello, world!) Tj
             ET
             BT
             /F1 10 Tf
             12.0 TL
             300 400 Td
             0 0 0 rg
             () Tj
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
             <</Length 0
             >>
             stream
             endstream
             endobj
             xref
             0 10
             0000000000 65535 f 
             0000000023 00000 n 
             0000000125 00000 n 
             0000000229 00000 n 
             0000001357 00000 n 
             0000001491 00000 n 
             0000001559 00000 n 
             0000001653 00000 n 
             0000001833 00000 n 
             0000001929 00000 n 
             trailer
             <</Root 5 0 R
               /Size 10
             >>
             startxref
             1976
             %%EOF\
             """
  end

  test "can serialise with one empty page" do
    assert new()
           |> page()
           |> comparable() ==
             """
             %PDF-2.0
             %����
             1 0 obj
             <</Type /Metadata
               /Subtype /XML
               /Length 1043
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
                   <xmpMM:DocumentID>0000000000000000000000000000000000000000000</xmpMM:DocumentID>
                   <xmpMM:InstanceID>0000000000000000000000000000000000000000000</xmpMM:InstanceID>
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
             <</Length 0
             >>
             stream
             endstream
             endobj
             xref
             0 6
             0000000000 65535 f 
             0000000023 00000 n 
             0000001151 00000 n 
             0000001258 00000 n 
             0000001326 00000 n 
             0000001422 00000 n 
             trailer
             <</Root 3 0 R
               /Size 6
             >>
             startxref
             1469
             %%EOF\
             """
  end

  test "can serialise with no pages" do
    assert new()
           |> comparable() ==
             """
             %PDF-2.0
             %����
             1 0 obj
             <</Type /Metadata
               /Subtype /XML
               /Length 1043
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
                   <xmpMM:DocumentID>0000000000000000000000000000000000000000000</xmpMM:DocumentID>
                   <xmpMM:InstanceID>0000000000000000000000000000000000000000000</xmpMM:InstanceID>
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
             0000001151 00000 n 
             0000001253 00000 n 
             trailer
             <</Root 3 0 R
               /Size 4
             >>
             startxref
             1321
             %%EOF\
             """
  end

  def comparable(doc) do
    doc
    |> render()
    |> to_string()
    |> String.replace(
      ~r{<xmpMM:(Document|Instance)ID>.*</xmpMM:(Document|Instance)ID>},
      "<xmpMM:\\1ID>0000000000000000000000000000000000000000000</xmpMM:\\2ID>"
    )
  end

  def output(chain) do
    tap(chain, fn rendered ->
      File.write("test.pdf", rendered)
    end)
  end
end
