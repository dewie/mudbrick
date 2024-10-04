defmodule Mudbrick.Page do
  defstruct [:parent, :contents_reference, :font_reference]

  def new(opts \\ []) do
    struct(
      Mudbrick.Page,
      Keyword.put_new(opts, :parent, Mudbrick.Document.page_tree_root_ref())
    )
  end
end
