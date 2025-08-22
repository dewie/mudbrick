defmodule Mudbrick.Images.Png do
  @moduledoc false
  alias Mudbrick.Stream

  defstruct [
    :resource_identifier,
    :size,
    :color_type,
    :width,
    :height,
    :bits_per_component,
    :compression_method,
    :interlace_method,
    :filter_method,
    :file,
    extra_objects: [],
    dictionary: %{},
    image_data: <<>>,
    palette: <<>>,
    alpha: <<>>
  ]

  def new(opts) do
    %__MODULE__{} =
      decode(opts[:file])
      |> map.put(:resource_identifier,opts[:resource_identifier])
      |> add_size()
      |> add_dictionary_and_extra_objects(opts[:doc])
  end

  def add_size(image) do
    %{image | size: byte_size(image.image_data)}
  end

  def add_dictionary_and_extra_objects(%{color_type: 0} = image, _doc) do
    %{
      image
      | dictionary: %{
          :Type => :XObject,
          :Subtype => :Image,
          :ColorSpace => :DeviceGray,
          :BitsPerComponent => image.bits_per_component,
          :Width => image.width,
          :Height => image.height,
          :Length => image.size,
          :Filter => :DCTDecode
        }
    }
  end

  def add_dictionary_and_extra_objects(%{color_type: 2} = image, _doc) do
    %{
      image
      | dictionary: %{
          :Type => :XObject,
          :Subtype => :Image,
          :Width => image.width,
          :Height => image.height,
          :Length => image.size,
          :Filter => :FlateDecode,
          :DecodeParms => %{
            :Predictor => 15,
            :Colors => get_colors(image.color_type),
            :BitsPerComponent => image.bits_per_component,
            :Columns => image.width
          },
          :ColorSpace => get_colorspace(image.color_type),
          :BitsPerComponent => image.bits_per_component
        }
    }
  end

  def add_dictionary_and_extra_objects(%{color_type: 3} = image, doc) do
    %{
      image
      | dictionary: %{
          :Type => :XObject,
          :Subtype => :Image,
          :Width => image.width,
          :Height => image.height,
          :Length => image.size,
          :Filter => :FlateDecode,
          :DecodeParms => %{
            :Predictor => 15,
            :Colors => get_colors(image.color_type),
            :BitsPerComponent => image.bits_per_component,
            :Columns => image.width
          },
          :ColorSpace => [
            :Indexed, :DeviceRGB, round(byte_size(image.palette) / 3 - 1), (length(doc.objects) + 2), 0 , {:raw,'R'}
          ],
          :BitsPerComponent => image.bits_per_component
        },
        extra_objects: [
          Stream.new(
            data: image.palette
          )
        ]
    }
  end

  def add_dictionary_and_extra_objects(%{color_type: color_type} = image, _doc)
      when color_type in [4, 6] do
    %{
      image
      | dictionary: %{
          :Type => :XObject,
          :Subtype => :Image,
          :Width => image.width,
          :Height => image.height,
          :Length => image.size,
          :Filter => :FlateDecode,
          :DecodeParms => %{
            :Predictor => 15,
            :Colors => get_colors(image.color_type),
            :BitsPerComponent => image.bits_per_component,
            :Columns => image.width
          },
          :ColorSpace => get_colorspace(image.color_type),
          :BitsPerComponent => image.bits_per_component
        },
        extra_objects: [
          Stream.new(
            data: image.alpha,
            additional_entries: %{
              :Type => :XObject,
              :Subtype => :Image,
              :Width => image.width,
              :Height => image.height,
              :BitsPerComponent => image.bits_per_component,
              :ColorSpace => :DeviceGray,
              :Decode => [0, 1],
              :DecodeParms => %{
                :Predictor => 15,
                :Colors => 1,
                :BitsPerComponent => image.bits_per_component,
                :Columns => image.width
              }
            }
          )
        ]
    }
  end

  def decode(image_data) do
    parse(image_data)
  end

  defp parse(image_data), do: parse(image_data, %__MODULE__{})

  defp parse(
         <<137, 80, 78, 71, 13, 10, 26, 10, rest::binary>>,
         data
       ) do
    parse(rest, data)
  end

  defp parse("", data), do: data

  defp parse(
         <<length::unsigned-32, type::binary-size(4), payload::binary-size(length),
           _crc::unsigned-32, rest::binary>>,
         data
       ) do
    data = parse_chunk(type, payload, data)
    parse(rest, data)
  end

  defp parse_chunk(
         "IHDR",
         <<width::unsigned-32, height::unsigned-32, bit_depth::unsigned-8, color_type::unsigned-8,
           compression_method::unsigned-8, filter_method::unsigned-8,
           interlace_method::unsigned-8, _rest::binary>>,
         data
       ) do
    %{
      data
      | width: width,
        height: height,
        bits_per_component: bit_depth,
        color_type: color_type,
        compression_method: compression_method,
        filter_method: filter_method,
        interlace_method: interlace_method
    }
  end

  defp parse_chunk("IDAT", payload, %{compression_method: 0} = data) do
    %{data | image_data: <<data.image_data::binary, payload::binary>>}
  end

  defp parse_chunk("PLTE", payload, %{compression_method: 0} = data) do
    %{data | palette: <<data.palette::binary, payload::binary>>}
  end

  defp parse_chunk("IEND", _payload, %{color_type: color_type, image_data: image_data} = data)
       when color_type in [4, 6] do
    {image_data, alpha} = extract_alpha_channel(data, image_data)
    %{data | image_data: image_data, alpha: alpha}
  end

  defp parse_chunk("IEND", _payload, data), do: data

  # defp parse_chunk("cHRM", _payload, data), do: data
  # defp parse_chunk("gAMA", _payload, data), do: data
  # defp parse_chunk("bKGD", _payload, data), do: data
  # defp parse_chunk("tIME", _payload, data), do: data
  # defp parse_chunk("tEXt", _payload, data), do: data
  # defp parse_chunk("zTXt", _payload, data), do: data
  # defp parse_chunk("iTXt", _payload, data), do: data
  # defp parse_chunk("iCCP", _payload, data), do: data
  # defp parse_chunk("sRGB", _payload, data), do: data
  # defp parse_chunk("pHYs", _payload, data), do: data

  defp parse_chunk(_, _payload, data), do: data

  defp extract_alpha_channel(data, image_data) do
    %{color_type: color_type, bits_per_component: bit_depth, width: width} = data
    image_data = inflate(image_data)
    colors = get_colors(color_type)
    alpha_bytes = round(bit_depth / 8)
    color_bytes = round(colors * bit_depth / 8)
    scanline_length = round((color_bytes + alpha_bytes) * width + 1)
    scan_lines = extract_scan_lines(image_data, scanline_length - 1)
    {color_data, alpha_data} = breakout_lines({color_bytes, alpha_bytes}, scan_lines)
    {deflate(color_data), alpha_data}
  end

  defp extract_scan_lines(<<>>, _line_length), do: []

  defp extract_scan_lines(image_data, line_length) do
    <<filter::unsigned-8, line::binary-size(line_length), rest::binary>> = image_data
    [{filter, line} | extract_scan_lines(rest, line_length)]
  end

  defp breakout_lines(sizes, scan_lines, color_data \\ <<>>, alpha_data \\ <<>>)

  defp breakout_lines(_sizes, [], color_data, alpha_data), do: {color_data, alpha_data}

  defp breakout_lines(
         {color_bytes, alpha_bytes},
         [{filter, line} | tail],
         color_data,
         alpha_data
       ) do
    {color, alpha} = breakout_line({color_bytes, alpha_bytes}, line)

    breakout_lines(
      {color_bytes, alpha_bytes},
      tail,
      <<color_data::binary, filter::unsigned-8, color::binary>>,
      <<alpha_data::binary, filter::unsigned-8, alpha::binary>>
    )
  end

  defp breakout_line(sizes, line, color_data \\ <<>>, alpha_data \\ <<>>)

  defp breakout_line(_sizes, "", color_data, alpha_data), do: {color_data, alpha_data}

  defp breakout_line({color_bytes, alpha_bytes}, line, color_data, alpha_data) do
    <<color::binary-size(color_bytes), alpha::binary-size(alpha_bytes), rest::binary>> = line

    breakout_line(
      {color_bytes, alpha_bytes},
      rest,
      <<color_data::binary, color::binary-size(color_bytes)>>,
      <<alpha_data::binary, alpha::binary-size(alpha_bytes)>>
    )
  end

  defp inflate(compressed) do
    z = :zlib.open()
    :ok = :zlib.inflateInit(z)
    uncompressed = :zlib.inflate(z, compressed)
    :zlib.inflateEnd(z)
    :erlang.list_to_binary(uncompressed)
  end

  defp deflate(data) do
    z = :zlib.open()
    :ok = :zlib.deflateInit(z)
    compressed = :zlib.deflate(z, data, :finish)
    :zlib.deflateEnd(z)
    :erlang.list_to_binary(compressed)
  end

  defp get_colorspace(0), do: :DeviceGray
  defp get_colorspace(2), do: :DeviceRGB
  defp get_colorspace(3), do: :DeviceGray
  defp get_colorspace(4), do: :DeviceGray
  defp get_colorspace(6), do: :DeviceRGB

  defp get_colors(0), do: 1
  defp get_colors(2), do: 3
  defp get_colors(3), do: 1
  defp get_colors(4), do: 1
  defp get_colors(6), do: 3

  defimpl Mudbrick.Object do
    def to_iodata(image) do
      Stream.new(
        data: image.image_data,
        additional_entries: image.dictionary
      )
      |> Mudbrick.Object.to_iodata()
    end
  end
end
