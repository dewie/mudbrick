defmodule Mudbrick.ContentStream do
  @enforce_keys [:page]
  defstruct page: nil, operations: []

  alias Mudbrick.Document

  defmodule Rg do
    defstruct [:r, :g, :b]

    defimpl Mudbrick.Object do
      def from(%Rg{r: r, g: g, b: b}) do
        [[r, g, b] |> Enum.map_join(" ", &to_string/1), " rg"]
      end
    end
  end

  defmodule Tf do
    defstruct [:font, :size]

    defimpl Mudbrick.Object do
      def from(tf) do
        [
          Mudbrick.Object.from(tf.font.resource_identifier),
          " ",
          to_string(tf.size),
          " Tf"
        ]
      end
    end
  end

  defmodule Td do
    defstruct [:tx, :ty, :purpose]

    defimpl Mudbrick.Object do
      def from(td) do
        [td.tx, td.ty, "Td"]
        |> Enum.map(&to_string/1)
        |> Enum.intersperse(" ")
      end
    end
  end

  defmodule TL do
    defstruct [:leading]

    defimpl Mudbrick.Object do
      def from(tl) do
        [to_string(tl.leading), " TL"]
      end
    end
  end

  defmodule Tj do
    defstruct font: nil,
              operator: "Tj",
              text: nil
  end

  defmodule Apostrophe do
    defstruct font: nil,
              operator: "'",
              text: nil
  end

  defimpl Mudbrick.Object, for: [Tj, Apostrophe] do
    def from(op) do
      if op.font.descendant && String.length(op.text) > 0 do
        {glyph_ids_decimal, _positions} =
          OpenType.layout_text(op.font.parsed, op.text)

        glyph_ids_hex = Enum.map(glyph_ids_decimal, &Mudbrick.to_hex/1)

        ["<", glyph_ids_hex, "> ", op.operator]
      else
        [Mudbrick.Object.from(op.text), " ", op.operator]
      end
    end
  end

  def new(opts \\ []) do
    struct!(__MODULE__, opts)
  end

  def add({doc, contents_obj}, operation) do
    Document.update(doc, contents_obj, fn contents ->
      Map.update!(contents, :operations, fn operations ->
        [operation | operations]
      end)
    end)
  end

  def add({doc, contents_obj}, mod, opts) do
    Document.update(doc, contents_obj, fn contents ->
      Map.update!(contents, :operations, fn operations ->
        [struct!(mod, opts) | operations]
      end)
    end)
  end

  defimpl Mudbrick.Object do
    def from(content_stream) do
      Mudbrick.Stream.new(
        data: [
          "BT\n",
          content_stream.operations
          |> Enum.reverse()
          |> Mudbrick.join("\n"),
          "\nET"
        ]
      )
      |> Mudbrick.Object.from()
    end
  end
end
