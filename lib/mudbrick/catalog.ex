defmodule Mudbrick.Catalog do
  defstruct [:page_tree]

  def new(opts) do
    struct!(__MODULE__, opts)
  end

  defimpl Mudbrick.Object do
    def from(catalog) do
      Mudbrick.Object.from(%{
        Type: :Catalog,
        Pages: catalog.page_tree
      })
    end
  end
end
