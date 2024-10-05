defmodule Mudbrick do
  alias Mudbrick.Document
  alias Mudbrick.Page

  @dpi 72

  @page_sizes %{
    a4: {8.3 * @dpi, 11.7 * @dpi},
    letter: {8.5 * @dpi, 11 * @dpi}
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

  def page(a, opts \\ [])

  def page({doc, _page}, opts) do
    Page.add(doc, opts)
  end

  def page(doc, opts) do
    Page.add(doc, opts)
  end

  def render({doc, _page}) do
    to_string(doc)
  end

  def render(doc) do
    to_string(doc)
  end
end
