defmodule Mudbrick.ParseRoundtripTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Mudbrick.Parser

  test "minimal PDF" do
    input = Mudbrick.new()

    assert input
           |> Mudbrick.render()
           |> IO.iodata_to_binary()
           |> Parser.parse() == input
  end

  test "custom page size" do
    input =
      Mudbrick.new()
      |> Mudbrick.page(size: {400, 100})
      |> Mudbrick.Document.finish()

    assert input
           |> Mudbrick.render()
           |> IO.iodata_to_binary()
           |> Parser.parse() == input
  end

  test "with rectangle" do
    import Mudbrick

    input =
      new()
      |> page(size: {100, 100})
      |> path(fn path ->
        Mudbrick.Path.rectangle(path, lower_left: {0, 0}, dimensions: {50, 60})
      end)
      |> render()
      |> IO.iodata_to_binary()

    parsed =
      input
      |> Parser.parse()
      |> render()
      |> IO.iodata_to_binary()

    assert parsed == input
  end

  test "with underline" do
    import Mudbrick.TestHelper
    import Mudbrick

    input =
      new(fonts: %{bodoni: bodoni_bold()})
      |> page(size: {400, 100})
      |> text(
        [{"Warning\n", underline: [width: 0.5]}],
        font: :bodoni,
        font_size: 70,
        position: {7, 30}
      )
      |> render()

    parsed =
      input
      |> IO.iodata_to_binary()
      |> Parser.parse()
      |> render()

    assert parsed == input
  end

  test "PDF with text" do
    alias Mudbrick.TestHelper
    import Mudbrick

    input =
      new(
        fonts: %{
          bodoni: TestHelper.bodoni_regular(),
          franklin: TestHelper.franklin_regular()
        }
      )
      |> page()
      |> text("hello, bodoni", font: :bodoni)
      |> text("hello, franklin", font: :franklin)
      |> Mudbrick.Document.finish()

    binary =
      input
      |> Mudbrick.render()
      |> IO.iodata_to_binary()

    assert binary ==
             binary
             |> Parser.parse()
             |> Mudbrick.render()
             |> IO.iodata_to_binary()
  end

  test "PDF with text, compressed" do
    alias Mudbrick.TestHelper
    import Mudbrick

    input =
      new(
        compress: true,
        fonts: %{
          bodoni: TestHelper.bodoni_regular(),
          franklin: TestHelper.franklin_regular()
        }
      )
      |> page()
      |> text("hello, bodoni", font: :bodoni)
      |> text("hello, franklin", font: :franklin)
      |> Mudbrick.Document.finish()

    binary =
      input
      |> Mudbrick.render()
      |> IO.iodata_to_binary()

    parsed_binary =
      binary
      |> Parser.parse()
      |> Mudbrick.render()
      |> IO.iodata_to_binary()

    assert binary == parsed_binary
  end

  property "objects" do
    base_object =
      one_of([
        atom(:alphanumeric),
        boolean(),
        integer(),
        float(min: -999, max: 999),
        string(:alphanumeric)
      ])

    check all input <-
                one_of([
                  base_object,
                  list_of(base_object),
                  list_of(list_of(base_object)),
                  map_of(atom(:alphanumeric), base_object),
                  map_of(atom(:alphanumeric), map_of(atom(:alphanumeric), base_object))
                ]),
              max_runs: 50 do
      assert input
             |> Mudbrick.Object.to_iodata()
             |> Parser.to_mudbrick(:object) == input
    end
  end
end
