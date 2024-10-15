defmodule TestHelper do
  def show(o) do
    Mudbrick.Object.from(o) |> to_string()
  end
end

ExUnit.start()
