defmodule Mudbrick do
  def new do
  end

  def render(_) do
    """
    %PDF-2.0
    %%EOF
    """
    |> String.trim_trailing()
  end

  def parse(_) do
  end
end
