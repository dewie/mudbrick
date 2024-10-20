defmodule Mudbrick.Stream do
  defstruct compress: false,
            data: nil,
            additional_entries: %{},
            length: nil,
            filters: []

  import :erlang, only: [iolist_size: 1]

  def new(opts) do
    opts =
      case decide_compression(opts) do
        {:ok, data} ->
          Keyword.merge(
            opts,
            data: data,
            length: iolist_size(data),
            filters: [:FlateDecode]
          )

        :error ->
          opts
      end

    struct!(__MODULE__, Keyword.put(opts, :length, iolist_size(opts[:data])))
  end

  defp decide_compression(opts) do
    if opts[:compress] do
      uncompressed = opts[:data]
      compressed = Mudbrick.compress(uncompressed)

      if iolist_size(compressed) < iolist_size(uncompressed) do
        {:ok, compressed}
      else
        :error
      end
    else
      :error
    end
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
