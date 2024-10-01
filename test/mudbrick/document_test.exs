defmodule Mudbrick.DocumentTest do
  use ExUnit.Case, async: true

  test "can represent a document with no pages" do
    assert Mudbrick.Document.new()
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
