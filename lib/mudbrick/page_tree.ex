defmodule Mudbrick.PageTree do
  defstruct kids: []

  def new(opts \\ []) do
    struct(Mudbrick.PageTree, opts)
  end

  def add_page_ref(tree, ref) do
    %{tree | kids: tree.kids ++ [ref]}
  end
end
