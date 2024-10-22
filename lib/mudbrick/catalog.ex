defmodule Mudbrick.Catalog do
  @moduledoc false

  @enforce_keys [:metadata, :page_tree]
  defstruct [:metadata, :page_tree]

  def new(opts) do
    struct!(__MODULE__, opts)
  end

  defimpl Mudbrick.Object do
    def from(catalog) do
      Mudbrick.Object.from(%{
        Type: :Catalog,
        Metadata: catalog.metadata.ref,
        Pages: catalog.page_tree.ref
      })
    end
  end
end
