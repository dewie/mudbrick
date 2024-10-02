defmodule Mudbrick.PageTree do
  defstruct [:kids]

  def new(kids: kids) do
    %Mudbrick.PageTree{kids: kids}
  end

  def add_page_ref(tree, ref) do
    %{tree | kids: tree.kids ++ [ref]}
  end
end
