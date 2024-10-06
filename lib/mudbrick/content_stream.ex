defmodule Mudbrick.ContentStream do
  @enforce_keys [:page]
  defstruct page: nil, operations: []

  alias Mudbrick.Document

  def new(opts \\ []) do
    struct!(Mudbrick.ContentStream, opts)
  end

  def add({doc, contents_obj}, mod, opts) do
    Document.update(doc, contents_obj, fn contents ->
      Map.update!(contents, :operations, fn ops ->
        ops ++ [struct(mod, opts)]
      end)
    end)
  end

  defimpl Mudbrick.Object do
    def from(stream) do
      inner = """
      BT
      #{Enum.map_join(stream.operations, "\n", &Mudbrick.Object.from/1)}
      ET\
      """

      """
      #{Mudbrick.Object.from(%{Length: byte_size(inner)})}
      stream
      #{inner}
      endstream\
      """
    end
  end

  defmodule Tf do
    defstruct [:font, :size]

    defimpl Mudbrick.Object do
      def from(tf) do
        "#{Mudbrick.Object.from(tf.font)} #{tf.size} Tf"
      end
    end
  end

  defmodule Td do
    defstruct [:tx, :ty]

    defimpl Mudbrick.Object do
      def from(td) do
        "#{td.tx} #{td.ty} Td"
      end
    end
  end

  defmodule Tj do
    defstruct [:text]

    defimpl Mudbrick.Object do
      def from(td) do
        "#{Mudbrick.Object.from(td.text)} Tj"
      end
    end
  end
end
