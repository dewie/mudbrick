defmodule Mudbrick.FontTest do
  use ExUnit.Case, async: true

  alias OpenType.Font
  alias Mudbrick.Document
  alias Mudbrick.Font
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

    assert %Font.Descendant{
             font_name: :"LibreBodoni-Regular",
             descriptor: descriptor,
             type: :CIDFontType0
           } = descendant.value

    assert %Font.Descriptor{
             file: file,
             font_name: :"LibreBodoni-Regular"
           } = descriptor.value

    assert %Mudbrick.Stream{
             data: ^data
           } = file.value

    assert Document.object_with_ref(doc, descendant.ref)
    assert Document.object_with_ref(doc, descriptor.ref)
    assert Document.object_with_ref(doc, file.ref)
  end

  describe "serialisation" do
    test "font" do
      assert %Font{
               name: :"LibreBodoni-Regular",
               type: :Type0,
               encoding: :"Identity-H",
               descendant: %{},
               resource_identifier: :F1
             }
             |> Object.from()
             |> to_string() ==
               """
               <</Type /Font
                 /Subtype /Type0
                 /BaseFont /LibreBodoni-Regular
                 /Encoding /Identity-H
               >>\
               """
    end

    test "descendant" do
      assert %Font.Descendant{
               font_name: :"LibreBodoni-Regular",
               descriptor: %{},
               type: :CIDFontType0
             }
             |> Object.from()
             |> to_string() ==
               """
               <</Type /Font
                 /Subtype /CIDFontType0
                 /BaseFont /LibreBodoni-Regular
               >>\
               """
    end

    test "descriptor" do
      assert %Font.Descriptor{
               font_name: :"LibreBodoni-Regular",
               file: Mudbrick.Indirect.Ref.new(99) |> Mudbrick.Indirect.Object.new(%{})
             }
             |> Object.from()
             |> to_string() ==
               """
               <</Type /FontDescriptor
                 /FontFile3 99 0 R
                 /FontName /LibreBodoni-Regular
               >>\
               """
    end
  end
end
