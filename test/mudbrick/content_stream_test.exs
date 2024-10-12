defmodule Mudbrick.ContentStreamTest do
  use ExUnit.Case, async: true

  import Mudbrick

  alias Mudbrick.ContentStream
  alias Mudbrick.Font

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
               descendant: %Mudbrick.Indirect.Object{
                 value: %Mudbrick.Font.CIDFont{
                   font_name: :"LibreBodoni-Regular",
                   descriptor: %Mudbrick.Indirect.Object{
                     value: %Mudbrick.Font.Descriptor{
                       file: %Mudbrick.Indirect.Object{
                         value: %Mudbrick.Stream{
                           data: @font_data,
                           additional_entries: %{Length1: 42952, Subtype: :OpenType}
                         },
                         ref: %Mudbrick.Indirect.Ref{number: 3}
                       },
                       font_name: :"LibreBodoni-Regular"
                     },
                     ref: %Mudbrick.Indirect.Ref{number: 4}
                   },
                   type: :CIDFontType0
                 },
                 ref: %Mudbrick.Indirect.Ref{number: 5}
               },
               encoding: :"Identity-H",
               first_char: nil,
               resource_identifier: :F1
             }
           } = show_text_operation
  end

  describe "serialisation" do
    test "converts TJ text to the current font's glyph IDs in hex" do
      text_show_operator =
        %ContentStream.TJ{
          text: "CO₂",
          font: %Font{
            name: :"LibreBodoni-Regular",
            type: :Type0,
            descendant: %Mudbrick.Indirect.Object{
              value: %Mudbrick.Font.CIDFont{
                font_name: :"LibreBodoni-Regular",
                descriptor: %Mudbrick.Indirect.Object{
                  value: %Mudbrick.Font.Descriptor{
                    file: %Mudbrick.Indirect.Object{
                      value: %Mudbrick.Stream{
                        data: @font_data,
                        additional_entries: %{Length1: 42952, Subtype: :OpenType}
                      }
                    },
                    font_name: :"LibreBodoni-Regular"
                  }
                },
                type: :CIDFontType0
              }
            },
            encoding: :"Identity-H",
            first_char: nil,
            resource_identifier: :F1
          }
        }

      assert Mudbrick.Object.from(text_show_operator) |> to_string() == """
             [<001100550174>] TJ\
             """
    end
  end
end
