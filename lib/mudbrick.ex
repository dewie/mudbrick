defmodule Mudbrick do
  alias Mudbrick.Document
  alias Mudbrick.Page

  def new do
    Document.new()
  end

  def page(doc, opts \\ []) do
    Page.add(doc, opts)
  end
end
