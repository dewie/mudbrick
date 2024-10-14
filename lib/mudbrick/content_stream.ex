defmodule Mudbrick.ContentStream do
  @enforce_keys [:page]
  defstruct page: nil, operations: []

  alias Mudbrick.Document

  defmodule Tf do
    defstruct [:font, :size]

    defimpl Mudbrick.Object do
      def from(tf) do
        [Mudbrick.Object.from(tf.font.resource_identifier), " ", to_string(tf.size), " Tf"]
      end
    end
  end

  defmodule Td do
    defstruct [:tx, :ty]

    defimpl Mudbrick.Object do
      def from(td) do
        [td.tx, td.ty, "Td"] |> Enum.map(&to_string/1) |> Enum.intersperse(" ")
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

    defimpl Mudbrick.Object do
      def from(tj) do
        if tj.font do
          {glyph_ids_decimal, _positions} =
            tj.font.parsed
            |> OpenType.layout_text(tj.text)

          glyph_ids_hex =
            glyph_ids_decimal
            |> Enum.map(fn id ->
              id
              |> Integer.to_string(16)
              |> String.pad_leading(4, "0")
            end)

          ["<", glyph_ids_hex, "> #{tj.operator}"]
        else
          [Mudbrick.Object.from(tj.text), " #{tj.operator}"]
        end
      end
    end
  end

  defmodule Ts do
    defstruct [:rise]

    defimpl Mudbrick.Object do
      def from(ts) do
        [Mudbrick.Object.from(ts.rise), " Ts"]
      end
    end
  end

  def new(opts \\ []) do
    struct!(Mudbrick.ContentStream, opts)
  end

  def add({doc, contents_obj}, mod, opts) do
    Document.update(doc, contents_obj, fn contents ->
      Map.update!(contents, :operations, fn ops ->
        [struct(mod, opts) | ops]
      end)
    end)
  end

  defimpl Mudbrick.Object do
    def from(stream) do
      inner = [
        "BT\n",
        Enum.map_join(Enum.reverse(stream.operations), "\n", &Mudbrick.Object.from/1),
        "\nET"
      ]

      [
        Mudbrick.Object.from(%{Length: :erlang.iolist_size(inner)}),
        "\nstream\n",
        inner,
        "\nendstream"
      ]
    end
  end
end
