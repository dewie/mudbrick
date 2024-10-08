defmodule Mudbrick.StreamTest do
  use ExUnit.Case, async: true

  test "includes length and stream markers when serialised" do
    data = System.fetch_env!("FONT_LIBRE_BODONI_REGULAR") |> File.read!()

    serialised =
      Mudbrick.Stream.new(data: data)
      |> Mudbrick.Object.from()
      |> :erlang.iolist_to_binary()

    assert String.slice(serialised, 0..24) == """
           <</Length 42952
           >>
           stream\
           """

    assert String.ends_with?(serialised, """
           endstream\
           """)
  end

  test "includes additional entries merged into the dictionary" do
    assert Mudbrick.Stream.new(data: "yo", additional_entries: %{Hi: :There})
           |> Mudbrick.Object.from()
           |> to_string() ==
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
