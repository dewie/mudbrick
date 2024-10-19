# Mudbrick

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

To do:

- Graphics.
- Compression.
- Font subsetting.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `mudbrick` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mudbrick, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/mudbrick>.

