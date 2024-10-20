defmodule Mudbrick.StreamTest do
  use ExUnit.Case, async: true

  import TestHelper

  test "includes length and stream markers when serialised" do
    serialised =
      Mudbrick.Stream.new(data: bodoni())
      |> Mudbrick.Object.from()
      |> :erlang.iolist_to_binary()

    assert String.starts_with?(serialised, """
           <</Length 42952
           >>
           stream\
           """)

    assert String.ends_with?(serialised, """
           endstream\
           """)
  end

  test "includes additional entries merged into the dictionary" do
    assert Mudbrick.Stream.new(data: "yo", additional_entries: %{Hi: :There})
           |> show() ==
             """
             <</Hi /There
               /Length 2
             >>
             stream
             yo
             endstream\
             """
  end
end
