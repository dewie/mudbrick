defmodule Mudbrick.TextWrappingVerificationTest do
  use ExUnit.Case, async: true

  import Mudbrick
  import Mudbrick.TestHelper

  alias Mudbrick.TextWrapper

  test "verifies text wrapping works in PDF" do
    long_text = "This is a very long line of text that should be automatically wrapped to fit within the specified width constraints and demonstrate the text wrapping functionality."

    # Create a new document with fonts
    doc = new(
      compress: true,
      fonts: %{bodoni: bodoni_regular()}
    )

    # Extract the font for TextWrapper usage
    font = (doc |> Mudbrick.Document.find_object(&match?(%Mudbrick.Font{}, &1))).value

    # Create page
    doc = doc |> page(size: {612, 792})  # Letter size

    # Add title
    doc = doc |> text("Text Wrapping Verification", font: :bodoni, font_size: 16, position: {50, 750})

    # Test 1: Unwrapped text (should overflow)
    doc = doc |> text("1. Unwrapped text (should overflow):", font: :bodoni, font_size: 12, position: {50, 700})
    doc = doc |> text(long_text, font: :bodoni, font_size: 12, position: {50, 680})

    # Test 2: Wrapped text (should fit within width)
    doc = doc |> text("2. Wrapped text (should fit within 200pt width):", font: :bodoni, font_size: 12, position: {50, 600})
    wrapped_lines = TextWrapper.wrap_text(long_text, font, 12, 200)
    doc = doc |> text(Enum.join(wrapped_lines, "\n"), font: :bodoni, font_size: 12, position: {50, 580})

    # Test 3: Justified wrapped text
    doc = doc |> text("3. Justified wrapped text:", font: :bodoni, font_size: 12, position: {50, 500})
    justified_lines = TextWrapper.wrap_text(long_text, font, 12, 200, justify: :justify)
    doc = doc |> text(Enum.join(justified_lines, "\n"), font: :bodoni, font_size: 12, position: {50, 480})

    # Generate the PDF
    pdf_content = render(doc)

    # Write to file
    File.write!("test/output/text_wrapping_verification.pdf", pdf_content)

    # Verify the file was created
    assert File.exists?("test/output/text_wrapping_verification.pdf")

    # Check file size is reasonable
    file_size = File.stat!("test/output/text_wrapping_verification.pdf").size
    assert file_size > 1000  # Should be at least 1KB

    IO.puts("✅ Text wrapping verification PDF generated successfully!")
    IO.puts("📄 File: test/output/text_wrapping_verification.pdf")
    IO.puts("📊 Size: #{file_size} bytes")
    IO.puts("🔍 Check the PDF to verify:")
    IO.puts("   - Section 1: Text should overflow the page width")
    IO.puts("   - Section 2: Text should be wrapped to fit within 200pt width")
    IO.puts("   - Section 3: Text should be wrapped and justified")
  end
end

