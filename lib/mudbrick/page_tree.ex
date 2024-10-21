defmodule Mudbrick.PageTree do
  @moduledoc false

  defstruct fonts: %{},
            images: %{},
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
          Font: resource_dictionary(page_tree.fonts),
          XObject: resource_dictionary(page_tree.images)
        }
      })
    end

    defp resource_dictionary(resources) do
      for {_human_identifier, object} <- resources, into: %{} do
        {object.value.resource_identifier, object.ref}
      end
    end
  end
end
