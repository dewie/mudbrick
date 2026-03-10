# Example usage of Mudbrick TextWrapper with Justification

# Basic usage with automatic text wrapping
text_block = Mudbrick.TextBlock.new(
  font: font,
  font_size: 12,
  position: {50, 700}
)
|> Mudbrick.TextBlock.write_wrapped(
  "This is a very long line of text that should be wrapped automatically to fit within the specified width constraints. It will break at word boundaries and create multiple lines as needed.",
  200  # Maximum width in points
)

# Left justification (default)
text_block = Mudbrick.TextBlock.new(font: font, font_size: 12)
|> Mudbrick.TextBlock.write_wrapped(
  "This text is left-aligned by default. Each line starts at the same position.",
  200,
  justify: :left
)

# Right justification
text_block = Mudbrick.TextBlock.new(font: font, font_size: 12)
|> Mudbrick.TextBlock.write_wrapped(
  "This text is right-aligned. Each line ends at the same position on the right side.",
  200,
  justify: :right
)

# Center justification
text_block = Mudbrick.TextBlock.new(font: font, font_size: 12)
|> Mudbrick.TextBlock.write_wrapped(
  "This text is centered. Each line is centered between the margins.",
  200,
  justify: :center
)

# Full justification (distribute spaces evenly)
text_block = Mudbrick.TextBlock.new(font: font, font_size: 12)
|> Mudbrick.TextBlock.write_wrapped(
  "This text is fully justified. Spaces are distributed evenly between words to align both left and right margins. The last line is not justified.",
  200,
  justify: :justify
)

# With word breaking and justification
text_block = Mudbrick.TextBlock.new(font: font, font_size: 12)
|> Mudbrick.TextBlock.write_wrapped(
  "supercalifragilisticexpialidocious and other long words that might not fit",
  150,
  break_words: true,
  hyphenate: true,
  justify: :justify
)

# With indentation and justification
text_block = Mudbrick.TextBlock.new(font: font, font_size: 12)
|> Mudbrick.TextBlock.write_wrapped(
  "This is a paragraph with proper indentation and justification. Each subsequent line will be indented and justified.",
  200,
  indent: 20,  # 20 points indentation for wrapped lines
  justify: :justify
)

# Direct TextWrapper usage with justification
wrapped_lines = Mudbrick.TextWrapper.wrap_text(
  "Long text here that needs to be wrapped and justified...",
  font,
  12,
  200,
  break_words: true,
  justify: :justify
)

# Then manually add to TextBlock
text_block = Enum.reduce(wrapped_lines, Mudbrick.TextBlock.new(font: font), fn line, tb ->
  Mudbrick.TextBlock.write(tb, line)
end)
