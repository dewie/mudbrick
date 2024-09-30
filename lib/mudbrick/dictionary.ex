defmodule Mudbrick.Dictionary do
  defstruct [:kv]

  def new(kv) do
    %Mudbrick.Dictionary{kv: kv}
  end

  defimpl String.Chars do
    def to_string(%Mudbrick.Dictionary{kv: kvs}) do
      for {k, v} <- kvs, reduce: "<<" do
        "<<" ->
          "<<#{k} #{v}\n"

        acc ->
          acc <> "  #{k} #{v}\n"
      end <> ">>"
    end
  end
end
