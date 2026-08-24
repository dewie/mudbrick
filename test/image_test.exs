defmodule Mudbrick.ImageTest do
  use ExUnit.Case, async: true

  import Mudbrick
  import Mudbrick.TestHelper

  alias Mudbrick.Document
  alias Mudbrick.Image
  alias Mudbrick.Images.Png

  describe "JPEGs" do
    test "embedding an image adds it to the document" do
      data = flower()
      doc = new(images: %{flower: data})

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

    test "serialise to a JPEG XObject stream" do
      assert dictionary(Image.new(file: flower(), resource_identifier: :I1)) ==
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

    test "a greyscale JPEG is declared as DeviceGray" do
      file = build_jpeg(width: 3, height: 2, components: 1)

      assert dictionary(Image.new(file: file, resource_identifier: :I1)) =~
               "/ColorSpace /DeviceGray"
    end

    # Declaring a CMYK JPEG as RGB makes the reader consume three samples per
    # pixel out of four, which shears the image diagonally and drains its colour.
    test "a CMYK JPEG is declared as DeviceCMYK" do
      file = build_jpeg(width: 3, height: 2, components: 4)
      dict = dictionary(Image.new(file: file, resource_identifier: :I1))

      assert dict =~ "/ColorSpace /DeviceCMYK"
      refute dict =~ "/Decode"
    end

    test "an Adobe CMYK JPEG has its inverted samples decoded back" do
      file = build_jpeg(width: 3, height: 2, components: 4, adobe: true)
      dict = dictionary(Image.new(file: file, resource_identifier: :I1))

      assert dict =~ "/ColorSpace /DeviceCMYK"
      assert dict =~ "/Decode [1 0 1 0 1 0 1 0]"
    end

    test "an Adobe RGB JPEG is not inverted" do
      file = build_jpeg(width: 3, height: 2, components: 3, adobe: true)
      dict = dictionary(Image.new(file: file, resource_identifier: :I1))

      assert dict =~ "/ColorSpace /DeviceRGB"
      refute dict =~ "/Decode"
    end

    # APPn segments may legally follow the frame header, so the walk can't stop
    # at SOF: doing so leaves a CMYK image without its /Decode, i.e. inverted.
    test "an Adobe marker after the frame header is still found" do
      file = build_jpeg(width: 3, height: 2, components: 4, adobe: :after_sof)

      assert dictionary(Image.new(file: file, resource_identifier: :I1)) =~
               "/Decode [1 0 1 0 1 0 1 0]"
    end

    # ExImageInfo reads dimensions from the first seven payload bytes without
    # checking that the declared length fits, so a file it accepts may still
    # have a frame header running past the end.
    test "a truncated frame header is read rather than guessed" do
      file = build_jpeg(width: 3, height: 2, components: 4, adobe: true)
      # Cuts into the component specifications, past the component count.
      truncated = binary_part(file, 0, byte_size(file) - 21)

      assert dictionary(Image.new(file: truncated, resource_identifier: :I1)) =~
               "/ColorSpace /DeviceCMYK"
    end

    test "a progressive JPEG's frame header is read too" do
      file = build_jpeg(width: 3, height: 2, components: 1, sof: 0xC2)

      assert dictionary(Image.new(file: file, resource_identifier: :I1)) =~
               "/ColorSpace /DeviceGray"
    end

    test "raises rather than guess a colour space for an unexpected component count" do
      file = build_jpeg(width: 3, height: 2, components: 2)

      assert_raise Image.NotSupported,
                   "Unsupported number of JPEG colour components: 2",
                   fn -> Image.new(file: file, resource_identifier: :I1) end
    end

    # Photoshop and Illustrator store a full JPEG thumbnail inside APP13/APP1.
    # Scanning for frame-header bytes instead of walking segment lengths would
    # pick up the thumbnail's component count.
    test "an embedded thumbnail does not decide the colour space" do
      thumbnail = build_jpeg(width: 2, height: 2, components: 3)
      file = build_jpeg(width: 3, height: 2, components: 4, adobe: true, app13: thumbnail)

      assert dictionary(Image.new(file: file, resource_identifier: :I1)) =~
               "/ColorSpace /DeviceCMYK"
    end
  end

  describe "placement" do
    test "specifying :auto height maintains aspect ratio" do
      assert [
               "q",
               "100 0 0 95.4 123 456 cm",
               "/I1 Do",
               "Q"
             ] =
               new(images: %{flower: flower()})
               |> page()
               |> image(:flower, position: {123, 456}, scale: {100, :auto})
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
               |> image(:flower, position: {123, 456}, scale: {:auto, 50})
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
               |> image(:flower, position: {45, 550}, scale: {100, 100})
               |> operations()
    end

    test "a PNG can be placed just like a JPEG" do
      assert [
               "q",
               "100 0 0 75 0 0 cm",
               "/I1 Do",
               "Q"
             ] =
               new(images: %{drawing: example_png()})
               |> page()
               |> image(:drawing, position: {0, 0}, scale: {100, 75})
               |> operations()
    end
  end

  describe "PNG decoding" do
    test "reads dimensions, colour type and bit depth from a truecolour PNG" do
      png = Png.new(file: read_fixture("truecolour.png"), resource_identifier: :I1)

      assert png.colour_type == 2
      assert png.width == 100
      assert png.height == 75
      assert png.bits_per_component == 8
      assert png.palette == nil
      assert png.alpha == nil
    end

    test "reads a palette from an indexed PNG" do
      png = Png.new(file: example_png(), resource_identifier: :I1)

      assert png.colour_type == 3
      # RGB entries, 3 bytes each
      assert rem(byte_size(png.palette), 3) == 0
      assert png.alpha == nil
    end

    test "extracts an alpha channel from a truecolour + alpha PNG" do
      png = Png.new(file: read_fixture("truecolour-alpha.png"), resource_identifier: :I1)

      assert png.colour_type == 6
      # one alpha byte per pixel
      assert byte_size(png.alpha) == png.width * png.height
    end

    test "extracts an alpha channel from a greyscale + alpha PNG" do
      png = Png.new(file: read_fixture("grayscale-alpha.png"), resource_identifier: :I1)

      assert png.colour_type == 4
      assert byte_size(png.alpha) == png.width * png.height
    end

    test "maps a tRNS chunk to per-pixel alpha for an indexed PNG" do
      # 2x2 image, pixels indexing palette entries 0, 1, 2, 0.
      # tRNS gives index 0 alpha 0 and index 1 alpha 128; index 2 defaults to opaque.
      file =
        build_png(
          width: 2,
          height: 2,
          colour_type: 3,
          palette: <<0, 0, 0, 1, 1, 1, 2, 2, 2>>,
          transparency: <<0, 128>>,
          scanlines: [<<0, 1>>, <<2, 0>>]
        )

      png = Png.new(file: file, resource_identifier: :I1)

      assert png.alpha == <<0, 128, 255, 0>>
    end

    test "raises for interlaced PNGs" do
      file = build_png(width: 1, height: 1, colour_type: 0, interlace: 1, scanlines: [<<0>>])

      assert_raise Image.NotSupported, "Interlaced PNGs are not supported", fn ->
        Png.new(file: file, resource_identifier: :I1)
      end
    end

    test "raises for unsupported PNG colour types" do
      file = build_png(width: 1, height: 1, colour_type: 99, scanlines: [<<0>>])

      assert_raise Image.NotSupported, "Unsupported PNG colour type: 99", fn ->
        Png.new(file: file, resource_identifier: :I1)
      end
    end

    test "maps a tRNS chunk to per-pixel alpha for a 4-bit indexed PNG" do
      # 3x2 image, pixel indices 0, 1, 2 / 2, 1, 0, packed two per byte.
      file =
        build_png(
          width: 3,
          height: 2,
          colour_type: 3,
          bits: 4,
          palette: <<0, 0, 0, 1, 1, 1, 2, 2, 2>>,
          transparency: <<0, 128>>,
          scanlines: [<<0x01, 0x20>>, <<0x21, 0x00>>]
        )

      png = Png.new(file: file, resource_identifier: :I1)

      assert png.bits_per_component == 4
      assert png.alpha == <<0, 128, 255, 255, 128, 0>>
    end

    test "maps a tRNS chunk to per-pixel alpha for a 1-bit indexed PNG" do
      # 3x2 image: each packed row is a single byte carrying 3 index bits and 5
      # padding bits. Rows are 0, 1, 1 and 1, 0, 1.
      file =
        build_png(
          width: 3,
          height: 2,
          colour_type: 3,
          bits: 1,
          palette: <<0, 0, 0, 255, 255, 255>>,
          transparency: <<0>>,
          scanlines: [<<0b01100000>>, <<0b10100000>>]
        )

      png = Png.new(file: file, resource_identifier: :I1)

      assert png.bits_per_component == 1
      assert png.alpha == <<0, 255, 255, 255, 0, 255>>
    end

    test "maps a tRNS chunk to per-pixel alpha for a 2-bit indexed PNG" do
      # 3x1 image, indices 0, 1, 3; index 3 is beyond the tRNS table, so opaque.
      file =
        build_png(
          width: 3,
          height: 1,
          colour_type: 3,
          bits: 2,
          palette: <<0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3>>,
          transparency: <<0, 64, 128>>,
          scanlines: [<<0b00011100>>]
        )

      png = Png.new(file: file, resource_identifier: :I1)

      assert png.alpha == <<0, 64, 255>>
    end

    test "raises for unrecognised image formats" do
      assert_raise Image.NotSupported, fn ->
        new(images: %{mystery: <<"GIF89a", 0, 0, 0>>})
      end
    end
  end

  describe "PNG serialisation" do
    test "a truecolour PNG becomes a FlateDecode XObject with a predictor" do
      png =
        Png.new(file: read_fixture("truecolour.png"), resource_identifier: :I1)
        |> Png.put_dictionary()

      assert dictionary(png) ==
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

    test "a greyscale PNG declares its predictor so filtering is undone" do
      png =
        Png.new(file: read_fixture("grayscale.png"), resource_identifier: :I1)
        |> Png.put_dictionary()

      dict = dictionary(png)
      assert dict =~ "/ColorSpace /DeviceGray"
      # The predictor is essential: without it the reader treats PNG filter
      # bytes as pixel data and the image is corrupted.
      assert dict =~
               "/DecodeParms <</BitsPerComponent 8\n  /Colors 1\n  /Columns 100\n  /Predictor 15\n>>"
    end
  end

  describe "PNG embedding" do
    test "an indexed PNG embeds its palette as a referenced object" do
      png = Png.new(file: example_png(), resource_identifier: :I1)
      doc = new(images: %{drawing: example_png()})

      image = Document.find_object(doc, &match?(%Png{}, &1))
      [:Indexed, :DeviceRGB, hival, palette_ref] = image.value.dictionary[:ColorSpace]

      assert hival == div(byte_size(png.palette), 3) - 1

      palette = Document.object_with_ref(doc, palette_ref)
      assert palette.value.data == png.palette
    end

    test "an alpha PNG embeds a greyscale soft mask referenced from the image" do
      png = Png.new(file: read_fixture("truecolour-alpha.png"), resource_identifier: :I1)
      doc = new(images: %{flower: read_fixture("truecolour-alpha.png")})

      image = Document.find_object(doc, &match?(%Png{}, &1))
      smask_ref = image.value.dictionary[:SMask]

      # The colour data was re-compressed without PNG filtering, so it must not
      # advertise a predictor.
      refute Map.has_key?(image.value.dictionary, :DecodeParms)

      smask = Document.object_with_ref(doc, smask_ref).value
      entries = smask.additional_entries
      assert entries[:ColorSpace] == :DeviceGray
      assert entries[:Width] == png.width
      assert entries[:Height] == png.height
      assert IO.iodata_to_binary(Mudbrick.decompress(smask.data)) == png.alpha
    end

    test "a 1-bit indexed transparent PNG keeps its bit depth and gains a soft mask" do
      file =
        build_png(
          width: 3,
          height: 2,
          colour_type: 3,
          bits: 1,
          palette: <<0, 0, 0, 255, 255, 255>>,
          transparency: <<0>>,
          scanlines: [<<0b01100000>>, <<0b10100000>>]
        )

      doc = new(images: %{tiny: file})

      image = Document.find_object(doc, &match?(%Png{}, &1))
      dictionary = image.value.dictionary

      assert dictionary[:BitsPerComponent] == 1

      assert dictionary[:DecodeParms] == %{
               Predictor: 15,
               Colors: 1,
               BitsPerComponent: 1,
               Columns: 3
             }

      assert [:Indexed, :DeviceRGB, 1, _palette_ref] = dictionary[:ColorSpace]

      smask = Document.object_with_ref(doc, dictionary[:SMask]).value
      assert smask.additional_entries[:BitsPerComponent] == 8
      # Too small to benefit from compression, so the alpha is stored as-is.
      assert smask.data == <<0, 255, 255, 255, 0, 255>>
    end
  end

  defp dictionary(image) do
    [dictionary, _stream] =
      image
      |> Mudbrick.Object.to_iodata()
      |> IO.iodata_to_binary()
      |> String.split("stream", parts: 2)

    dictionary
  end

  defp read_fixture(name) do
    Path.join([__DIR__, "fixtures", name]) |> File.read!()
  end

  # Assembles a JPEG with just the header segments that decide the colour space,
  # so CMYK and greyscale can be covered without checking in binaries.
  defp build_jpeg(opts) do
    components = opts[:components]

    sof =
      <<8, opts[:height]::16, opts[:width]::16, components>> <>
        for id <- 1..components, into: <<>>, do: <<id, 0x11, 0>>

    # "Adobe" + version, two flag fields and the colour transform.
    app14 = marker_segment(0xEE, "Adobe" <> <<0, 100, 128, 0, 0, 0, 0>>)
    app13 = if opts[:app13], do: [marker_segment(0xED, opts[:app13])], else: []

    IO.iodata_to_binary([
      <<0xFF, 0xD8>>,
      marker_segment(0xE0, "JFIF" <> <<0, 1, 2, 0, 0, 1, 0, 1, 0, 0>>),
      app13,
      if(opts[:adobe] == true, do: [app14], else: []),
      marker_segment(opts[:sof] || 0xC0, sof),
      if(opts[:adobe] == :after_sof, do: [app14], else: []),
      # A start-of-scan with no entropy-coded data; enough to end the headers.
      marker_segment(0xDA, <<1, 1, 0, 0, 63, 0>>),
      <<0xFF, 0xD9>>
    ])
  end

  defp marker_segment(marker, payload) do
    [<<0xFF, marker, byte_size(payload) + 2::16>>, payload]
  end

  # Assembles a minimal, valid PNG so transparency handling can be tested with
  # known pixel values instead of a checked-in binary.
  defp build_png(opts) do
    ihdr =
      <<opts[:width]::32, opts[:height]::32, opts[:bits] || 8, opts[:colour_type], 0, 0,
        opts[:interlace] || 0>>

    # Each PNG scanline is prefixed with a filter-type byte (0 = no filtering).
    filtered = Enum.map(opts[:scanlines], fn row -> <<0>> <> IO.iodata_to_binary([row]) end)
    idat = :zlib.compress(IO.iodata_to_binary(filtered))

    chunks =
      [chunk("IHDR", ihdr)] ++
        palette_chunk(opts[:palette]) ++
        transparency_chunk(opts[:transparency]) ++
        [chunk("IDAT", idat), chunk("IEND", "")]

    <<137, 80, 78, 71, 13, 10, 26, 10>> <> IO.iodata_to_binary(chunks)
  end

  defp palette_chunk(nil), do: []
  defp palette_chunk(palette), do: [chunk("PLTE", palette)]

  defp transparency_chunk(nil), do: []
  defp transparency_chunk(transparency), do: [chunk("tRNS", transparency)]

  defp chunk(type, data) do
    <<byte_size(data)::32>> <> type <> data <> <<:erlang.crc32(type <> data)::32>>
  end
end
