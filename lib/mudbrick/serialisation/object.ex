defprotocol Mudbrick.Object do
  @spec from(value :: any()) :: String.t()
  def from(value)
end

defimpl Mudbrick.Object, for: Atom do
  def from(a) when a in [true, false] do
    "#{a}"
  end

  def from(a) do
    "/#{a}"
  end
end

defimpl Mudbrick.Object, for: BitString do
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

defimpl Mudbrick.Object, for: Mudbrick.Catalog do
  def from(catalog) do
    Mudbrick.Object.from(%{
      Type: :Catalog,
      Pages: catalog.page_tree
    })
  end
end

defimpl Mudbrick.Object, for: Mudbrick.ContentStream do
  def from(stream) do
    inner = """
    BT
    /F1 24 Tf
    300 400 Td
    (#{stream.text}) Tj
    ET\
    """

    """
    #{Mudbrick.Object.from(%{Length: byte_size(inner)})}
    stream
    #{inner}
    endstream\
    """
  end
end

defimpl Mudbrick.Object, for: Mudbrick.PageTree do
  def from(page_tree) do
    Mudbrick.Object.from(%{
      Type: :Pages,
      Kids: page_tree.kids,
      Count: length(page_tree.kids)
    })
  end
end

defimpl Mudbrick.Object, for: Mudbrick.Page do
  def from(page) do
    {width, height} = page.size

    Mudbrick.Object.from(
      %{
        Type: :Page,
        Parent: page.parent,
        MediaBox: [0, 0, width, height]
      }
      |> Map.merge(
        case page.contents_ref do
          nil -> %{}
          ref -> %{Contents: ref, Resources: %{Font: %{F1: page.font_ref}}}
        end
      )
    )
  end
end

defimpl Mudbrick.Object, for: Mudbrick.Indirect.Object do
  def from(%Mudbrick.Indirect.Object{value: value, ref: ref}) do
    """
    #{ref.number} 0 obj
    #{Mudbrick.Object.from(value)}
    endobj\
    """
  end
end

defimpl Mudbrick.Object, for: Mudbrick.Indirect.Ref do
  def from(%Mudbrick.Indirect.Ref{number: number}) do
    "#{number} 0 R"
  end
end

defimpl Mudbrick.Object, for: Float do
  def from(f) do
    "#{f}"
  end
end

defimpl Mudbrick.Object, for: Integer do
  def from(i) do
    "#{i}"
  end
end

defimpl Mudbrick.Object, for: List do
  def from(list) do
    "[#{Enum.map_join(list, " ", fn item -> Mudbrick.Object.from(item) end)}]"
  end
end

defimpl Mudbrick.Object, for: Map do
  def from(kvs) do
    "<<#{pairs(kvs)}\n>>"
  end

  defp pairs(kvs) do
    kvs
    |> Enum.sort(fn
      {:Type, _v1}, {_k2, _v2} -> true
      {_k1, _v1}, {:Type, _v2} -> false
      {k1, _v1}, {k2, _v2} -> k1 <= k2
    end)
    |> Enum.map_join("\n", fn {k, v} -> "  #{pair(k, v)}" end)
    |> String.trim_leading()
  end

  defp pair(k, v) do
    "#{Mudbrick.Object.from(k)} #{Mudbrick.Object.from(v)}"
  end
end

defimpl Mudbrick.Object, for: Mudbrick.Name do
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
