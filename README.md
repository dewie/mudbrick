# Mudbrick

[Documentation](https://hexdocs.pm/mudbrick)

Early-stages PDF generator, beelining for:

- PDF 2.0 support.
- In-process, pure functional approach.
- OpenType support.
- Special characters and ligatures, like ₛᵤ₆ₛ꜀ᵣᵢₚₜₛ for chemical compounds etc.

Currently working:

- OpenType fonts with ligatures and special characters.
- Text positioning.
- Right alignment.
- Coloured text.
- JPEG images.
- Compression.

To do:

- Other image formats.
- Font subsetting.
- Vector graphics.

## Installation

```elixir
def deps do
  [
    {:mudbrick, "~> 0.1.0"}
  ]
end
```
