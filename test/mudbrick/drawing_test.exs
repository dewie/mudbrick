defmodule Mudbrick.DrawingTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Mudbrick.TestHelper,
    only: [
      invalid_colour: 0,
      output: 2
    ]

  alias Mudbrick.Path

  alias Mudbrick.Path.{
    Output,
    Rectangle,
    StraightLine
  }

  test "can add drawings to a page" do
    import Mudbrick

    assert [
             "q",
             "1 0 0 RG",
             "1 w",
             "0 0 m",
             "50 60 l",
             "S",
             "Q",
             "q",
             "0 0 0 RG",
             "1 w",
             "0 0 50 60 re",
             "S",
             "Q"
           ] =
             new()
             |> page()
             |> path(fn path ->
               Path.straight_line(path, from: {0, 0}, to: {50, 60}, colour: {1, 0, 0})
             end)
             |> path(fn path ->
               Path.rectangle(path, lower_left: {0, 0}, dimensions: {50, 60})
             end)
             |> Mudbrick.TestHelper.output()
             |> Mudbrick.TestHelper.operations()
  end

  test "can construct a rectangle" do
    import Path

    path =
      new()
      |> rectangle(lower_left: {0, 0}, dimensions: {50, 75})

    assert path.sub_paths == [
             Rectangle.new(
               lower_left: {0, 0},
               dimensions: {50, 75},
               line_width: 1
             )
           ]
  end

  test "can construct a path with one straight line" do
    import Path

    path =
      new()
      |> straight_line(from: {0, 0}, to: {50, 50})

    assert path.sub_paths == [
             StraightLine.new(
               from: {0, 0},
               to: {50, 50},
               line_width: 1
             )
           ]
  end

  test "can make an empty path" do
    import Path

    assert [] =
             operations(fn ->
               new()
             end)
  end

  test "can render a rectangle" do
    import Path

    assert [
             "q",
             "0 0 0 RG",
             "1 w",
             "0 0 50 75 re",
             "S",
             "Q"
           ] =
             operations(fn ->
               new()
               |> rectangle(lower_left: {0, 0}, dimensions: {50, 75})
             end)
  end

  test "can draw one path" do
    import Path

    assert [
             "q",
             "0 0 0 RG",
             "1 w",
             "0 650 m",
             "460 750 l",
             "S",
             "Q"
           ] =
             operations(fn ->
               new()
               |> straight_line(from: {0, 650}, to: {460, 750})
             end)
  end

  test "can choose line width" do
    import Path

    assert [
             "q",
             "0 0 0 RG",
             "4.0 w",
             "0 650 m",
             "460 750 l",
             "S",
             "Q"
           ] =
             operations(fn ->
               new()
               |> straight_line(from: {0, 650}, to: {460, 750}, line_width: 4.0)
             end)
  end

  test "can choose colour" do
    import Path

    assert [
             "q",
             "0 1 0 RG",
             "1 w",
             "0 650 m",
             "460 750 l",
             "S",
             "Q"
           ] =
             operations(fn ->
               new()
               |> straight_line(from: {0, 650}, to: {460, 750}, colour: {0, 1, 0})
             end)
  end

  property "it's an error to set a colour above 1" do
    import Path

    check all colour <- invalid_colour() do
      e =
        assert_raise(Mudbrick.ContentStream.InvalidColour, fn ->
          new()
          |> straight_line(from: {0, 0}, to: {0, 0}, colour: colour)
          |> Output.from()
        end)

      assert e.message == "tuple must be made of floats or integers between 0 and 1"
    end
  end

  defp operations(f) do
    output(fn _ -> f.() end, Mudbrick.Path.Output)
    |> Enum.map(&Mudbrick.TestHelper.show/1)
    |> Enum.reverse()
  end
end
