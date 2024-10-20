defmodule Mudbrick.ImageTest do
  use ExUnit.Case, async: true

  import Mudbrick
  import TestHelper

  alias Mudbrick.Document
  alias Mudbrick.Image

  test "embedding an image adds it to the document" do
    data = flower()
    doc = new(images: %{flower: [file: data]})

    expected_image = %Image{file: data, resource_identifier: :I1}

    assert Document.find_object(doc, &match?(^expected_image, &1))
    assert Document.root_page_tree(doc).value.images[:flower].value == expected_image
  end

  test "asking for a registered image produces an isolated cm/Do operation" do
    assert [
             "q",
             "100 0 0 100 45 550 cm",
             "/I1 Do",
             "Q"
           ] =
             new(images: %{flower: [file: flower()]})
             |> page()
             |> image(:flower)
             |> operations()
  end

  test "asking for an unregistered image is an error" do
    chain =
      new(images: %{})
      |> page()

    e =
      assert_raise Image.Unregistered, fn ->
        chain |> image(:flower)
      end

    assert e.message == "Unregistered image: flower"
  end

  describe "serialisation" do
    test "is an XObject stream" do
      assert %Image{file: "some image data", resource_identifier: :I1}
             |> show() ==
               """
               <</Type /XObject
                 /Subtype /Image
                 /BitsPerComponent 8
                 /ColorSpace /DeviceRGB
                 /Filter /DCTDecode
                 /Height 477
                 /Length 15
                 /Width 500
               >>
               stream
               some image data
               endstream\
               """
    end
  end
end
