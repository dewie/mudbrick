defmodule Mudbrick.FontTest do
  use ExUnit.Case, async: true

  import TestHelper

  alias Mudbrick.Document
  alias Mudbrick.Font
  alias Mudbrick.Indirect

  test "can set colour on a piece of text" do
    import Mudbrick

    {_doc, content_stream} =
      new()
      |> page(
        fonts: %{
          helvetica: [
            name: :Helvetica,
            type: :TrueType,
            encoding: :PDFDocEncoding
          ]
        }
      )
      |> font(:helvetica, size: 10)
      |> text("black and ")
      |> text(
        """
        red
        text\
        """,
        colour: {1.0, 0.0, 0.0}
      )

    assert show(content_stream) =~
             """
             BT
             /F1 10 Tf
             12.0 TL
             (black and ) Tj
             1.0 0.0 0.0 rg
             (red) Tj
             (text) '
             ET
             """
  end

  test "embedded OTF fonts have a glyph-unicode mapping to enable copy+paste" do
    {doc, _} =
      Mudbrick.new()
      |> Mudbrick.page(fonts: %{bodoni: [file: bodoni()]})

    [_, _page, font | _] = doc.objects

    assert %Font{to_unicode: mapping} = font.value
    assert Document.object_with_ref(doc, mapping.ref)

    assert show(font.value) =~ ~r"/ToUnicode [0-9] 0 R"

    assert %Mudbrick.Font.CMap{} = mapping.value
  end

  test "serialised CMaps conform to standard" do
    parsed = OpenType.new() |> OpenType.parse(bodoni())

    lines =
      Font.CMap.new(parsed: parsed)
      |> show()
      |> String.split("\n")

    assert [
             <<"<</Length ", _::binary>>,
             ">>",
             "stream",
             "/CIDInit /ProcSet findresource begin"
             | _
           ] = lines

    assert "497 beginbfchar" in lines
  end

  test "embedded OTF fonts create descendant, descriptor and file objects" do
    data = bodoni()

    {doc, _} =
      Mudbrick.new()
      |> Mudbrick.page(fonts: %{bodoni: [file: data]})

    [_, _page, font | _] = doc.objects

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

  test "forgetting to set the font is an error" do
    import Mudbrick

    chain =
      new()
      |> page(
        fonts: %{
          helvetica: [
            name: :Helvetica,
            type: :TrueType,
            encoding: :PDFDocEncoding
          ]
        }
      )

    e =
      assert_raise Font.NotSet, fn ->
        chain |> text("hi there")
      end

    assert e.message == "No font chosen"
  end

  test "asking for an unregistered font is an error" do
    import Mudbrick

    chain =
      new()
      |> page(fonts: %{})

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
             |> show() ==
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
             |> show() ==
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
               resource_identifier: :F1,
               to_unicode: Indirect.Ref.new(23) |> Indirect.Object.new(%{})
             }
             |> show() ==
               """
               <</Type /Font
                 /Subtype /Type0
                 /BaseFont /LibreBodoni-Regular
                 /DescendantFonts [22 0 R]
                 /Encoding /Identity-H
                 /ToUnicode 23 0 R
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
             |> show() ==
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
             |> show() ==
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
