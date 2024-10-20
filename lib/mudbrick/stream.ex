defmodule Mudbrick.Stream do
  defstruct compress: false,
            data: nil,
            additional_entries: %{},
            length: nil,
            filters: []

  def new(opts) do
    opts =
      if opts[:compress] do
        opts
        |> Keyword.update!(:data, fn data ->
          z = :zlib.open()
          :ok = :zlib.deflateInit(z)
          deflated = :zlib.deflate(z, data, :finish)
          :zlib.deflateEnd(z)
          :zlib.close(z)
          deflated
        end)
        |> then(fn opts ->
          Keyword.merge(
            opts,
            length: :erlang.iolist_size(opts[:data]),
            filters: [:FlateDecode]
          )
        end)
      else
        opts
      end

    struct!(__MODULE__, Keyword.put(opts, :length, :erlang.iolist_size(opts[:data])))
  end

  defimpl Mudbrick.Object do
    def from(stream) do
      [
        Mudbrick.Object.from(
          %{Length: stream.length}
          |> Map.merge(stream.additional_entries)
          |> Map.merge(
            if Enum.empty?(stream.filters) do
              %{}
            else
              %{Filter: stream.filters}
            end
          )
        ),
        "\nstream\n",
        stream.data,
        "\nendstream"
      ]
    end
  end
end
