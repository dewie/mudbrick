defmodule Mudbrick.ContentStream.Rg do
  @moduledoc false
  defstruct [:r, :g, :b]

  def new(opts) do
    if Enum.any?(opts, fn {_k, v} ->
         v < 0 or v > 1
       end) do
      raise Mudbrick.ContentStream.InvalidColour,
            "tuple must be made of floats or integers between 0 and 1"
    end

    struct!(__MODULE__, opts)
  end

  defimpl Mudbrick.Object do
    def from(%Mudbrick.ContentStream.Rg{r: r, g: g, b: b}) do
      [[r, g, b] |> Enum.map_join(" ", &to_string/1), " rg"]
    end
  end
end

defmodule Mudbrick.ContentStream.RgStroking do
  @moduledoc false
  defstruct [:r, :g, :b]

  def new(opts) do
    if Enum.any?(opts, fn {_k, v} ->
         v < 0 or v > 1
       end) do
      raise Mudbrick.ContentStream.InvalidColour,
            "tuple must be made of floats or integers between 0 and 1"
    end

    struct!(__MODULE__, opts)
  end

  defimpl Mudbrick.Object do
    def from(%Mudbrick.ContentStream.RgStroking{r: r, g: g, b: b}) do
      [[r, g, b] |> Enum.map_join(" ", &to_string/1), " RG"]
    end
  end
end
