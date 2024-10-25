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
