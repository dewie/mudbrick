defmodule Mudbrick.TextWrappingTest do
  use ExUnit.Case, async: true

  import Mudbrick
  import Mudbrick.TestHelper

  test "demonstrates text wrapping using text function with max_width" do
    long_text = "This is a very long line of text that should be automatically wrapped to fit within the specified width constraints and demonstrate the text wrapping functionality working correctly."

    # Create a new document with fonts
    doc = new(
      compress: true,
      fonts: %{bodoni: bodoni_regular()}
    )

    # Create page
    doc = doc |> page(size: {612, 792})  # Letter size

    # Add title
    doc = doc |> text("Text Wrapping with max_width Option", font: :bodoni, font_size: 16, position: {50, 750})

    # Test 1: Single string with max_width
    doc = doc |> text(
      "1. Single string with max_width (should wrap):",
      font: :bodoni,
      font_size: 12,
      position: {50, 720}
    )

    doc = doc |> text(
      long_text,
      font: :bodoni,
      font_size: 12,
      position: {50, 700},
      max_width: 200
    )

    # Test 2: List of strings with max_width
    doc = doc |> text(
      "2. List of strings with max_width (should wrap):",
      font: :bodoni,
      font_size: 12,
      position: {50, 620}
    )

    doc = doc |> text(
      ["First paragraph. ", "Second paragraph. ", "Third paragraph that should wrap."],
      font: :bodoni,
      font_size: 12,
      position: {50, 600},
      max_width: 200
    )

    # Test 3: List with tuples and max_width
    doc = doc |> text(
      "3. List with tuples and max_width (should wrap):",
      font: :bodoni,
      font_size: 12,
      position: {50, 520}
    )

    doc = doc |> text(
      ["This is ", {"regular text", colour: {0, 0, 0}}, " and this is ", {"colored text", colour: {1, 0, 0}}, " that should wrap."],
      font: :bodoni,
      font_size: 12,
      position: {50, 500},
      max_width: 200
    )

    # Test 4: Justification with max_width
    doc = doc |> text(
      "4. Justified text with max_width (should wrap and justify):",
      font: :bodoni,
      font_size: 12,
      position: {50, 420}
    )

    doc = doc |> text(
      long_text,
      font: :bodoni,
      font_size: 12,
      position: {50, 400},
      max_width: 200,
      justify: :justify
    )

    # Test 5: Without max_width for comparison (should overflow)
    doc = doc |> text(
      "5. Without max_width for comparison (should overflow):",
      font: :bodoni,
      font_size: 12,
      position: {50, 320}
    )

    doc = doc |> text(
      long_text,
      font: :bodoni,
      font_size: 12,
      position: {50, 300}
    )

    # Generate the PDF
    pdf_content = render(doc)

    # Write to file
    File.write!("test/output/text_wrapping_test.pdf", pdf_content)

    # Verify the file was created
    assert File.exists?("test/output/text_wrapping_test.pdf")

    # Check file size is reasonable
    file_size = File.stat!("test/output/text_wrapping_test.pdf").size
    assert file_size > 1000  # Should be at least 1KB

    IO.puts("✅ Text wrapping test PDF generated successfully!")
    IO.puts("📄 File: test/output/text_wrapping_test.pdf")
    IO.puts("📊 Size: #{file_size} bytes")
    IO.puts("🔍 Check the PDF to verify:")
    IO.puts("   - Sections 1-4 should show wrapped text within 200pt width")
    IO.puts("   - Section 4 should show justified text")
    IO.puts("   - Section 5 should show unwrapped text that overflows")
  end
end
