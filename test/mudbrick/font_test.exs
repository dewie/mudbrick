defmodule Mudbrick.FontTest do
  use ExUnit.Case, async: true

  alias Mudbrick.Document
  alias Mudbrick.Font
  alias Mudbrick.Indirect
  alias Mudbrick.Object

  test "embedded OTF fonts create descendant, descriptor and file objects" do
    data = System.fetch_env!("FONT_LIBRE_BODONI_REGULAR") |> File.read!()

    {doc, _} =
      Mudbrick.new()
      |> Mudbrick.page(
        fonts: %{
          bodoni: [
            encoding: :"Identity-H",
            file: data
          ]
        }
      )

    [_, font | _] = doc.objects

    assert %Font{
             name: :"LibreBodoni-Regular",
             type: :Type0,
             encoding: :"Identity-H",
             descendant: descendant,
             resource_identifier: :F1
           } = font.value

    assert %Font.CIDFont{
             font_name: :"LibreBodoni-Regular",
             descriptor: descriptor,
             type: :CIDFontType0
           } = descendant.value

    assert %Font.Descriptor{
             bounding_box: _bbox,
             file: file,
             font_name: :"LibreBodoni-Regular",
             flags: 4
           } = descriptor.value

    assert %Mudbrick.Stream{
             data: ^data,
             additional_entries: %{
               Length1: 42_952,
               Subtype: :OpenType
             }
           } = file.value

    assert Document.object_with_ref(doc, descendant.ref)
    assert Document.object_with_ref(doc, descriptor.ref)
    assert Document.object_with_ref(doc, file.ref)
  end

  test "asking for an unregistered font is an error" do
    import Mudbrick

    chain =
      new()
      |> page(fonts: %{})
      |> contents()

    e =
      assert_raise Font.Unregistered, fn ->
        chain |> font(:bodoni, 24)
      end

    assert e.message == "Unregistered font: bodoni"
  end

  describe "serialisation" do
    test "without encoding" do
      assert %Font{
               name: :SomeFont,
               type: :TrueType,
               resource_identifier: :F1
             }
             |> Object.from()
             |> to_string() ==
               """
               <</Type /Font
                 /Subtype /TrueType
                 /BaseFont /SomeFont
               >>\
               """
    end

    test "without descendant" do
      assert %Font{
               name: :SomeFont,
               type: :TrueType,
               encoding: :PDFDocEncoding,
               resource_identifier: :F1
             }
             |> Object.from()
             |> to_string() ==
               """
               <</Type /Font
                 /Subtype /TrueType
                 /BaseFont /SomeFont
                 /Encoding /PDFDocEncoding
               >>\
               """
    end

    test "with descendant" do
      assert %Font{
               name: :"LibreBodoni-Regular",
               type: :Type0,
               encoding: :"Identity-H",
               descendant: Indirect.Ref.new(22) |> Indirect.Object.new(%{}),
               resource_identifier: :F1
             }
             |> Object.from()
             |> to_string() ==
               """
               <</Type /Font
                 /Subtype /Type0
                 /BaseFont /LibreBodoni-Regular
                 /DescendantFonts [22 0 R]
                 /Encoding /Identity-H
               >>\
               """
    end

    test "CID font" do
      assert %Font.CIDFont{
               font_name: :"LibreBodoni-Regular",
               descriptor: Indirect.Ref.new(666) |> Indirect.Object.new(%{}),
               type: :CIDFontType0,
               default_width: 1000,
               widths: [0, 1, 2]
             }
             |> Object.from()
             |> to_string() ==
               """
               <</Type /Font
                 /Subtype /CIDFontType0
                 /BaseFont /LibreBodoni-Regular
                 /CIDSystemInfo <</Ordering (Identity)
                 /Registry (Adobe)
                 /Supplement 0
               >>
                 /DW 1000
                 /FontDescriptor 666 0 R
                 /W [0 [0 1 2]]
               >>\
               """
    end

    test "descriptor" do
      assert %Font.Descriptor{
               ascent: 928,
               bounding_box: [1, 1, 1, 1],
               cap_height: 1000,
               descent: 111,
               font_name: :"LibreBodoni-Regular",
               flags: 4,
               file: Indirect.Ref.new(99) |> Indirect.Object.new(%{}),
               italic_angle: 0.0,
               stem_vertical: 80
             }
             |> Object.from()
             |> to_string() ==
               """
               <</Type /FontDescriptor
                 /Ascent 928
                 /CapHeight 1000
                 /Descent 111
                 /Flags 4
                 /FontBBox [1 1 1 1]
                 /FontFile3 99 0 R
                 /FontName /LibreBodoni-Regular
                 /ItalicAngle 0.0
                 /StemV 80
               >>\
               """
    end
  end
end
