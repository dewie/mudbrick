defmodule Mudbrick.FontTest do
  use ExUnit.Case, async: true

  alias Mudbrick.Font
  alias Mudbrick.Object

  test "converts keys when serialised" do
    assert Font.new(
             name: :Helvetica,
             encoding: :"Identity-H",
             type: :TrueType,
             resource_identifier: :F1
           )
           |> Object.from()
           |> to_string() ==
             """
             <</Type /Font
               /Subtype /TrueType
               /BaseFont /Helvetica
               /Encoding /Identity-H
             >>\
             """
  end
end
