defmodule Mudbrick.ContentStreamTest do
  use ExUnit.Case, async: true

  import Mudbrick

  alias Mudbrick.ContentStream.{Td, Tf, Tj, Ts}

  test "translates subscripts to lowercased below-line versions" do
    {_, object} =
      Mudbrick.new()
      |> page(
        fonts: %{
          helvetica: [
            name: :Helvetica,
            type: :TrueType,
            encoding: :PDFDocEncoding
          ],
          a_font_that_becomes_f1: [
            name: :SomeFont,
            type: :TrueType,
            encoding: :PDFDocEncoding
          ]
        }
      )
      |> contents()
      |> font(:helvetica, size: 24)
      |> text_position(300, 400)
      |> text("CO₂ is Carbon Dioxide and HNO₃ is Nitric Acid")

    assert object.value.operations == [
             %Tf{font: :F2, size: 24},
             %Td{tx: 300, ty: 400},
             %Tj{text: "CO"},
             %Ts{rise: -6.0},
             %Tf{font: :F2, size: 16},
             %Tj{text: "2"},
             %Tf{font: :F2, size: 24},
             %Ts{rise: 0},
             %Tj{text: " is Carbon Dioxide and HNO"},
             %Ts{rise: -6.0},
             %Tf{font: :F2, size: 16},
             %Tj{text: "3"},
             %Tf{font: :F2, size: 24},
             %Ts{rise: 0},
             %Tj{text: " is Nitric Acid"}
           ]
  end
end
