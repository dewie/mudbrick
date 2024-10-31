defmodule Mudbrick.DrawingTest do
  use ExUnit.Case, async: true

  import Mudbrick.TestHelper, only: [output: 2]

  alias Mudbrick.Drawing
  alias Mudbrick.Drawing.Path

  test "can construct a path" do
    import Drawing

    drawing =
      new()
      |> path(from: {0, 0}, to: {50, 50})

    assert drawing.paths == [
             Path.new(from: {0, 0}, to: {50, 50})
           ]
  end

  test "can make an empty drawing" do
    import Drawing

    assert [] =
             output(fn ->
               new()
             end)
             |> operations()
  end

  test "can draw one path" do
    import Drawing

    assert [
             "0 50 m",
             "60 50 l",
             "S"
           ] =
             output(fn ->
               new()
               |> path(from: {0, 50}, to: {60, 50})
             end)
             |> operations()
  end

  defp output(f), do: output(fn _ -> f.() end, Mudbrick.Drawing.Output)

  defp operations(ops) do
    Enum.map(ops, &Mudbrick.TestHelper.show/1) |> Enum.reverse()
  end
end
