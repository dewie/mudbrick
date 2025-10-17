defmodule Mudbrick.Images.Png do
  @moduledoc """
  PNG image loader used by Mudbrick.


  This module parses PNG binary data to extract image metadata and content,
  assembling a PDF image `dictionary` and optional `additional_objects` (such as a
  palette or a soft-mask for alpha channels) suitable for embedding in a PDF.

  It exposes a single public entrypoint `new/1` which accepts:

  - `:file` (binary): the PNG file bytes
  - `:resource_identifier` (any): identifier used by the document builder
  - `:doc` (struct): the current document, needed for indexed color palette refs

  The struct mirrors the information discovered during decoding:
  `width`, `height`, `bits_per_component`, `color_type`, `image_data`,
  optional `palette` and `alpha`, the computed `size`, and the assembled
  `dictionary` and `additional_objects`.

  The module implements `Mudbrick.Object`, which turns the image into a
  `Mudbrick.Stream` with the proper PDF image entries.
  """
  alias Mudbrick.Stream
  require Logger

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
    additional_objects: [],
    dictionary: %{},
    image_data: <<>>,
    palette: <<>>,
    alpha: <<>>
  ]

  @doc """
  Build a PNG image struct from binary file data and options.

  Options:
  - `:file` (binary, required): PNG bytes.
  - `:resource_identifier` (any, optional): identifier for the document builder.
  - `:doc` (struct, optional): document context, used for indexed color palette refs.
  """
  def new(opts) do
    %__MODULE__{} =
      decode(opts[:file])
      |> Map.put(:resource_identifier,opts[:resource_identifier])
      |> add_size()
      |> add_dictionary_and_additional_objects(opts[:doc])
  end

  @doc """
  Set the `size` field to the length of `image_data` in bytes.
  """
  def add_size(image) do
    %{image | size: byte_size(image.image_data)}
  end

  @doc """
  Compute and attach the PDF image dictionary and any `additional_objects` needed
  for the given PNG `color_type`.
  """
  def add_dictionary_and_additional_objects(%{color_type: 0} = image, _doc) do
  Logger.warning "PNG IMAGE TYPE = 0"
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
          :Filter => :FlateDecode
        }
    }
  end

  def add_dictionary_and_additional_objects(%{color_type: 2} = image, _doc) do
  Logger.warning "PNG IMAGE TYPE = 2"
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

  def add_dictionary_and_additional_objects(%{color_type: 3} = image, doc) do
  Logger.warning "PNG IMAGE TYPE = 3"
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
            :Indexed, :DeviceRGB, round(byte_size(image.palette) / 3 - 1), (length(doc.objects) + 2), 0 , {:raw, ~c"R"}
          ],
          :BitsPerComponent => image.bits_per_component
        },
        additional_objects: [
          Stream.new(
            data: image.palette
          )
        ]
    }
  end

  def add_dictionary_and_additional_objects(%{color_type: color_type} = image, doc)
      when color_type in [4, 6] do
      Logger.warning "PNG IMAGE TYPE = 4,6 -> #{color_type}"

      additional_objects =  Stream.new(
        compress: true,
        data: image.alpha,

        additional_entries: %{
          :Type => :XObject,
          :Subtype => :Image,
          :Height => image.height,
          :Width => image.width,
          :BitsPerComponent => image.bits_per_component,
          :ColorSpace => :DeviceGray,
          :Decode => {:raw, "[ 0 1 ]"}
        }
      )

      Logger.warning "ADDITIONAL OBJECTS"
      Logger.warning inspect additional_objects, pretty: true

      %{
      image
      | dictionary: %{
          :Type => :XObject,
          :Subtype => :Image,
          :Width => image.width,
          :Height => image.height,
          :Length => image.size,
          :Filter => :FlateDecode,
          :ColorSpace => get_colorspace(image.color_type),
          :BitsPerComponent => image.bits_per_component,
          :SMask =>  {:raw, ~c"#{length(doc.objects) + 2} 0 R"}

        },
        additional_objects: [
          additional_objects

        ]
    }
  end

  @doc """
  Decode PNG binary data into an image struct capturing metadata and content.
  """
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
    %{color_type: color_type, bits_per_component: bit_depth, width: width, height: height} = data
    inflated = inflate(image_data)

    bytes_per_pixel =
      case color_type do
        4 -> 1 + 1   # Gray + Alpha (8-bit assumed)
        6 -> 3 + 1   # RGB + Alpha (8-bit assumed)
      end

    # Reconstruct raw, unfiltered scanlines
    raw = unfilter_scanlines(inflated, width, bytes_per_pixel, height)

    {color_raw, alpha_raw} =
      split_color_and_alpha(raw, width, height, color_type, bit_depth)

    {deflate(color_raw), alpha_raw}
  end

  # removed old filtered split helpers; we now unfilter first

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

  # Unfilter PNG scanlines to recover raw bytes per row (no leading filter byte)
  defp unfilter_scanlines(data, width, bytes_per_pixel, height) do
    row_length = width * bytes_per_pixel
    do_unfilter(data, row_length, bytes_per_pixel, height, <<>>, :binary.copy(<<0>>, row_length))
  end

  defp do_unfilter(_data, _row_length, _bpp, 0, acc, _prev_row), do: acc

  defp do_unfilter(<<filter, rest::binary>>, row_length, bpp, rows_left, acc, prev_row) do
    <<row::binary-size(row_length), tail::binary>> = rest
    current = apply_png_filter(filter, row, prev_row, bpp)
    do_unfilter(tail, row_length, bpp, rows_left - 1, <<acc::binary, current::binary>>, current)
  end

  defp apply_png_filter(0, row, _prev, _bpp), do: row
  defp apply_png_filter(1, row, _prev, bpp), do: unfilter_sub(row, bpp)
  defp apply_png_filter(2, row, prev, _bpp), do: unfilter_up(row, prev)
  defp apply_png_filter(3, row, prev, bpp), do: unfilter_average(row, prev, bpp)
  defp apply_png_filter(4, row, prev, bpp), do: unfilter_paeth(row, prev, bpp)

  defp unfilter_sub(row, bpp) do
    do_unfilter_sub(row, bpp, 0, <<>>)
  end

  defp do_unfilter_sub(<<>>, _bpp, _i, acc), do: acc
  defp do_unfilter_sub(<<byte, rest::binary>>, bpp, i, acc) do
    left = if i < bpp, do: 0, else: :binary.at(acc, i - bpp)
    val = band(byte + left, 255)
    do_unfilter_sub(rest, bpp, i + 1, <<acc::binary, val>>)
  end

  defp unfilter_up(row, prev) do
    do_unfilter_up(row, prev, 0, <<>>)
  end

  defp do_unfilter_up(<<>>, _prev, _i, acc), do: acc
  defp do_unfilter_up(<<byte, rest::binary>>, prev, i, acc) do
    up = :binary.at(prev, i)
    val = band(byte + up, 255)
    do_unfilter_up(rest, prev, i + 1, <<acc::binary, val>>)
  end

  defp unfilter_average(row, prev, bpp) do
    do_unfilter_average(row, prev, bpp, 0, <<>>)
  end

  defp do_unfilter_average(<<>>, _prev, _bpp, _i, acc), do: acc
  defp do_unfilter_average(<<byte, rest::binary>>, prev, bpp, i, acc) do
    left = if i < bpp, do: 0, else: :binary.at(acc, i - bpp)
    up = :binary.at(prev, i)
    val = band(byte + div(left + up, 2), 255)
    do_unfilter_average(rest, prev, bpp, i + 1, <<acc::binary, val>>)
  end

  defp unfilter_paeth(row, prev, bpp) do
    do_unfilter_paeth(row, prev, bpp, 0, <<>>)
  end

  defp do_unfilter_paeth(<<>>, _prev, _bpp, _i, acc), do: acc
  defp do_unfilter_paeth(<<byte, rest::binary>>, prev, bpp, i, acc) do
    a = if i < bpp, do: 0, else: :binary.at(acc, i - bpp)
    b = :binary.at(prev, i)
    c = if i < bpp, do: 0, else: :binary.at(prev, i - bpp)
    pr = paeth_predictor(a, b, c)
    val = band(byte + pr, 255)
    do_unfilter_paeth(rest, prev, bpp, i + 1, <<acc::binary, val>>)
  end

  defp paeth_predictor(a, b, c) do
    p = a + b - c
    pa = abs(p - a)
    pb = abs(p - b)
    pc = abs(p - c)
    cond do
      pa <= pb and pa <= pc -> a
      pb <= pc -> b
      true -> c
    end
  end

  defp band(x, m), do: :erlang.band(x, m)

  # Split unfiltered raw RGBA/GA rows into color and alpha continuous buffers
  defp split_color_and_alpha(raw, width, height, color_type, bit_depth) do
    # We currently support 8-bit per component
    _ = bit_depth
    {colors_per_pixel, alpha_bytes} =
      case color_type do
        4 -> {1, 1} # Gray + A
        6 -> {3, 1} # RGB + A
      end

    bytes_per_pixel = colors_per_pixel + alpha_bytes
    row_bytes = width * bytes_per_pixel

    do_split(raw, width, height, colors_per_pixel, alpha_bytes, row_bytes, <<>>, <<>>)
  end

  defp do_split(_raw, _w, 0, _cp, _ab, _rb, color_acc, alpha_acc), do: {color_acc, alpha_acc}
  defp do_split(raw, w, rows_left, cp, ab, row_bytes, color_acc, alpha_acc) do
    <<row::binary-size(row_bytes), rest::binary>> = raw
    {row_color, row_alpha} = split_row(row, w, cp, ab)
    do_split(rest, w, rows_left - 1, cp, ab, row_bytes, <<color_acc::binary, row_color::binary>>, <<alpha_acc::binary, row_alpha::binary>>)
  end

  defp split_row(row, width, colors_per_pixel, alpha_bytes) do
    bytes_per_pixel = colors_per_pixel + alpha_bytes
    do_split_row(row, width, bytes_per_pixel, colors_per_pixel, alpha_bytes, 0, <<>>, <<>>)
  end

  defp do_split_row(_row, 0, _bpp, _cp, _ab, _i, color_acc, alpha_acc), do: {color_acc, alpha_acc}
  defp do_split_row(row, remaining, bpp, cp, ab, i, color_acc, alpha_acc) do
    offset = i * bpp
    <<_pre::binary-size(offset), pix::binary-size(bpp), _rest::binary>> = row
    <<color::binary-size(cp), alpha::binary-size(ab)>> = pix
    do_split_row(row, remaining - 1, bpp, cp, ab, i + 1, <<color_acc::binary, color::binary>>, <<alpha_acc::binary, alpha::binary>>)
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
