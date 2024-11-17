defmodule Mudbrick.ContentStream.Td do
  @moduledoc false
  defstruct tx: 0,
            ty: 0,
            purpose: nil

  def add_current({_doc, content_stream} = context) do
    Mudbrick.ContentStream.add(context, content_stream.value.current_base_td)
  end

  def most_recent(content_stream) do
    Enum.find(content_stream.value.operations, &match?(%__MODULE__{}, &1))
  end

  defimpl Mudbrick.Object do
    def to_iodata(td) do
      [td.tx, td.ty, "Td"]
      |> Enum.map(&to_string/1)
      |> Enum.intersperse(" ")
    end
  end
end
