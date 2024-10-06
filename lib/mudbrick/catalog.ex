defmodule Mudbrick.Catalog do
  defstruct [:page_tree]

  def new(page_tree: page_tree) do
    %Mudbrick.Catalog{page_tree: page_tree}
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
