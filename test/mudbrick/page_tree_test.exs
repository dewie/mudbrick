defmodule Mudbrick.PageTreeTest do
  use ExUnit.Case, async: true

  import Mudbrick.TestHelper

  alias Mudbrick.Document

  test "is a dictionary of pages, fonts and images" do
    doc =
      Mudbrick.new(
        fonts: %{bodoni: [file: bodoni()]},
        images: %{flower: [file: flower()]}
      )

    assert doc |> Document.root_page_tree() |> show() ==
             """
             7 0 obj
             <</Type /Pages
               /Count 0
               /Kids []
               /Resources <</Font <</F1 5 0 R
             >>
               /XObject <</I1 6 0 R
             >>
             >>
             >>
             endobj\
             """
  end
end
