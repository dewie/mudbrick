defmodule Mudbrick do
  alias Mudbrick.Document
  alias Mudbrick.Page

  @page_sizes %{
    a4: {8.3 * 72, 11.7 * 72},
    letter: {8.5 * 72, 11 * 72}
  }

  def new(opts \\ []) do
    opts
    |> Keyword.update(
      :page_size,
      @page_sizes.a4,
      &Map.fetch!(@page_sizes, &1)
    )
    |> Document.new()
  end

  def page(doc, opts \\ []) do
    Page.add(doc, opts)
  end
end
