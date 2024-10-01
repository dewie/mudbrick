defmodule Mudbrick.PageTree do
  defstruct [:kids]

  def new(kids: kids) do
    %Mudbrick.PageTree{kids: kids}
  end
end
