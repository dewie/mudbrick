defprotocol Mudbrick.Object do
  @spec from(value :: any()) :: String.t()
  def from(value)
end

defimpl Mudbrick.Object, for: Atom do
  def from(a) when a in [true, false] do
    "#{a}"
  end

  def from(name) do
    "/#{escape_chars(to_string(name))}"
  end

  defp escape_chars(name) do
    name
    |> to_string()
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
      {:Type, _v1}, _ -> true
      _pair, {:Type, _v2} -> false
      {:Subtype, _v1}, _pair -> true
      _pair, {:Subtype, _v2} -> false
      {k1, _v1}, {k2, _v2} -> k1 <= k2
    end)
    |> Enum.map_join("\n", fn {k, v} -> "  #{pair(k, v)}" end)
    |> String.trim_leading()
  end

  defp pair(k, v) do
    "#{Mudbrick.Object.from(k)} #{Mudbrick.Object.from(v)}"
  end
end
