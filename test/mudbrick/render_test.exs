defmodule Mudbrick.RenderTest do
  use ExUnit.Case, async: true

  @lf 10
  @cr 13
  @eol <<@cr, @lf>>

  test "version is always 2.0" do
    assert <<"%PDF-2.0", @eol, _rest::binary>> = Mudbrick.new() |> Mudbrick.render()
  end
end
