defmodule Mudbrick.ContentStreamTest do
  use ExUnit.Case, async: true

  import Mudbrick

  alias Mudbrick.ContentStream
  alias Mudbrick.Font
  alias Mudbrick.Indirect
  alias Mudbrick.Object
  alias Mudbrick.Stream

  @font_data System.fetch_env!("FONT_LIBRE_BODONI_REGULAR") |> File.read!()

  test "text becomes a TJ when font descendant present" do
    {_doc, content_stream} =
      new()
      |> page(
        size: :letter,
        fonts: %{
          bodoni: [
            file: @font_data,
            encoding: :"Identity-H"
          ]
        }
      )
      |> contents()
      |> font(:bodoni, size: 24)
      |> text_position(0, 700)
      |> text("CO₂")

    [show_text_operation | _] = content_stream.value.operations

    assert %ContentStream.TJ{
             text: "CO₂",
             font: %Font{
               name: :"LibreBodoni-Regular",
               type: :Type0,
               encoding: :"Identity-H",
               first_char: nil,
               resource_identifier: :F1,
               descendant: %Indirect.Object{
                 value: %Font.CIDFont{
                   font_name: :"LibreBodoni-Regular",
                   type: :CIDFontType0,
                   descriptor: %Indirect.Object{
                     value: %Font.Descriptor{
                       font_name: :"LibreBodoni-Regular",
                       file: %Indirect.Object{
                         value: %Stream{
                           data: @font_data,
                           additional_entries: %{Length1: 42_952, Subtype: :OpenType}
                         }
                       }
                     }
                   }
                 }
               }
             }
           } = show_text_operation
  end

  describe "serialisation" do
    test "converts TJ text to the current font's glyph IDs in hex" do
      font_name = :"LibreBodoni-Regular"

      text_show_operator =
        %ContentStream.TJ{
          text: "CO₂",
          font: %Font{
            name: font_name,
            type: :Type0,
            encoding: :"Identity-H",
            first_char: nil,
            resource_identifier: :F1,
            descendant:
              obj(1, %Font.CIDFont{
                font_name: font_name,
                type: :CIDFontType0,
                descriptor:
                  obj(2, %Font.Descriptor{
                    font_name: font_name,
                    flags: 4,
                    file:
                      obj(3, %Stream{
                        data: @font_data,
                        additional_entries: %{Length1: 42_952, Subtype: :OpenType}
                      })
                  })
              })
          }
        }

      assert Object.from(text_show_operator) |> to_string() == """
             [<001100550174>] TJ\
             """
    end

    defp obj(ref_number, obj) do
      ref_number
      |> Indirect.Ref.new()
      |> Indirect.Object.new(obj)
    end
  end
end
