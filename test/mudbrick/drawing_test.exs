defmodule Mudbrick.DrawingTest do
  use ExUnit.Case, async: true

  import Mudbrick.TestHelper, only: [output: 2]

  alias Mudbrick.Drawing

  test "can make an empty line drawing" do
    assert [] =
             output(fn ->
               Drawing.new()
             end)
             |> operations()
  end

  defp output(f), do: output(fn _ -> f.() end, Mudbrick.Drawing.Output)

  defp operations(ops) do
    Enum.map(ops, &Mudbrick.TestHelper.show/1)
  end
end
