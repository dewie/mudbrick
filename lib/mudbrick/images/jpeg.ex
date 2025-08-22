defmodule Mudbrick.Images.Jpeg do
  @moduledoc false
  alias Mudbrick.Stream

  defstruct [
    :file,
    :resource_identifier,
    :size,
    :bit_depth,
    :color_type,
    :width,
    :height,
    :bits_per_component,
    :filter,
    extra_objects: [],
    dictionary: %{}
  ]


  def new(opts) do

    %__MODULE__{bit_depth: bit_depth, height: height, width: width, color_type: color_type} =
      decode(opts[:file])
      size = byte_size(opts[:file])

      dictionary =
       %{
          :"Type" => :"XObject",
          :"Subtype" => :"Image",
          :"ColorSpace" => get_colorspace(color_type),
          :"BitsPerComponent" => bit_depth,
          :"Width" => width,
          :"Height" => height,
          :"Length" => size,
          :"Filter" => :"DCTDecode"
        }

        dictionary =
        if color_type == 4 do
          # Invert colours, See :4.8.4 of the spec
          Map.put(dictionary, :"Decode", [ 1, 0, 1, 0, 1, 0, 1, 0 ])
        else
          dictionary
        end


      %__MODULE__{
        bit_depth: bit_depth,
        height: height,
        width: width,
        color_type: color_type,
        file: opts[:file],
        size: size,
        size: byte_size(opts[:file]),
        dictionary: dictionary
      }


  end

  def decode(image_data) do
    parse(image_data)
  end

  defp parse(<<255, 216, rest::binary>>), do: parse(rest)

  [192, 193, 194, 195, 197, 198, 199, 201, 202, 203, 205, 206, 207]
  |> Enum.each(fn code ->
    defp parse(<<255, unquote(code), _length::unsigned-integer-size(16), rest::binary>>),
      do: parse_image_data(rest)
  end)

  defp parse(<<255, _code, length::unsigned-integer-size(16), rest::binary>>) do
    {:ok, data} = chomp(rest, length - 2)
    parse(data)
  end

  def parse_image_data(
        <<bits, height::unsigned-integer-size(16), width::unsigned-integer-size(16), color_type,
          _rest::binary>>
      ) do
    %__MODULE__{bit_depth: bits, height: height, width: width, color_type: color_type}
  end

  def parse_image_data(_, _), do: {:error, :parse_error}

  defp chomp(data, length) do
    data = :erlang.binary_part(data, {length, byte_size(data) - length})
    {:ok, data}
  end

  defp get_colorspace(0), do: :"DeviceGray"
  defp get_colorspace(1), do: :"DeviceGray"
  defp get_colorspace(2), do: :"DeviceRGB"
  defp get_colorspace(3), do: :"DeviceRGB"
  defp get_colorspace(4), do: :"DeviceCMYK"
  defp get_colorspace(_), do: raise("Unsupported number of JPG color_type")


  defimpl Mudbrick.Object do
    def to_iodata(image) do
      Stream.new(
        data: image.file,
        additional_entries:  image.dictionary
      )
      |> Mudbrick.Object.to_iodata()
    end
  end

end
