defmodule Mudbrick do
  alias Mudbrick.Document

  def new do
    Document.new()
  end

  def page(doc) do
    doc |> Document.add_page()
  end
end
