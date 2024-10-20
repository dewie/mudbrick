defmodule Mudbrick.PageTree do
  defstruct fonts: %{},
            kids: []

  def new(opts \\ []) do
    struct!(__MODULE__, opts)
  end

  def add_page_ref(tree, ref) do
    %{tree | kids: tree.kids ++ [ref]}
  end

  defimpl Mudbrick.Object do
    def from(page_tree) do
      Mudbrick.Object.from(%{
        Type: :Pages,
        Kids: page_tree.kids,
        Count: length(page_tree.kids),
        Resources: %{
          Font: font_dictionary(page_tree.fonts)
        }
      })
    end

    defp font_dictionary(fonts) do
      for {_human_identifier, object} <- fonts, into: %{} do
        {object.value.resource_identifier, object.ref}
      end
    end
  end
end
