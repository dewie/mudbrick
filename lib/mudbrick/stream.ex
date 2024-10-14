defmodule Mudbrick.Stream do
  defstruct data: nil,
            additional_entries: %{}

  def new(opts) do
    struct!(__MODULE__, opts)
  end

  defimpl Mudbrick.Object do
    def from(stream) do
      # z = :zlib.open()
      # :ok = :zlib.deflateInit(z)
      # deflated = :zlib.deflate(z, stream.data, :finish)
      # :zlib.deflateEnd(z)
      # :zlib.close(z)

      [
        Mudbrick.Object.from(
          %{
            Length: :erlang.iolist_size(stream.data)
            # Filter: [:FlateDecode]
          }
          |> Map.merge(stream.additional_entries)
        ),
        "\nstream\n",
        stream.data,
        "\nendstream"
      ]
    end
  end
end
