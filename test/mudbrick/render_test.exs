defmodule Mudbrick.RenderTest do
  use ExUnit.Case, async: true

  @lf 10
  @eol <<@lf>>

  test "version is always 2.0" do
    assert <<"%PDF-2.0", @eol, _rest::binary>> = Mudbrick.new() |> Mudbrick.render()
  end

  test "last line contains only the end-of-file marker" do
    last_line =
      Mudbrick.new()
      |> Mudbrick.render()
      |> String.split(@eol)
      |> List.last()

    assert <<"%%EOF">> = last_line
  end
end
