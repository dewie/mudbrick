defmodule Mudbrick do
  alias Mudbrick.Document

  def new do
    Document.new()
  end

  def page(doc, opts \\ []) do
    Document.add_page(doc, opts)
  end
end
