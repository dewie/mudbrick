defmodule Mudbrick.ContentStream do
  @moduledoc false

  alias Mudbrick.Document

  @enforce_keys [:page]
  defstruct compress: false,
            operations: [],
            page: nil

  defmodule InvalidColour do
    defexception [:message]
  end

  def new(opts \\ []) do
    struct!(__MODULE__, opts)
  end

  def add(context, nil) do
    context
  end

  def add(context, operation) do
    update_operations(context, fn operations ->
      [operation | operations]
    end)
  end

  def add(context, mod, opts) do
    update_operations(context, fn operations ->
      [struct!(mod, opts) | operations]
    end)
  end

  def put(context, fields) do
    update(context, fn contents ->
      struct!(contents, fields)
    end)
  end

  def update_operations(context, f) do
    update(context, fn contents ->
      Map.update!(contents, :operations, f)
    end)
  end

  defp update({doc, contents_obj}, f) do
    Document.update(doc, contents_obj, f)
  end

  defimpl Mudbrick.Object do
    def to_iodata(content_stream) do
      Mudbrick.Stream.new(
        compress: content_stream.compress,
        data: [
          content_stream.operations
          |> Enum.reverse()
          |> Mudbrick.join("\n")
        ]
      )
      |> Mudbrick.Object.to_iodata()
    end
  end
end
