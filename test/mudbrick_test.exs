defmodule MudbrickTest do
  use ExUnit.Case, async: true
  doctest Mudbrick

  import Mudbrick
  import Mudbrick.TestHelper

  alias Mudbrick.Path

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
end
