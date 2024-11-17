defmodule Mudbrick.ContentStream.Rg do
  @moduledoc false
  @enforce_keys [:r, :g, :b]
  defstruct stroking: false,
            r: nil,
            g: nil,
            b: nil

  def new(opts) do
    if Enum.any?(Keyword.delete(opts, :stroking), fn {_k, v} ->
         v < 0 or v > 1
       end) do
      raise Mudbrick.ContentStream.InvalidColour,
            "tuple must be made of floats or integers between 0 and 1"
    end

    struct!(__MODULE__, opts)
  end

  defimpl Mudbrick.Object do
    def to_iodata(%Mudbrick.ContentStream.Rg{stroking: false, r: r, g: g, b: b}) do
      [[r, g, b] |> Enum.map_join(" ", &to_string/1), " rg"]
    end

    def to_iodata(%Mudbrick.ContentStream.Rg{stroking: true, r: r, g: g, b: b}) do
      [[r, g, b] |> Enum.map_join(" ", &to_string/1), " RG"]
    end
  end
end
