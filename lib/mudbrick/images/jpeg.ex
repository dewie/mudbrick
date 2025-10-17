defmodule Mudbrick.Images.Jpeg do
  @moduledoc """
  JPEG image loader used by Mudbrick.

  This module parses JPEG binary data to extract image metadata and stores the
  raw image bytes as `image_data`. It assembles a PDF image `dictionary`
  suitable for embedding in a PDF, including optional CMYK decode inversion.

  Public entrypoint `new/1` accepts:

  - `:file` (binary): the JPEG file bytes
  - `:resource_identifier` (any): identifier used by the document builder
  - `:doc` (struct | nil): currently unused for JPEG, reserved for parity

  The struct contains `width`, `height`, `bits_per_component`, `color_type`,
  `image_data`, the computed `size`, and the assembled `dictionary` and
  `additional_objects`.

  The module implements `Mudbrick.Object`, emitting a `Mudbrick.Stream` with
  the proper PDF image entries.
  """
  alias Mudbrick.Stream

  defstruct [
    :resource_identifier,
    :size,
    :color_type,
    :width,
    :height,
    :bits_per_component,
    :file,
    additional_objects: [],
    dictionary: %{},
    image_data: <<>>
  ]

  @doc """
  Build a JPEG image struct from binary file data and options.

  Options:
  - `:file` (binary, required): JPEG bytes.
  - `:resource_identifier` (any, optional): identifier for the document builder.
  - `:doc` (struct | nil, optional): reserved for parity; unused for JPEG.
  """
  def new(opts) do
    %__MODULE__{}
    =
      decode(opts[:file])
      |> Map.put(:resource_identifier, opts[:resource_identifier])
      |> Map.put(:image_data, opts[:file])
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
  Compute and attach the PDF image dictionary for the JPEG, including CMYK
  decode inversion when `color_type` is 4.
  """
  def add_dictionary_and_additional_objects(image, _doc) do
    dictionary = %{
      :Type => :XObject,
      :Subtype => :Image,
      :ColorSpace => get_colorspace(image.color_type),
      :BitsPerComponent => image.bits_per_component,
      :Width => image.width,
      :Height => image.height,
      :Length => image.size,
      :Filter => :DCTDecode
    }

    dictionary =
      if image.color_type == 4 do
        # Invert colours for CMYK, See 4.8.4 of the spec
        Map.put(dictionary, :Decode, [1, 0, 1, 0, 1, 0, 1, 0])
      else
        dictionary
      end

    %{image | dictionary: dictionary}
  end

  @doc """
  Decode JPEG binary data into an image struct capturing metadata.
  """
  def decode(image_data) do
    parse(image_data)
  end

  @doc false
  defp parse(<<255, 216, rest::binary>>), do: parse(rest)

  [192, 193, 194, 195, 197, 198, 199, 201, 202, 203, 205, 206, 207]
  |> Enum.each(fn code ->
    defp parse(<<255, unquote(code), _length::unsigned-integer-size(16), rest::binary>>),
      do: parse_image_data(rest)
  end)

  @doc false
  defp parse(<<255, _code, length::unsigned-integer-size(16), rest::binary>>) do
    {:ok, data} = chomp(rest, length - 2)
    parse(data)
  end

  @doc false
  def parse_image_data(
        <<bits, height::unsigned-integer-size(16), width::unsigned-integer-size(16), color_type,
          _rest::binary>>
      ) do
    %__MODULE__{bits_per_component: bits, height: height, width: width, color_type: color_type}
  end

  @doc false
  def parse_image_data(_, _), do: {:error, :parse_error}

  @doc false
  defp chomp(data, length) do
    data = :erlang.binary_part(data, {length, byte_size(data) - length})
    {:ok, data}
  end

  @doc false
  defp get_colorspace(0), do: :DeviceGray
  defp get_colorspace(1), do: :DeviceGray
  defp get_colorspace(2), do: :DeviceRGB
  defp get_colorspace(3), do: :DeviceRGB
  defp get_colorspace(4), do: :DeviceCMYK
  defp get_colorspace(_), do: raise("Unsupported number of JPG color_type")


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
