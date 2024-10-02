defmodule Mudbrick.Page do
  defstruct [:parent]

  def new do
    new(parent: Mudbrick.Document.page_tree_root_ref())
  end

  def new(parent: parent) do
    %Mudbrick.Page{parent: parent}
  end
end
