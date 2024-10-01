defmodule Mudbrick.Catalog do
  defstruct [:page_tree]

  def new(page_tree: page_tree) do
    %Mudbrick.Catalog{page_tree: page_tree}
  end
end
