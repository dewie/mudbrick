defprotocol Mudbrick.Object do
  @fallback_to_any true
  @spec from(value :: any()) :: list()
  def from(value)
end

defimpl Mudbrick.Object, for: Any do
  def from(term) do
    [to_string(term)]
  end
end

defimpl Mudbrick.Object, for: Atom do
  def from(a) when a in [true, false] do
    [to_string(a)]
  end

  def from(name) do
    [?/, escape_chars(name)]
  end

  defp escape_chars(name) do
    name
    |> to_string()
    |> String.to_charlist()
    |> Enum.flat_map(&escape_char/1)
  end

  defp escape_char(char) when char not in ?!..?~ do
    "##{Base.encode16(to_string([char]))}" |> String.to_charlist()
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
    [?(, escape_chars(s), ?)]
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

defimpl Mudbrick.Object, for: List do
  def from(list) do
    [
      ?[,
      list
      |> Enum.map(&Mudbrick.Object.from(&1))
      |> Enum.intersperse(?\s),
      ?]
    ]
  end
end

defimpl Mudbrick.Object, for: Map do
  def from(kvs) do
    ["<<", pairs(kvs), "\n>>"]
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
    |> format_kvs()
  end

  defp format_kvs(kvs) do
    kvs
    |> Enum.map(fn {k, v} -> pair(k, v) end)
    |> Enum.intersperse("\n  ")
  end

  defp pair(k, v) do
    [Mudbrick.Object.from(k), ?\s, Mudbrick.Object.from(v)]
  end
end
