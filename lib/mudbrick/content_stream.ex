defmodule Mudbrick.ContentStream do
  defstruct [:text]

  def new(opts) do
    struct(Mudbrick.ContentStream, opts)
  end

  defimpl Mudbrick.Object do
    def from(stream) do
      inner = """
      BT
      /F1 24 Tf
      300 400 Td
      (#{stream.text}) Tj
      ET\
      """

      """
      #{Mudbrick.Object.from(%{Length: byte_size(inner)})}
      stream
      #{inner}
      endstream\
      """
    end
  end
end
