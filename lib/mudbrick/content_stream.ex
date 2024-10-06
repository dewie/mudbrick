defmodule Mudbrick.ContentStream do
  @enforce_keys [:page]
  defstruct page: nil, operations: []

  alias Mudbrick.Document

  @subscripts %{
    "₀" => "0",
    "₁" => "1",
    "₂" => "2",
    "₃" => "3",
    "₄" => "4",
    "₅" => "5",
    "₆" => "6",
    "₇" => "7",
    "₈" => "8",
    "₉" => "9"
  }

  @subscript_pattern Regex.compile!("(#{@subscripts |> Map.keys() |> Enum.join("|")})")

  defmodule Tf do
    defstruct [:font, :size]

    defimpl Mudbrick.Object do
      def from(tf) do
        [Mudbrick.Object.from(tf.font), " ", to_string(tf.size), " Tf"]
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

  defmodule Tj do
    defstruct [:text]

    defimpl Mudbrick.Object do
      def from(td) do
        [Mudbrick.Object.from(td.text), " Tj"]
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

  def add({doc, contents_obj}, Tj, opts) do
    Document.update(doc, contents_obj, fn contents ->
      Map.update!(contents, :operations, fn ops ->
        replace_subscript(ops, opts[:text])
      end)
    end)
  end

  def add({doc, contents_obj}, mod, opts) do
    Document.update(doc, contents_obj, fn contents ->
      Map.update!(contents, :operations, fn ops ->
        ops ++ [struct(mod, opts)]
      end)
    end)
  end

  defp replace_subscript(ops, text) do
    case String.split(text, @subscript_pattern, parts: 2, include_captures: true) do
      [text] ->
        ops ++ [%Tj{text: text}]

      [pre, subscript_char, post] ->
        equivalent_regular_char = Map.fetch!(@subscripts, subscript_char)

        (ops ++
           [%Tj{text: pre}] ++
           subscript(current_font(ops), equivalent_regular_char))
        |> replace_subscript(post)
    end
  end

  defp subscript(font, text) do
    [
      %Ts{rise: -(font.size * 0.25)},
      %Tf{font | size: font.size / 3 * 2},
      %Tj{text: text},
      font,
      %Ts{rise: 0}
    ]
  end

  defp current_font(ops) do
    ops
    |> Enum.reverse()
    |> Enum.find(fn
      %Tf{} -> true
      _ -> false
    end)
  end

  defimpl Mudbrick.Object do
    def from(stream) do
      inner = [
        "BT\n",
        Enum.map_join(stream.operations, "\n", &Mudbrick.Object.from/1),
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
