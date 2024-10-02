defmodule Mudbrick.ContentStream do
  defstruct [:text]

  def new(opts) do
    struct(Mudbrick.ContentStream, opts)
  end
end
