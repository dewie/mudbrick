defmodule Mudbrick.Name do
  defstruct [:value]

  def new(value) when not is_nil(value) do
    %Mudbrick.Name{value: value}
  end
end
