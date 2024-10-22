defmodule Mudbrick.Metadata do
  def render(opts) do
    document_id = id(opts)
    instance_id = id([:x | opts])

    [
      """
      <?xpacket begin="\uFEFF" id="W5M0MpCehiHzreSzNTczkc9d"?>
      <x:xmpmeta xmlns:x="adobe:ns:meta/">
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <rdf:Description rdf:about="" xmlns:pdf="http://ns.adobe.com/pdf/1.3/">
            <pdf:Producer>\
      """,
      Keyword.get(opts, :producer, "Mudbrick"),
      """
      </pdf:Producer>
          </rdf:Description>
          <rdf:Description rdf:about="" xmlns:xmp="http://ns.adobe.com/xap/1.0/">
            <xmp:CreatorTool>\
      """,
      Keyword.get(opts, :creator_tool, "Mudbrick"),
      """
      </xmp:CreatorTool>
      """,
      date("CreateDate", opts[:create_date]),
      date("ModifyDate", opts[:modify_date]),
      """
          </rdf:Description>
          <rdf:Description rdf:about="" xmlns:dc="http://purl.org/dc/elements/1.1/">
            <dc:format>application/pdf</dc:format>
            <dc:title>
              <rdf:Alt>
                <rdf:li xml:lang="x-default">\
      """,
      Keyword.get(opts, :title, ""),
      """
      </rdf:li>
              </rdf:Alt>
            </dc:title>
      """,
      creators(opts[:creators]),
      """
          </rdf:Description>
          <rdf:Description rdf:about="" xmlns:xmpMM="http://ns.adobe.com/xap/1.0/mm/">
            <xmpMM:DocumentID>\
      """,
      document_id,
      """
      </xmpMM:DocumentID>
           <xmpMM:InstanceID>\
      """,
      instance_id,
      """
      </xmpMM:InstanceID>
          </rdf:Description>
        </rdf:RDF>
      </x:xmpmeta>

      <?xpacket end="w"?>\
      """
    ]
  end

  defp creators([]), do: ""
  defp creators(nil), do: ""

  defp creators(creators) do
    [
      """
      <dc:creator>
        <rdf:Seq>
      """,
      for(name <- creators, do: ["<rdf:li>", name, "</rdf:li>"]),
      """
      </rdf:Seq>
      </dc:creator>
      """
    ]
  end

  defp date(_, nil), do: ""

  defp date(element_name, date) do
    ["<xmp:", element_name, ">", DateTime.to_iso8601(date), "</xmp:", element_name, ">"]
  end

  defp id(opts) do
    :crypto.hash(:sha256, inspect(opts))
    |> Base.encode64(padding: false)
  end
end
