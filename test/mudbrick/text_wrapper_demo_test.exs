defmodule Mudbrick.TextWrapperDemoTest do
  use ExUnit.Case, async: true

  import Mudbrick
  import Mudbrick.TestHelper

  alias Mudbrick.TextWrapper

  test "demonstrates text wrapping and justification features" do
    # Demo text samples
    long_text = """
    This is a demonstration of the new text wrapping and justification features in Mudbrick.
    This paragraph contains a very long line of text that should be automatically wrapped
    to fit within the specified width constraints. The text will break at word boundaries
    and create multiple lines as needed for proper formatting.
    """

    short_text = "Short line for testing."

    word_breaking_text = """
    This paragraph contains supercalifragilisticexpialidocious and other very long words
    that might not fit within normal line widths. We can break these words and add
    hyphens for better formatting.
    """

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
    doc = doc |> text("Text Wrapping and Justification Demo", font: :bodoni, font_size: 16, position: {50, 750})

           # Demo 1: Basic text wrapping (left-aligned)
           wrapped_lines = TextWrapper.wrap_text(long_text, font, 12, 300)
           doc = doc |> text(
             "1. Basic Text Wrapping (Left-aligned):\n\n" <> Enum.join(wrapped_lines, "\n"),
             font: :bodoni, font_size: 12, position: {50, 700})

           # Demo 2: Right justification
           wrapped_lines = TextWrapper.wrap_text(long_text, font, 12, 300, justify: :right)
           doc = doc |> text(
             "2. Right Justification:\n\n" <> Enum.join(wrapped_lines, "\n"),
             font: :bodoni, font_size: 12, position: {50, 600})

           # Demo 3: Center justification
           wrapped_lines = TextWrapper.wrap_text(long_text, font, 12, 300, justify: :center)
           doc = doc |> text(
             "3. Center Justification:\n\n" <> Enum.join(wrapped_lines, "\n"),
             font: :bodoni, font_size: 12, position: {50, 500})

           # Demo 4: Full justification
           wrapped_lines = TextWrapper.wrap_text(long_text, font, 12, 300, justify: :justify)
           doc = doc |> text(
             "4. Full Justification:\n\n" <> Enum.join(wrapped_lines, "\n"),
             font: :bodoni, font_size: 12, position: {50, 400})

           # Demo 5: Word breaking with hyphenation
           wrapped_lines = TextWrapper.wrap_text(word_breaking_text, font, 12, 200,
             break_words: true,
             hyphenate: true,
             justify: :justify
           )
           doc = doc |> text(
             "5. Word Breaking with Hyphenation:\n\n" <> Enum.join(wrapped_lines, "\n"),
             font: :bodoni, font_size: 12, position: {50, 300})

           # Demo 6: Indentation with justification
           wrapped_lines = TextWrapper.wrap_text(long_text, font, 12, 300,
             indent: 30,
             justify: :justify
           )
           doc = doc |> text(
             "6. Indentation with Justification:\n\n" <> Enum.join(wrapped_lines, "\n"),
             font: :bodoni, font_size: 12, position: {50, 200})

           # Demo 7: Different widths comparison
           narrow_lines = TextWrapper.wrap_text(short_text, font, 12, 150, justify: :justify)
           medium_lines = TextWrapper.wrap_text(short_text, font, 12, 250, justify: :justify)
           wide_lines = TextWrapper.wrap_text(short_text, font, 12, 350, justify: :justify)

           doc = doc |> text(
             "7. Different Widths Comparison:\n\n" <>
             "Narrow (150pt):\n" <> Enum.join(narrow_lines, "\n") <> "\n\n" <>
             "Medium (250pt):\n" <> Enum.join(medium_lines, "\n") <> "\n\n" <>
             "Wide (350pt):\n" <> Enum.join(wide_lines, "\n"),
             font: :bodoni, font_size: 12, position: {50, 100})

    # Generate the PDF
    pdf_content = render(doc)

    # Write to file
    File.write!("test/output/text_wrapper_demo.pdf", pdf_content)

    # Verify the file was created
    assert File.exists?("test/output/text_wrapper_demo.pdf")

    # Check file size is reasonable
    file_size = File.stat!("test/output/text_wrapper_demo.pdf").size
    assert file_size > 1000  # Should be at least 1KB

    IO.puts("✅ Text wrapper demo PDF generated successfully!")
    IO.puts("📄 File: test/output/text_wrapper_demo.pdf")
    IO.puts("📊 Size: #{file_size} bytes")
  end

  test "demonstrates direct TextWrapper usage" do
    # Demo text
    text = """
    This demonstrates direct usage of the TextWrapper module. We can wrap text
    programmatically and then add it to TextBlocks manually for more control
    over the formatting process.
    """

    # Create a new document with fonts
    doc = new(
      compress: true,
      fonts: %{bodoni: bodoni_regular()}
    )

    # Extract the font for TextWrapper usage
    font = (doc |> Mudbrick.Document.find_object(&match?(%Mudbrick.Font{}, &1))).value

    # Create page
    doc = doc |> page(size: {612, 792})

    # Use TextWrapper directly
    wrapped_lines = TextWrapper.wrap_text(
      text,
      font,
      12,
      300,
      justify: :justify,
      break_words: true
    )

           # Add the wrapped lines to the document
           doc = doc |> text(
             "Direct TextWrapper Usage:\n\n" <> Enum.join(wrapped_lines, "\n"),
             font: :bodoni, font_size: 12, position: {50, 750})

    # Generate PDF
    pdf_content = render(doc)
    File.write!("test/output/text_wrapper_direct.pdf", pdf_content)

    # Verify
    assert File.exists?("test/output/text_wrapper_direct.pdf")

    IO.puts("✅ Direct TextWrapper demo PDF generated!")
    IO.puts("📄 File: test/output/text_wrapper_direct.pdf")
  end

  test "demonstrates edge cases and error handling" do
    # Create a new document with fonts
    doc = new(
      compress: true,
      fonts: %{bodoni: bodoni_regular()}
    )

    # Extract the font for TextWrapper usage
    font = (doc |> Mudbrick.Document.find_object(&match?(%Mudbrick.Font{}, &1))).value

    # Create page
    doc = doc |> page(size: {612, 792})

           # Test edge cases
           empty_lines = TextWrapper.wrap_text("", font, 12, 200, justify: :center)
           single_word_lines = TextWrapper.wrap_text("word", font, 12, 200, justify: :right)
           long_word_lines = TextWrapper.wrap_text("supercalifragilisticexpialidocious", font, 12, 100,
             break_words: true,
             hyphenate: true
           )
           invalid_justify_lines = TextWrapper.wrap_text("This should be left-aligned despite invalid option.", font, 12, 200,
             justify: :invalid_option
           )
           narrow_width_lines = TextWrapper.wrap_text("This text will be wrapped very tightly.", font, 12, 50,
             break_words: true
           )

           doc = doc |> text(
             "Edge Cases and Error Handling:\n\n" <>
             "Empty string:\n" <> Enum.join(empty_lines, "\n") <> "\n\n" <>
             "Single word:\n" <> Enum.join(single_word_lines, "\n") <> "\n\n" <>
             "Very long word:\n" <> Enum.join(long_word_lines, "\n") <> "\n\n" <>
             "Invalid justification (defaults to left):\n" <> Enum.join(invalid_justify_lines, "\n") <> "\n\n" <>
             "Very narrow width:\n" <> Enum.join(narrow_width_lines, "\n"),
             font: :bodoni, font_size: 12, position: {50, 750})

    # Generate PDF
    pdf_content = render(doc)
    File.write!("test/output/text_wrapper_edge_cases.pdf", pdf_content)

    # Verify
    assert File.exists?("test/output/text_wrapper_edge_cases.pdf")

    IO.puts("✅ Edge cases demo PDF generated!")
    IO.puts("📄 File: test/output/text_wrapper_edge_cases.pdf")
  end
end
