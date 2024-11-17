defmodule Mudbrick.Stream do
  @moduledoc false

  defstruct compress: false,
            data: nil,
            additional_entries: %{},
            length: nil,
            filters: []

  def new(opts) do
    opts =
      case decide_compression(opts) do
        {:ok, data} ->
          Keyword.merge(
            opts,
            data: data,
            length: IO.iodata_length(data),
            filters: [:FlateDecode]
          )

        :error ->
          opts
      end

    struct!(__MODULE__, Keyword.put(opts, :length, IO.iodata_length(opts[:data])))
  end

  defp decide_compression(opts) do
    if opts[:compress] do
      uncompressed = opts[:data]
      compressed = Mudbrick.compress(uncompressed)

      if IO.iodata_length(compressed) < IO.iodata_length(uncompressed) do
        {:ok, compressed}
      else
        :error
      end
    else
      :error
    end
  end

  defimpl Mudbrick.Object do
    def to_iodata(stream) do
      [
        Mudbrick.Object.to_iodata(
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
        if(stream.data == [""], do: [], else: [stream.data, "\n"]),
        "endstream"
      ]
    end
  end
end
