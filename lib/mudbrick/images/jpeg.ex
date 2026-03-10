defmodule Mudbrick.Images.Jpeg do
  @moduledoc """
  JPEG image loader for Mudbrick.

  Responsibilities:
  - Parse JPEG bytes to extract dimensions, bit depth, and color components
  - Build a PDF Image XObject dictionary suitable for embedding (with CMYK decode inversion)
  - Provide an object implementation to serialise as a PDF stream

  Public API:
  - `new/1` – build a `%Mudbrick.Images.Jpeg{}` from JPEG bytes and options
  - Implements `Mudbrick.Object` to serialise as a PDF `Mudbrick.Stream`
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

  @typedoc "JPEG image struct produced by this module."
  @type t :: %__MODULE__{
          resource_identifier: any(),
          size: non_neg_integer() | nil,
          color_type: non_neg_integer() | nil,
          width: non_neg_integer() | nil,
          height: non_neg_integer() | nil,
          bits_per_component: pos_integer() | nil,
          file: binary() | nil,
          additional_objects: list(),
          dictionary: map(),
          image_data: binary()
        }

  @doc """
  Build a JPEG image struct from binary file data and options.

  Options:
  - `:file` (binary, required): JPEG bytes
  - `:resource_identifier` (any, optional): identifier for the document builder
  - `:doc` (struct | nil, optional): reserved for parity; unused for JPEG
  """
  @spec new(Keyword.t()) :: t()
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
  @spec add_size(t()) :: t()
  def add_size(image) do
    %{image | size: byte_size(image.image_data)}
  end

  @doc """
  Compute and attach the PDF image dictionary for the JPEG, including CMYK
  decode inversion when `color_type` is 4.
  """
  @spec add_dictionary_and_additional_objects(t(), any()) :: t()
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
  @spec decode(binary()) :: t()
  def decode(image_data) do
    parse(image_data)
  end

  # Parse start marker, then delegate to segment-based parsing
  @doc false
  defp parse(<<255, 216, rest::binary>>), do: parse(rest)

  # SOF markers we support: on hit, parse image info and stop gathering
  [192, 193, 194, 195, 197, 198, 199, 201, 202, 203, 205, 206, 207]
  |> Enum.each(fn code ->
    @doc false
    defp parse(<<255, unquote(code), _length::unsigned-integer-size(16), rest::binary>>),
      do: parse_image_data(rest)
  end)

  # Skip unknown/other segments by consuming declared segment length
  @doc false
  defp parse(<<255, _code, length::unsigned-integer-size(16), rest::binary>>) do
    {:ok, data} = chomp(rest, length - 2)
    parse(data)
  end

  # Extract bits per component, height, width, and component count (color type)
  @doc false
  def parse_image_data(
        <<bits, height::unsigned-integer-size(16), width::unsigned-integer-size(16), color_type,
          _rest::binary>>
      ) do
    %__MODULE__{bits_per_component: bits, height: height, width: width, color_type: color_type}
  end

  @doc false
  def parse_image_data(_, _), do: {:error, :parse_error}

  # Advance over a segment of given length
  @doc false
  defp chomp(data, length) do
    data = :erlang.binary_part(data, {length, byte_size(data) - length})
    {:ok, data}
  end

  # Map JPEG component counts to PDF color spaces
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
