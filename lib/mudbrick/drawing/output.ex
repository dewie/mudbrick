defmodule Mudbrick.Drawing.Output do
  defstruct operations: []

  def from(_) do
    %__MODULE__{}
  end
end
