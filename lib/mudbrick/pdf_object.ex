defprotocol Mudbrick.PDFObject do
  @spec from(value :: any()) :: String.t()
  def from(value)
end

defimpl Mudbrick.PDFObject, for: Atom do
  def from(a) when a in [true, false] do
    "#{a}"
  end

  def from(a) do
    "/#{a}"
  end
end

defimpl Mudbrick.PDFObject, for: BitString do
  @escapees %{
    ?\n => "\\n",
    ?\r => "\\r",
    ?\t => "\\t",
    ?\b => "\\b",
    ?\f => "\\f",
    ?( => "\\(",
    ?) => "\\)",
    ?\\ => "\\",
    0xDDD => "\\ddd"
  }

  def from(s) do
    "(#{escape_chars(s)})"
  end

  defp escape_chars(name) do
    name
    |> String.to_charlist()
    |> Enum.flat_map(&escape_char/1)
    |> Kernel.to_string()
  end

  defp escape_char(char) do
    [Map.get(@escapees, char, char)]
  end
end

defimpl Mudbrick.PDFObject, for: Mudbrick.Catalog do
  def from(catalog) do
    Mudbrick.PDFObject.from(%{
      Type: :Catalog,
      Pages: catalog.page_tree
    })
  end
end

defimpl Mudbrick.PDFObject, for: Mudbrick.PageTree do
  def from(_page_tree) do
    Mudbrick.PDFObject.from(%{Type: :Pages, Kids: [], Count: 0})
  end
end

defimpl Mudbrick.PDFObject, for: Float do
  def from(f) do
    "#{f}"
  end
end

defimpl Mudbrick.PDFObject, for: Integer do
  def from(i) do
    "#{i}"
  end
end

defimpl Mudbrick.PDFObject, for: List do
  def from(list) do
    "[#{Enum.map_join(list, " ", fn item -> Mudbrick.PDFObject.from(item) end)}]"
  end
end

defimpl Mudbrick.PDFObject, for: Map do
  def from(kvs) do
    "<<#{pairs(kvs)}\n>>"
  end

  defp pairs(kvs) do
    kvs
    |> Enum.sort()
    |> Enum.map_join("\n", fn {k, v} -> "  #{pair(k, v)}" end)
    |> String.trim_leading()
  end

  defp pair(k, v) do
    "#{Mudbrick.PDFObject.from(k)} #{Mudbrick.PDFObject.from(v)}"
  end
end

defimpl Mudbrick.PDFObject, for: Mudbrick.Name do
  def from(name) do
    "/#{escape_chars(name.value)}"
  end

  defp escape_chars(name) do
    name
    |> String.to_charlist()
    |> Enum.flat_map(&escape_char/1)
    |> Kernel.to_string()
  end

  defp escape_char(char) when char not in ?!..?~ do
    "##{Base.encode16("#{[char]}")}" |> String.to_charlist()
  end

  defp escape_char(char) do
    [char]
  end
end
