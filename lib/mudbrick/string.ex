defmodule Mudbrick.String do
  defstruct [:value]

  def new(s) do
    %Mudbrick.String{value: s}
  end

  defimpl String.Chars do
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

    def to_string(mudbrick_string) do
      "(#{escape_chars(mudbrick_string.value)})"
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
end
