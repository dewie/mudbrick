defmodule Mudbrick.ImageTest do
  use ExUnit.Case, async: true

  import Mudbrick
  import Mudbrick.TestHelper

  alias Mudbrick.Document
  alias Mudbrick.Image

  test "embedding an image adds it to the document" do
    data = flower()
    doc = new(images: %{flower: [file: data]})

    expected_image = %Image{
      file: data,
      resource_identifier: :I1,
      width: 500,
      height: 477,
      filter: :DCTDecode,
      bits_per_component: 8
    }

    assert Document.find_object(doc, &(&1 == expected_image))
    assert Document.root_page_tree(doc).value.images[:flower].value == expected_image
  end

  test "PNGs are currently not supported" do
    assert_raise Image.NotSupported, fn ->
      new(images: %{my_png: [file: example_png()]})
    end
  end

  test "specifying :auto height maintains aspect ratio" do
    assert [
             "q",
             "100 0 0 95.4 123 456 cm",
             "/I1 Do",
             "Q"
           ] =
             new(images: %{flower: [file: flower()]})
             |> page()
             |> image(
               :flower,
               position: {123, 456},
               scale: {100, :auto}
             )
             |> operations()
  end

  test "specifying :auto width maintains aspect ratio" do
    assert [
             "q",
             "52.41090146750524 0 0 50 123 456 cm",
             "/I1 Do",
             "Q"
           ] =
             new(images: %{flower: [file: flower()]})
             |> page()
             |> image(
               :flower,
               position: {123, 456},
               scale: {:auto, 50}
             )
             |> operations()
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
             |> image(
               :flower,
               position: {45, 550},
               scale: {100, 100}
             )
             |> operations()
  end

  describe "serialisation" do
    test "produces a JPEG XObject stream" do
      [dictionary, _stream] =
        Image.new(file: flower(), resource_identifier: :I1)
        |> Mudbrick.Object.from()
        |> IO.iodata_to_binary()
        |> String.split("stream", parts: 2)

      assert dictionary ==
               """
               <</Type /XObject
                 /Subtype /Image
                 /BitsPerComponent 8
                 /ColorSpace /DeviceRGB
                 /Filter /DCTDecode
                 /Height 477
                 /Length 36287
                 /Width 500
               >>
               """
    end
  end
end
