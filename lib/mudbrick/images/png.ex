defmodule Mudbrick.Images.Png do
  @moduledoc false

  # Embeds PNG images as PDF Image XObjects.
  #
  # For non-transparent images (colour types 0, 2 and 3) the compressed PNG
  # image data (IDAT) is embedded verbatim and the PNG per-scanline filtering is
  # undone by the PDF reader via `/Filter /FlateDecode` with a `/DecodeParms`
  # predictor. For images with an alpha channel (colour types 4 and 6, or an
  # indexed image with a `tRNS` chunk) the alpha is extracted into a separate
  # soft mask (`/SMask`) image.

  alias Mudbrick.Image
  alias Mudbrick.Stream

  @png_signature <<137, 80, 78, 71, 13, 10, 26, 10>>

  @type t :: %__MODULE__{
          resource_identifier: atom() | nil,
          width: non_neg_integer(),
          height: non_neg_integer(),
          bits_per_component: pos_integer(),
          colour_type: 0 | 2 | 3 | 4 | 6,
          image_data: binary(),
          palette: binary() | nil,
          alpha: binary() | nil,
          dictionary: map()
        }

  @enforce_keys [
    :width,
    :height,
    :bits_per_component,
    :colour_type,
    :image_data
  ]
  defstruct [
    :resource_identifier,
    :width,
    :height,
    :bits_per_component,
    :colour_type,
    :image_data,
    palette: nil,
    alpha: nil,
    dictionary: %{}
  ]

  @doc """
  Build a PNG image struct from PNG bytes.

  Options:

    - `:file` (required) - the raw PNG bytes.
    - `:resource_identifier` - the identifier used to reference the image, e.g. `:I1`.
  """
  @spec new(Keyword.t()) :: t()
  def new(opts) do
    opts
    |> Keyword.fetch!(:file)
    |> decode()
    |> Map.put(:resource_identifier, opts[:resource_identifier])
  end

  @doc false
  # The soft mask Image XObject built from the alpha channel, or nil when the
  # image is fully opaque.
  @spec soft_mask(t()) :: Stream.t() | nil
  def soft_mask(%__MODULE__{alpha: nil}), do: nil

  def soft_mask(%__MODULE__{alpha: alpha} = image) do
    Stream.new(
      data: alpha,
      compress: true,
      additional_entries: %{
        Type: :XObject,
        Subtype: :Image,
        Width: image.width,
        Height: image.height,
        BitsPerComponent: 8,
        ColorSpace: :DeviceGray
      }
    )
  end

  @doc false
  # The palette stream for indexed images, or nil for other colour types.
  @spec palette_object(t()) :: Stream.t() | nil
  def palette_object(%__MODULE__{palette: nil}), do: nil

  def palette_object(%__MODULE__{palette: palette}),
    do: Stream.new(data: palette, compress: false)

  @doc false
  # Completes the image dictionary once the palette and soft mask objects (if
  # any) have been added to the document and their references are known.
  @spec put_dictionary(t(), %{
          optional(:palette) => Mudbrick.Indirect.Ref.t(),
          optional(:smask) => Mudbrick.Indirect.Ref.t()
        }) :: t()
  def put_dictionary(image, refs \\ %{}) do
    %{image | dictionary: dictionary(image, refs)}
  end

  defp dictionary(%{colour_type: type} = image, _refs) when type in [0, 2] do
    base(image)
    |> Map.merge(%{
      ColorSpace: colour_space(type),
      DecodeParms: decode_parms(image)
    })
  end

  defp dictionary(%{colour_type: 3} = image, refs) do
    hival = div(byte_size(image.palette), 3) - 1

    base(image)
    |> Map.merge(%{
      ColorSpace: [:Indexed, :DeviceRGB, hival, Map.fetch!(refs, :palette)],
      DecodeParms: decode_parms(image)
    })
    |> maybe_put_smask(refs)
  end

  defp dictionary(%{colour_type: type} = image, refs) when type in [4, 6] do
    base(image)
    |> Map.put(:ColorSpace, colour_space(type))
    |> Map.put(:SMask, Map.fetch!(refs, :smask))
  end

  defp base(image) do
    %{
      Type: :XObject,
      Subtype: :Image,
      Width: image.width,
      Height: image.height,
      BitsPerComponent: image.bits_per_component,
      Filter: :FlateDecode
    }
  end

  defp maybe_put_smask(dictionary, %{smask: ref}), do: Map.put(dictionary, :SMask, ref)
  defp maybe_put_smask(dictionary, _refs), do: dictionary

  defp decode_parms(image) do
    %{
      Predictor: 15,
      Colors: colours(image.colour_type),
      BitsPerComponent: image.bits_per_component,
      Columns: image.width
    }
  end

  defp colour_space(0), do: :DeviceGray
  defp colour_space(2), do: :DeviceRGB
  defp colour_space(4), do: :DeviceGray
  defp colour_space(6), do: :DeviceRGB

  defp colours(0), do: 1
  defp colours(2), do: 3
  defp colours(3), do: 1
  defp colours(4), do: 1
  defp colours(6), do: 3

  # --- Decoding ------------------------------------------------------------

  defp decode(@png_signature <> chunks) do
    %{ihdr: ihdr} =
      acc =
      parse_chunks(chunks, %{ihdr: nil, idat: <<>>, palette: nil, transparency: nil})

    guard_supported!(ihdr)
    build(ihdr, acc)
  end

  defp decode(_), do: raise(Image.NotSupported, "Not a PNG file")

  # Opaque colour types: embed the compressed PNG data as-is and let the PDF
  # reader reverse the PNG predictor.
  defp build(%{colour_type: type} = ihdr, acc) when type in [0, 2] do
    %{fields(ihdr) | image_data: acc.idat}
  end

  # Indexed: same as above but carrying a palette and possibly a tRNS-derived
  # soft mask.
  defp build(%{colour_type: 3} = ihdr, %{transparency: nil} = acc) do
    %{fields(ihdr) | image_data: acc.idat, palette: acc.palette}
  end

  defp build(%{colour_type: 3, bits_per_component: depth}, _acc) when depth != 8 do
    raise Image.NotSupported, "#{depth}-bit indexed PNGs with transparency are not supported"
  end

  defp build(%{colour_type: 3} = ihdr, acc) do
    alpha = indexed_alpha(acc.idat, acc.transparency, ihdr)
    %{fields(ihdr) | image_data: acc.idat, palette: acc.palette, alpha: alpha}
  end

  # Colour types with a built-in alpha channel: separate the colour and alpha
  # samples, re-compressing the colour data (now without PNG filtering).
  defp build(%{colour_type: type} = ihdr, acc) when type in [4, 6] do
    {colour, alpha} = split_colour_and_alpha(acc.idat, ihdr)
    %{fields(ihdr) | image_data: deflate(colour), alpha: alpha}
  end

  defp fields(ihdr) do
    %__MODULE__{
      width: ihdr.width,
      height: ihdr.height,
      bits_per_component: ihdr.bits_per_component,
      colour_type: ihdr.colour_type,
      image_data: <<>>
    }
  end

  defp guard_supported!(nil), do: raise(Image.NotSupported, "PNG has no IHDR chunk")

  defp guard_supported!(%{interlace_method: method}) when method != 0 do
    raise Image.NotSupported, "Interlaced PNGs are not supported"
  end

  defp guard_supported!(%{compression_method: method}) when method != 0 do
    raise Image.NotSupported, "Unsupported PNG compression method: #{method}"
  end

  # Alpha extraction (colour types 4/6 and indexed tRNS) is only implemented for
  # 8-bit samples.
  defp guard_supported!(%{colour_type: type, bits_per_component: depth})
       when type in [4, 6] and depth != 8 do
    raise Image.NotSupported, "#{depth}-bit alpha PNGs are not supported"
  end

  defp guard_supported!(%{colour_type: type}) when type not in [0, 2, 3, 4, 6] do
    raise Image.NotSupported, "Unsupported PNG colour type: #{type}"
  end

  defp guard_supported!(_ihdr), do: :ok

  defp parse_chunks(<<>>, acc), do: acc

  defp parse_chunks(
         <<length::32, type::binary-size(4), payload::binary-size(length), _crc::32,
           rest::binary>>,
         acc
       ) do
    parse_chunks(rest, parse_chunk(type, payload, acc))
  end

  defp parse_chunk(
         "IHDR",
         <<width::32, height::32, bit_depth::8, colour_type::8, compression_method::8,
           _filter_method::8, interlace_method::8>>,
         acc
       ) do
    %{
      acc
      | ihdr: %{
          width: width,
          height: height,
          bits_per_component: bit_depth,
          colour_type: colour_type,
          compression_method: compression_method,
          interlace_method: interlace_method
        }
    }
  end

  defp parse_chunk("IDAT", payload, acc), do: %{acc | idat: acc.idat <> payload}
  defp parse_chunk("PLTE", payload, acc), do: %{acc | palette: payload}
  defp parse_chunk("tRNS", payload, acc), do: %{acc | transparency: payload}
  defp parse_chunk(_type, _payload, acc), do: acc

  # --- Alpha channel handling ---------------------------------------------

  # For indexed images, map each pixel's palette index through the tRNS table to
  # produce an 8-bit alpha value (indices beyond the table are fully opaque).
  defp indexed_alpha(idat, transparency, ihdr) do
    idat
    |> inflate()
    |> unfilter(ihdr.width, ihdr.height, 1)
    |> :binary.bin_to_list()
    |> Enum.map(fn index ->
      if index < byte_size(transparency), do: :binary.at(transparency, index), else: 255
    end)
    |> :binary.list_to_bin()
  end

  defp split_colour_and_alpha(idat, %{colour_type: type, width: width, height: height}) do
    colours = colours(type)
    bytes_per_pixel = colours + 1

    idat
    |> inflate()
    |> unfilter(width, height, bytes_per_pixel)
    |> split_samples(colours, 1, <<>>, <<>>)
  end

  defp split_samples(<<>>, _colours, _alpha_bytes, colour, alpha), do: {colour, alpha}

  defp split_samples(data, colours, alpha_bytes, colour, alpha) do
    <<pixel_colour::binary-size(colours), pixel_alpha::binary-size(alpha_bytes), rest::binary>> =
      data

    split_samples(
      rest,
      colours,
      alpha_bytes,
      colour <> pixel_colour,
      alpha <> pixel_alpha
    )
  end

  # --- PNG scanline filtering ---------------------------------------------

  # Reverse the per-scanline PNG filters, returning the raw sample bytes with
  # the leading filter-type byte of each row removed.
  defp unfilter(data, width, height, bytes_per_pixel) do
    row_length = width * bytes_per_pixel
    do_unfilter(data, row_length, bytes_per_pixel, height, :binary.copy(<<0>>, row_length), <<>>)
  end

  defp do_unfilter(_data, _row_length, _bpp, 0, _previous, acc), do: acc

  defp do_unfilter(<<filter, rest::binary>>, row_length, bpp, rows_left, previous, acc) do
    <<row::binary-size(row_length), tail::binary>> = rest
    reconstructed = reconstruct(filter, row, previous, bpp)

    do_unfilter(tail, row_length, bpp, rows_left - 1, reconstructed, acc <> reconstructed)
  end

  defp reconstruct(0, row, _previous, _bpp), do: row

  defp reconstruct(filter, row, previous, bpp),
    do: reconstruct(filter, row, previous, bpp, 0, <<>>)

  defp reconstruct(_filter, <<>>, _previous, _bpp, _i, acc), do: acc

  defp reconstruct(filter, <<byte, rest::binary>>, previous, bpp, i, acc) do
    left = if i < bpp, do: 0, else: :binary.at(acc, i - bpp)
    up = :binary.at(previous, i)
    upper_left = if i < bpp, do: 0, else: :binary.at(previous, i - bpp)

    value =
      case filter do
        # Sub
        1 -> byte + left
        # Up
        2 -> byte + up
        # Average
        3 -> byte + div(left + up, 2)
        # Paeth
        4 -> byte + paeth(left, up, upper_left)
      end

    reconstruct(filter, rest, previous, bpp, i + 1, <<acc::binary, rem(value, 256)>>)
  end

  defp paeth(a, b, c) do
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

  defp inflate(data) do
    z = :zlib.open()
    :ok = :zlib.inflateInit(z)
    inflated = :zlib.inflate(z, data)
    :zlib.inflateEnd(z)
    :zlib.close(z)
    IO.iodata_to_binary(inflated)
  end

  defp deflate(data) do
    z = :zlib.open()
    :ok = :zlib.deflateInit(z)
    deflated = :zlib.deflate(z, data, :finish)
    :zlib.deflateEnd(z)
    :zlib.close(z)
    IO.iodata_to_binary(deflated)
  end

  defimpl Mudbrick.Object do
    def to_iodata(image) do
      Mudbrick.Stream.new(
        data: image.image_data,
        additional_entries: image.dictionary
      )
      |> Mudbrick.Object.to_iodata()
    end
  end
end
