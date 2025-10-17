defmodule Mudbrick.ImageTest do
  use ExUnit.Case, async: true

  import Mudbrick
  import Mudbrick.TestHelper

  alias Mudbrick.Document
  alias Mudbrick.{Image, Images.Jpeg, Images.Png}

  test "embedding an image adds it to the document" do
    data = flower()
    doc = new(images: %{flower: data})

    expected_image = %Mudbrick.Images.Jpeg{
      resource_identifier: :I1,
      size: 36287,
      color_type: 3,
      width: 500,
      height: 477,
      bits_per_component: 8,
      file: nil,
      additional_objects: [],
      dictionary: %{BitsPerComponent: 8, ColorSpace: :DeviceRGB, Filter: :DCTDecode, Height: 477, Length: 36287, Subtype: :Image, Type: :XObject, Width: 500},
      image_data: data
    }


    assert Document.find_object(doc, &(&1 == expected_image))
    assert Document.root_page_tree(doc).value.images[:flower].value == expected_image
  end


  test "specifying :auto height maintains aspect ratio" do
    assert [
             "q",
             "100 0 0 95.4 123 456 cm",
             "/I1 Do",
             "Q"
           ] =
             new(images: %{flower: flower()})
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
             new(images: %{flower: flower()})
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
             new(images: %{flower: flower()})
             |> page()
             |> image(
               :flower,
               position: {45, 550},
               scale: {100, 100}
             )
             |> operations()
  end

  describe "serialisation jpg" do
    test "produces a JPEG XObject stream using the old image module" do
      [dictionary, _stream] =
        Image.new(file: flower(), resource_identifier: :I1)
        |> Mudbrick.Object.to_iodata()
        |> IO.iodata_to_binary()
        |> String.split("stream", parts: 2)

      IO.puts(dictionary)

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

    test "produces a JPEG XObject stream using the new Images.Jpeg module" do
      [dictionary, _stream] =
        Mudbrick.Images.Jpeg.new(file: flower(), resource_identifier: :I1)
        |> tap(fn x -> IO.inspect(x) end)
        |> Mudbrick.Object.to_iodata()
        |> tap(fn x -> IO.inspect(x) end)
        |> IO.iodata_to_binary()
        |> String.split("stream", parts: 2)

      IO.inspect(dictionary)

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


  describe "serialisation png" do
    test "produces a PNG XObject for a truecolour png" do


      [dictionary, _stream] =
        Mudbrick.Images.Png.new(file: File.read!(Path.join(__DIR__, "fixtures/truecolour.png")), resource_identifier: :I1)
        |> Mudbrick.Object.to_iodata()
        |> IO.iodata_to_binary()
        |> String.split("stream", parts: 2)

      IO.puts dictionary

      assert dictionary ==
                """
                <</Type /XObject
                    /Subtype /Image
                    /BitsPerComponent 8
                    /ColorSpace /DeviceRGB
                    /DecodeParms <</BitsPerComponent 8
                    /Colors 3
                    /Columns 100
                    /Predictor 15
                  >>
                    /Filter /FlateDecode
                    /Height 75
                    /Length 16689
                    /Width 100
                >>
                  """
    end

    test "produces a PNG XObject for a truecolour-alpha png" do


      [dictionary, _stream] =
        Mudbrick.Images.Png.new(file: File.read!(Path.join(__DIR__, "fixtures/truecolour-alpha.png")), resource_identifier: :I1)
        |> Mudbrick.Object.to_iodata()
        |> IO.iodata_to_binary()
        |> String.split("stream", parts: 2)

      IO.puts dictionary

      assert dictionary ==
                """
                <</Type /XObject
                    /Subtype /Image
                    /BitsPerComponent 8
                    /ColorSpace /DeviceRGB
                    /DecodeParms <</BitsPerComponent 8
                    /Colors 3
                    /Columns 100
                    /Predictor 15
                  >>
                    /Filter /FlateDecode
                    /Height 75
                    /Length 15961
                    /Width 100
                >>
                  """
    end

  end


  describe "Pdf creation" do
    test "creates a pdf with jpg " do

      new(
        # flate compression for fonts, text etc.
        compress: true,
        # register an OTF font
        fonts: %{bodoni: bodoni_regular()},
        # register a JPEG
        images: %{flower: File.read!(Path.join(__DIR__, "fixtures/cmyk.jpg"))}
      )
      |> page(size: {100, 100})
      # place preregistered JPEG
      |> image(
        :flower,
        # full page size
        scale: {100, 100},
        # in points (1/72 inch), starts at bottom left
        position: {0, 0}
      )
      |> render()
      |> then(&File.write(Path.join(__DIR__, "output/JPEG_example_flower.pdf"), &1))
    end

    test "creates a pdf with truecolour png " do

      new(
        # flate compression for fonts, text etc.
        compress: true,
        # register an OTF font
        fonts: %{bodoni: bodoni_regular()},
        # register a JPEG
        images: %{flower: File.read!(Path.join(__DIR__, "fixtures/truecolour.png"))}
      )
      |> page(size: Mudbrick.Page.size(:a4))
      # place preregistered JPEG
      |> image(
        :flower,
        # full page size

        # in points (1/72 inch), starts at bottom left
        position: {0, 0}
      )
      |> render()
      |> then(&File.write(Path.join(__DIR__, "output/truecolour.pdf"), &1))
    end

    test "creates a pdf with truecolour-alpha png " do
      new(
        # flate compression for fonts, text etc.
        compress: true,
        # register an OTF font
        fonts: %{bodoni: bodoni_regular()},
        # register a JPEG
        images: %{flower: File.read!(Path.join(__DIR__, "fixtures/truecolour-alpha.png"))}
      )
      |> page(size: Mudbrick.Page.size(:a4))
      |> image(
        :flower,
        position: {0, 0}
      )
      |> render()
      |> then(&File.write(Path.join(__DIR__, "output/truecolour-alpha.pdf"), &1))
    end

    test "creates a pdf with indexed png " do
      new(
        # flate compression for fonts, text etc.
        compress: true,
        # register an OTF font
        fonts: %{bodoni: bodoni_regular()},
        # register a JPEG
        images: %{flower: File.read!(Path.join(__DIR__, "fixtures/indexed.png"))}
      )
      |> page(size: Mudbrick.Page.size(:a4))
      |> image(
        :flower,
        position: {0, 0}
      )
      |> render()
      |> then(&File.write(Path.join(__DIR__, "output/indexed.pdf"), &1))
    end

    test "creates a pdf with png_trans png " do
      new(
        # flate compression for fonts, text etc.
        compress: true,
        # register an OTF font
        #fonts: %{bodoni: bodoni_regular()},
        # register a JPEG
        images: %{flower: File.read!(Path.join(__DIR__, "fixtures/png_trans.png"))}
      )
      |> page(size: Mudbrick.Page.size(:a4))
      |> image(
        :flower,
        position: {10, 10}
      )
      |> render()
      |> then(&File.write(Path.join(__DIR__, "output/png_trans.pdf"), &1))
    end


  end
end
