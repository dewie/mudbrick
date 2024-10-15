defmodule Mudbrick.ContentStream do
  @enforce_keys [:page]
  defstruct page: nil, text_objects: []

  alias Mudbrick.ContentStream.TextObject
  alias Mudbrick.Document

  defmodule Rg do
    defstruct [:r, :g, :b]

    defimpl Mudbrick.Object do
      def from(%Rg{r: r, g: g, b: b}) do
        ["#{r} #{g} #{b} rg"]
      end
    end
  end

  defmodule QPush do
    defstruct []

    defimpl Mudbrick.Object do
      def from(_), do: ["q"]
    end
  end

  defmodule QPop do
    defstruct []

    defimpl Mudbrick.Object do
      def from(_), do: ["Q"]
    end
  end

  def new(opts \\ []) do
    struct!(__MODULE__, opts)
  end

  def add({doc, contents_obj}, operation) do
    Document.update(doc, contents_obj, fn contents ->
      Map.update!(contents, :text_objects, fn
        [] ->
          [TextObject.new(operations: [operation])]

        [object] ->
          [Map.update!(object, :operations, &[operation | &1])]
      end)
    end)
  end

  def add(context, mod, opts) do
    add(context, struct!(mod, opts))
  end

  defimpl Mudbrick.Object do
    def from(content_stream) do
      Mudbrick.Object.from(
        Mudbrick.Stream.new(
          data: Enum.map_join(content_stream.text_objects, "\n", &Mudbrick.Object.from/1)
        )
      )
    end
  end
end
