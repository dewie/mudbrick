defmodule Mudbrick.DrawingTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Mudbrick.TestHelper,
    only: [
      invalid_colour: 0,
      output: 2
    ]

  alias Mudbrick.Path
  alias Mudbrick.Path.Output
  alias Mudbrick.Path.SubPath

  test "can construct a path" do
    import Path

    path =
      new()
      |> sub_path(from: {0, 0}, to: {50, 50})

    assert path.sub_paths == [
             SubPath.new(from: {0, 0}, to: {50, 50}, line_width: 1)
           ]
  end

  test "can make an empty path" do
    import Path

    assert [] =
             output(fn ->
               new()
             end)
             |> operations()
  end

  test "can draw one path" do
    import Path

    assert [
             "0 0 0 RG",
             "1 w",
             "0 650 m",
             "460 750 l",
             "S"
           ] =
             output(fn ->
               new()
               |> sub_path(from: {0, 650}, to: {460, 750})
             end)
             |> operations()
  end

  test "can choose line width" do
    import Path

    assert [
             "0 0 0 RG",
             "4.0 w",
             "0 650 m",
             "460 750 l",
             "S"
           ] =
             output(fn ->
               new()
               |> sub_path(from: {0, 650}, to: {460, 750}, line_width: 4.0)
             end)
             |> operations()
  end

  test "can choose colour" do
    import Path

    assert [
             "0 1 0 RG",
             "1 w",
             "0 650 m",
             "460 750 l",
             "S"
           ] =
             output(fn ->
               new()
               |> sub_path(from: {0, 650}, to: {460, 750}, colour: {0, 1, 0})
             end)
             |> operations()
  end

  property "it's an error to set a colour above 1" do
    import Path

    check all colour <- invalid_colour() do
      e =
        assert_raise(Mudbrick.ContentStream.InvalidColour, fn ->
          new()
          |> sub_path(from: {0, 0}, to: {0, 0}, colour: colour)
          |> Output.from()
        end)

      assert e.message == "tuple must be made of floats or integers between 0 and 1"
    end
  end

  defp output(f), do: output(fn _ -> f.() end, Mudbrick.Path.Output)

  defp operations(ops) do
    Enum.map(ops, &Mudbrick.TestHelper.show/1) |> Enum.reverse()
  end
end
