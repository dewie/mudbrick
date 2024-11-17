defmodule Mudbrick.Catalog do
  @moduledoc false

  @enforce_keys [:metadata, :page_tree]
  defstruct [:metadata, :page_tree]

  def new(opts) do
    struct!(__MODULE__, opts)
  end

  defimpl Mudbrick.Object do
    def to_iodata(catalog) do
      Mudbrick.Object.to_iodata(%{
        Type: :Catalog,
        Metadata: catalog.metadata.ref,
        Pages: catalog.page_tree.ref
      })
    end
  end
end
