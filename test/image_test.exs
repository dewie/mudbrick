defmodule Mudbrick.ImageTest do
  use ExUnit.Case, async: true

  import Mudbrick
  import TestHelper

  alias Mudbrick.Document
  alias Mudbrick.Image

  test "embedding an image adds it to the document" do
    data = flower()
    doc = new(images: %{flower: [file: data]})

    expected_image = %Image{file: data}

    assert Document.find_object(doc, &match?(^expected_image, &1))
    assert Document.root_page_tree(doc).value.images[:flower].value == expected_image
  end

  describe "serialisation" do
    test "is an XObject stream" do
      assert %Image{file: "some image data"}
             |> show() ==
               """
               <</Type /XObject
                 /Subtype /Image
                 /Length 15
               >>
               stream
               some image data
               endstream\
               """
    end
  end
end
