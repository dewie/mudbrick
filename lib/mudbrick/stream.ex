defmodule Mudbrick.Stream do
  defstruct [:data]

  def new(opts) do
    struct!(Mudbrick.Stream, opts)
  end

  defimpl Mudbrick.Object do
    def from(stream) do
      # z = :zlib.open()
      # :ok = :zlib.deflateInit(z)
      # deflated = :zlib.deflate(z, stream.data, :finish)
      # :zlib.deflateEnd(z)
      # :zlib.close(z)

      [
        Mudbrick.Object.from(%{
          Length: byte_size(stream.data)
          # Filter: [:FlateDecode]
        }),
        "\nstream\n",
        stream.data,
        "\nendstream"
      ]
    end
  end
end
