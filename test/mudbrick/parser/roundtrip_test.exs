defmodule Mudbrick.ParseRoundtripTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Mudbrick
  import Mudbrick.TestHelper

  alias Mudbrick.Parser

  property "documents" do
    check all document_options <- document_options(),
              pages_options <- list_of(page_options()),
              images_options <- list_of(image_options()),
              max_runs: 75 do
      doc = new(document_options)
      images = Keyword.get(document_options, :images, %{})

      input =
        Enum.zip([pages_options, cycle(images_options), cycle(Map.keys(images))])
        |> Enum.reduce(doc, fn {page_options, image_options, image_identifier}, context ->
          context
          |> page(page_options)
          |> then(fn page_context ->
            if Enum.empty?(image_options) or Enum.empty?(document_options[:images]) do
              page_context
            else
              page_context
              |> image(image_identifier, image_options)
            end
          end)
        end)
        |> render()

      parsed =
        input
        |> IO.iodata_to_binary()
        |> Parser.parse()
        |> render()

      assert parsed == input
    end
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

  test "with an image" do
    input =
      new(images: %{flower: flower()})
      |> page()
      |> image(
        :flower,
        scale: {100, 100},
        position: {0, 0}
      )
      |> render()

    parsed =
      input
      |> IO.iodata_to_binary()
      |> Parser.parse()
      |> render()

    assert parsed == input
  end

  test "custom page size" do
    input =
      new()
      |> page(size: {400, 100})
      |> render()

    parsed =
      input
      |> IO.iodata_to_binary()
      |> Parser.parse()
      |> render()

    assert parsed == input
  end

  test "with rectangle" do
    input =
      new()
      |> page(size: {100, 100})
      |> path(fn path ->
        Mudbrick.Path.rectangle(path, lower_left: {0, 0}, dimensions: {50, 60})
      end)
      |> render()

    parsed =
      input
      |> IO.iodata_to_binary()
      |> Parser.parse()
      |> render()

    assert parsed == input
  end

  test "with underline" do
    input =
      new(fonts: %{poop: bodoni_bold()})
      |> page(size: {400, 100})
      |> text(
        [{"Warning\n", underline: [width: 0.5]}],
        font: :poop,
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
    input =
      new(
        fonts: %{
          bodoni: bodoni_regular(),
          franklin: franklin_regular()
        }
      )
      |> page()
      |> text("hello, bodoni", font: :bodoni)
      |> text("hello, franklin", font: :franklin)
      |> render()

    parsed =
      input
      |> IO.iodata_to_binary()
      |> Parser.parse()
      |> render()

    assert parsed == input
  end

  test "PDF with text, compressed" do
    input =
      new(
        compress: true,
        fonts: %{
          bodoni: bodoni_regular(),
          franklin: franklin_regular()
        }
      )
      |> page()
      |> text("hello, bodoni", font: :bodoni)
      |> text("hello, franklin", font: :franklin)
      |> render()

    parsed =
      input
      |> IO.iodata_to_binary()
      |> Parser.parse()
      |> Mudbrick.render()

    assert parsed == input
  end

  defp cycle([]), do: []
  defp cycle(enumerable), do: Stream.cycle(enumerable)
end
