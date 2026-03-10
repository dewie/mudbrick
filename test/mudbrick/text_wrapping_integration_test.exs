defmodule Mudbrick.TextWrappingIntegrationTest do
  use ExUnit.Case, async: true

  import Mudbrick.TestHelper, only: [bodoni_regular: 0]
  import Mudbrick

  test "text wrapping with max_width option" do
    output_file = "test/output/text_wrapping_integration.pdf"

    new(fonts: %{bodoni: bodoni_regular()})
    |> page(size: {200, 300})
    |> text(
      "This is a very long line of text that should be wrapped automatically to fit within the specified width constraints.",
      font: :bodoni,
      font_size: 12,
      position: {10, 280},
      max_width: 80
    )
    |> render()
    |> then(&File.write(output_file, &1))

    assert File.exists?(output_file)
  end

  test "text wrapping with justification" do
    output_file = "test/output/text_wrapping_justified.pdf"

    new(fonts: %{bodoni: bodoni_regular()})
    |> page(size: {300, 400})
    |> text(
      "This text is fully justified. Spaces are distributed evenly between words to align both left and right margins. The last line is not justified.",
      font: :bodoni,
      font_size: 12,
      position: {10, 380},
      max_width: 280,
      justify: :justify
    )
    |> render()
    |> then(&File.write(output_file, &1))

    assert File.exists?(output_file)
  end

  test "text wrapping with word breaking" do
    output_file = "test/output/text_wrapping_break_words.pdf"

    new(fonts: %{bodoni: bodoni_regular()})
    |> page(size: {150, 400})
    |> text(
      "supercalifragilisticexpialidocious and other long words",
      font: :bodoni,
      font_size: 12,
      position: {10, 380},
      max_width: 130,
      break_words: true,
      hyphenate: true
    )
    |> render()
    |> then(&File.write(output_file, &1))

    assert File.exists?(output_file)
  end
end
