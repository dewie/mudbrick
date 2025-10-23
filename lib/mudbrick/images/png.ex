defmodule Mudbrick.Images.Png do
  @moduledoc """
  PNG image loader for Mudbrick.

  Responsibilities:
  - Parse PNG bytes to extract dimensions, bit depth, color type, palette, and image data
  - Build a PDF Image XObject dictionary and any `additional_objects` (palette or SMask)
  - For RGBA/GA images, construct a valid soft mask (SMask) from the alpha channel

  Public API:
  - `new/1` – build a `%Mudbrick.Images.Png{}` from PNG bytes and options
  - Implements `Mudbrick.Object` to serialise as a PDF `Mudbrick.Stream`
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
    alpha: <<>>,
    transparency: <<>>
  ]

  @typedoc "PNG image struct produced by this module."
  @type t :: %__MODULE__{
          resource_identifier: any(),
          size: non_neg_integer() | nil,
          color_type: 0 | 2 | 3 | 4 | 6 | nil,
          width: non_neg_integer() | nil,
          height: non_neg_integer() | nil,
          bits_per_component: pos_integer() | nil,
          compression_method: non_neg_integer() | nil,
          interlace_method: non_neg_integer() | nil,
          filter_method: non_neg_integer() | nil,
          file: binary() | nil,
          additional_objects: list(),
          dictionary: map(),
          image_data: binary(),
          palette: binary(),
          alpha: binary(),
          transparency: binary()
        }

  @doc """
  Build a PNG image struct from binary file data and options.

  Options:
  - `:file` (binary, required): PNG bytes.
  - `:resource_identifier` (any, optional): identifier for the document builder.
  - `:doc` (struct, optional): document context, used for indexed color palette refs.
  """
  @spec new(Keyword.t()) :: t()
  def new(opts) do
    %__MODULE__{} =
      decode(opts[:file])
      |> Map.put(:resource_identifier, opts[:resource_identifier])
      |> add_size()
      |> add_dictionary_and_additional_objects(opts[:doc])
  end

  @doc """
  Set the `size` field to the length of `image_data` in bytes.
  """
  @spec add_size(t()) :: t()
  def add_size(image) do
    %{image | size: byte_size(image.image_data)}
  end

  @doc """
  Compute and attach the PDF image dictionary and any `additional_objects` needed
  for the given PNG `color_type`.
  """
  @spec add_dictionary_and_additional_objects(t(), any()) :: t()
  def add_dictionary_and_additional_objects(%{color_type: 0} = image, _doc) do
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
    Logger.warning("PNG IMAGE TYPE = 2")

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

  def add_dictionary_and_additional_objects(%{color_type: 3, alpha: alpha} = image, doc)
      when byte_size(alpha) > 0 do
    Logger.warning("PNG IMAGE TYPE = 3 WITH TRANSPARENCY")

    # Create SMask for indexed PNG with transparency
    smask_object = Stream.new(
      compress: true,
      data: alpha,
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
            :Indexed,
            :DeviceRGB,
            round(byte_size(image.palette) / 3 - 1),
            {:raw, ~c"#{if doc, do: length(doc.objects) + 3, else: 3} 0 R"}
          ],
          :BitsPerComponent => image.bits_per_component,
          :SMask => {:raw, ~c"#{if doc, do: length(doc.objects) + 2, else: 2} 0 R"}
        },
        additional_objects: [
          smask_object,
          Stream.new(data: image.palette, compress: false),

        ]
    }
  end

  def add_dictionary_and_additional_objects(%{color_type: 3} = image, doc) do
    Logger.warning("PNG IMAGE TYPE = 3")

    # additional_objects =
    #   Stream.new(
    #     compress: false,
    #     data: image.palette
    #   )

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
            :Indexed,
            :DeviceRGB,
            round(byte_size(image.palette) / 3 - 1),
            {:raw, ~c"#{if doc, do: length(doc.objects) + 2, else: 2} 0 R"}
          ],
          :BitsPerComponent => image.bits_per_component
        },
        additional_objects: [
          Stream.new(data: image.palette, compress: false)
        ]
    }
  end

  def add_dictionary_and_additional_objects(%{color_type: color_type} = image, doc)
      when color_type in [4, 6] do
    Logger.warning("PNG IMAGE TYPE = #{color_type}")

    additional_objects =
      Stream.new(
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
          :SMask => {:raw, ~c"#{if doc, do: length(doc.objects) + 2, else: 2} 0 R"}
        },
        additional_objects: [
          additional_objects
        ]
    }
  end

  @doc """
  Decode PNG binary data into an image struct capturing metadata and content.
  """
  @spec decode(binary()) :: t()
  def decode(image_data) do
    parse(image_data)
  end

  @doc false
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

  @doc false
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

  @doc false
  defp parse_chunk("IDAT", payload, %{compression_method: 0} = data) do
    %{data | image_data: <<data.image_data::binary, payload::binary>>}
  end

  @doc false
  defp parse_chunk("PLTE", payload, %{compression_method: 0} = data) do
    %{data | palette: <<data.palette::binary, payload::binary>>}
  end

  @doc false
  defp parse_chunk("tRNS", payload, %{compression_method: 0} = data) do
    %{data | transparency: <<data.transparency::binary, payload::binary>>}
  end

  @doc false
  defp parse_chunk("IEND", _payload, %{color_type: color_type, image_data: image_data} = data)
       when color_type in [4, 6] do
    {image_data, alpha} = extract_alpha_channel(data, image_data)
    %{data | image_data: image_data, alpha: alpha}
  end

  @doc false
  defp parse_chunk("IEND", _payload, %{color_type: 3, transparency: transparency} = data)
       when byte_size(transparency) > 0 do
    {image_data, alpha} = extract_indexed_alpha_channel(data, data.image_data)
    %{data | image_data: image_data, alpha: alpha}
  end

  @doc false
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

  @doc false
  defp parse_chunk(_, _payload, data), do: data

  @doc false
  defp extract_alpha_channel(data, image_data) do
    %{color_type: color_type, bits_per_component: bit_depth, width: width, height: height} = data
    inflated = inflate(image_data)

    bytes_per_pixel =
      case color_type do
        # Gray + Alpha (8-bit assumed)
        4 -> 1 + 1
        # RGB + Alpha (8-bit assumed)
        6 -> 3 + 1
      end

    # Reconstruct raw, unfiltered scanlines
    raw = unfilter_scanlines(inflated, width, bytes_per_pixel, height)

    {color_raw, alpha_raw} =
      split_color_and_alpha(raw, width, height, color_type, bit_depth)

    {deflate(color_raw), alpha_raw}
  end

  # Extract alpha channel for indexed PNGs with tRNS transparency
  @doc false
  defp extract_indexed_alpha_channel(data, image_data) do
    %{transparency: transparency, width: width, height: height} = data

    # Inflate the image data
    inflated = inflate(image_data)

    # For indexed images, each pixel is one byte (index into palette)
    bytes_per_pixel = 1

    # Unfilter the scanlines
    raw = unfilter_scanlines(inflated, width, bytes_per_pixel, height)

    # Convert transparency data to alpha mask
    alpha_mask = build_indexed_alpha_mask(raw, transparency, width, height)

    {image_data, alpha_mask}
  end

  # Build alpha mask from indexed image data and tRNS transparency info
  @doc false
  defp build_indexed_alpha_mask(raw_data, transparency, width, height) do
    # Create a lookup table for transparency
    transparent_indices = :binary.bin_to_list(transparency)

    # Process each pixel and create alpha mask
    do_build_alpha_mask(raw_data, transparent_indices, width, height, <<>>)
  end

  @doc false
  defp do_build_alpha_mask(<<>>, _transparent_indices, _width, _height, acc), do: acc

  defp do_build_alpha_mask(raw_data, transparent_indices, width, height, acc) do
    <<row::binary-size(width), rest::binary>> = raw_data

    alpha_row =
      for pixel_index <- :binary.bin_to_list(row) do
        if pixel_index in transparent_indices, do: 0, else: 255
      end

    alpha_binary = :binary.list_to_bin(alpha_row)

    do_build_alpha_mask(
      rest,
      transparent_indices,
      width,
      height,
      <<acc::binary, alpha_binary::binary>>
    )
  end

  # removed old filtered split helpers; we now unfilter first

  # zlib inflate helper for PNG payloads
  @doc false
  defp inflate(compressed) do
    z = :zlib.open()
    :ok = :zlib.inflateInit(z)
    uncompressed = :zlib.inflate(z, compressed)
    :zlib.inflateEnd(z)
    :erlang.list_to_binary(uncompressed)
  end

  # zlib deflate helper for PDF streams
  @doc false
  defp deflate(data) do
    z = :zlib.open()
    :ok = :zlib.deflateInit(z)
    compressed = :zlib.deflate(z, data, :finish)
    :zlib.deflateEnd(z)
    :erlang.list_to_binary(compressed)
  end

  # Unfilter PNG scanlines to recover raw bytes per row (no leading filter byte)
  @doc false
  defp unfilter_scanlines(data, width, bytes_per_pixel, height) do
    row_length = width * bytes_per_pixel
    do_unfilter(data, row_length, bytes_per_pixel, height, <<>>, :binary.copy(<<0>>, row_length))
  end

  # Iterate rows, apply the appropriate filter to reconstruct raw bytes per row
  @doc false
  defp do_unfilter(_data, _row_length, _bpp, 0, acc, _prev_row), do: acc

  defp do_unfilter(<<filter, rest::binary>>, row_length, bpp, rows_left, acc, prev_row) do
    <<row::binary-size(row_length), tail::binary>> = rest
    current = apply_png_filter(filter, row, prev_row, bpp)
    do_unfilter(tail, row_length, bpp, rows_left - 1, <<acc::binary, current::binary>>, current)
  end

  # Dispatch to specific filter algorithms (None/Sub/Up/Average/Paeth)
  @doc false
  defp apply_png_filter(0, row, _prev, _bpp), do: row
  defp apply_png_filter(1, row, _prev, bpp), do: unfilter_sub(row, bpp)
  defp apply_png_filter(2, row, prev, _bpp), do: unfilter_up(row, prev)
  defp apply_png_filter(3, row, prev, bpp), do: unfilter_average(row, prev, bpp)
  defp apply_png_filter(4, row, prev, bpp), do: unfilter_paeth(row, prev, bpp)

  # Sub filter: each byte adds the value of the byte to its left
  @doc false
  defp unfilter_sub(row, bpp) do
    do_unfilter_sub(row, bpp, 0, <<>>)
  end

  defp do_unfilter_sub(<<>>, _bpp, _i, acc), do: acc

  defp do_unfilter_sub(<<byte, rest::binary>>, bpp, i, acc) do
    left = if i < bpp, do: 0, else: :binary.at(acc, i - bpp)
    val = band(byte + left, 255)
    do_unfilter_sub(rest, bpp, i + 1, <<acc::binary, val>>)
  end

  # Up filter: each byte adds the value from previous row at same column
  @doc false
  defp unfilter_up(row, prev) do
    do_unfilter_up(row, prev, 0, <<>>)
  end

  defp do_unfilter_up(<<>>, _prev, _i, acc), do: acc

  defp do_unfilter_up(<<byte, rest::binary>>, prev, i, acc) do
    up = :binary.at(prev, i)
    val = band(byte + up, 255)
    do_unfilter_up(rest, prev, i + 1, <<acc::binary, val>>)
  end

  # Average filter: adds average of left and up neighbors
  @doc false
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

  # Paeth filter: adds Paeth predictor of left, up, and upper-left
  @doc false
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

  # Compute Paeth predictor value
  @doc false
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

  # Bitwise and for small arithmetic with wraparound in filters
  @doc false
  defp band(x, m), do: :erlang.band(x, m)

  # Split unfiltered raw RGBA/GA rows into color and alpha continuous buffers
  # From unfiltered rows, separate interleaved color and alpha samples into two buffers
  @doc false
  defp split_color_and_alpha(raw, width, height, color_type, bit_depth) do
    # We currently support 8-bit per component
    _ = bit_depth

    {colors_per_pixel, alpha_bytes} =
      case color_type do
        # Gray + A
        4 -> {1, 1}
        # RGB + A
        6 -> {3, 1}
      end

    bytes_per_pixel = colors_per_pixel + alpha_bytes
    row_bytes = width * bytes_per_pixel

    do_split(raw, width, height, colors_per_pixel, alpha_bytes, row_bytes, <<>>, <<>>)
  end

  # Walk rows collecting color and alpha planes
  @doc false
  defp do_split(_raw, _w, 0, _cp, _ab, _rb, color_acc, alpha_acc), do: {color_acc, alpha_acc}

  defp do_split(raw, w, rows_left, cp, ab, row_bytes, color_acc, alpha_acc) do
    <<row::binary-size(row_bytes), rest::binary>> = raw
    {row_color, row_alpha} = split_row(row, w, cp, ab)

    do_split(
      rest,
      w,
      rows_left - 1,
      cp,
      ab,
      row_bytes,
      <<color_acc::binary, row_color::binary>>,
      <<alpha_acc::binary, row_alpha::binary>>
    )
  end

  # Split a single row into consecutive color bytes and alpha bytes
  @doc false
  defp split_row(row, width, colors_per_pixel, alpha_bytes) do
    bytes_per_pixel = colors_per_pixel + alpha_bytes
    do_split_row(row, width, bytes_per_pixel, colors_per_pixel, alpha_bytes, 0, <<>>, <<>>)
  end

  # Iterate each pixel-sized group across the row accumulating color and alpha
  @doc false
  defp do_split_row(_row, 0, _bpp, _cp, _ab, _i, color_acc, alpha_acc), do: {color_acc, alpha_acc}

  defp do_split_row(row, remaining, bpp, cp, ab, i, color_acc, alpha_acc) do
    offset = i * bpp
    <<_pre::binary-size(offset), pix::binary-size(bpp), _rest::binary>> = row
    <<color::binary-size(cp), alpha::binary-size(ab)>> = pix

    do_split_row(
      row,
      remaining - 1,
      bpp,
      cp,
      ab,
      i + 1,
      <<color_acc::binary, color::binary>>,
      <<alpha_acc::binary, alpha::binary>>
    )
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
