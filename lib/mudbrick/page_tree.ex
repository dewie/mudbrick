defmodule Mudbrick.PageTree do
  defstruct kids: []

  def new(opts \\ []) do
    struct(Mudbrick.PageTree, opts)
  end

  def add_page_ref(tree, ref) do
    %{tree | kids: tree.kids ++ [ref]}
  end

  defimpl Mudbrick.Object do
    def from(page_tree) do
      Mudbrick.Object.from(%{
        Type: :Pages,
        Kids: page_tree.kids,
        Count: length(page_tree.kids)
      })
    end
  end
end
