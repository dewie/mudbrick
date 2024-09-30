defmodule Mudbrick.Name do
  defstruct [:value]

  def new(value) when not is_nil(value) do
    %Mudbrick.Name{value: value}
  end

  defimpl String.Chars do
    def to_string(name) do
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
end
