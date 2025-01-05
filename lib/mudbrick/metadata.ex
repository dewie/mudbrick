defmodule Mudbrick.Metadata do
  @moduledoc false

  def render(opts) do
    opts = normalised_opts(opts)
    document_id = id(opts)
    instance_id = id([{:generate, :instance_id} | opts])

    [
      """
      <?xpacket begin="\uFEFF" id="W5M0MpCehiHzreSzNTczkc9d"?>
      <x:xmpmeta xmlns:x="adobe:ns:meta/">
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <rdf:Description rdf:about="" xmlns:pdf="http://ns.adobe.com/pdf/1.3/">
            <pdf:Producer>\
      """,
      Keyword.fetch!(opts, :producer),
      """
      </pdf:Producer>
          </rdf:Description>
          <rdf:Description rdf:about="" xmlns:xmp="http://ns.adobe.com/xap/1.0/">
            <xmp:CreatorTool>\
      """,
      Keyword.fetch!(opts, :creator_tool),
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
      Keyword.fetch!(opts, :title),
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
  defp date(_, ""), do: ""

  defp date(element_name, date) do
    ["<xmp:", element_name, ">", DateTime.to_iso8601(date), "</xmp:", element_name, ">"]
  end

  defp id(opts) do
    {fonts, opts} = hashable_resources(opts, :fonts)
    {images, opts} = hashable_resources(opts, :images)

    :crypto.hash(
      :sha256,
      [
        Application.spec(:mudbrick)[:vsn],
        inspect(opts),
        fonts,
        images
      ]
    )
    |> Base.encode64(padding: false)
  end

  defp hashable_resources(opts, type) do
    case Keyword.pop(opts, type) do
      {nil, opts} ->
        {"", opts}

      {resources, opts} ->
        {Map.values(resources) |> Enum.sort(), opts}
    end
  end

  defp normalised_opts(opts) do
    compress = Keyword.get(opts, :compress, false)
    create_date = empty_string_opt(opts, :create_date)
    creators = empty_string_opt(opts, :creators, [])
    creator_tool = Keyword.get(opts, :creator_tool, "Mudbrick")
    modify_date = empty_string_opt(opts, :modify_date)
    producer = Keyword.get(opts, :producer, "Mudbrick")
    title = empty_string_opt(opts, :title, "")

    opts
    |> Keyword.put(:compress, compress)
    |> Keyword.put(:create_date, create_date)
    |> Keyword.put(:creators, creators)
    |> Keyword.put(:creator_tool, creator_tool)
    |> Keyword.put(:modify_date, modify_date)
    |> Keyword.put(:producer, producer)
    |> Keyword.put(:title, title)
  end

  defp empty_string_opt(opts, key, default \\ nil) do
    case Keyword.get(opts, key, default) do
      "" -> default
      otherwise -> otherwise
    end
  end
end
