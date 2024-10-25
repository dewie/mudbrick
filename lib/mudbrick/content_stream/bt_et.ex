defmodule Mudbrick.ContentStream.BT do
  @moduledoc false
  defstruct []

  def open({_doc, content_stream} = context) do
    context
    |> Mudbrick.ContentStream.add(%__MODULE__{})
    |> Mudbrick.ContentStream.add(content_stream.value.current_base_td)
    |> Mudbrick.ContentStream.add(content_stream.value.current_tf)
    |> Mudbrick.ContentStream.add(content_stream.value.current_tl)
  end

  defimpl Mudbrick.Object do
    def from(_), do: ["BT"]
  end
end

defmodule Mudbrick.ContentStream.ET do
  @moduledoc false
  defstruct []

  def remove(context) do
    Mudbrick.ContentStream.update_operations(context, fn [%__MODULE__{} | operations] ->
      operations
    end)
  end

  defimpl Mudbrick.Object do
    def from(_), do: ["ET"]
  end
end
