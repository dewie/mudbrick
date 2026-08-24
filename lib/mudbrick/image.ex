defmodule Mudbrick.Image do
  @type t :: %__MODULE__{
          file: iodata(),
          resource_identifier: atom(),
          width: number(),
          height: number(),
          bits_per_component: number(),
          components: 1 | 3 | 4,
          adobe?: boolean(),
          filter: :DCTDecode
        }

  @type scale_dimension :: number() | :auto
  @type scale :: {scale_dimension(), scale_dimension()}
  @type image_option ::
          {:position, Mudbrick.coords()}
          | {:scale, scale()}
          | {:skew, Mudbrick.coords()}
  @type image_options :: [image_option()]

  @enforce_keys [:file, :resource_identifier]
  defstruct [
    :file,
    :resource_identifier,
    :width,
    :height,
    :bits_per_component,
    :filter,
    components: 3,
    adobe?: false
  ]

  defmodule AutoScalingError do
    defexception [:message]
  end

  defmodule Unregistered do
    defexception [:message]
  end

  defmodule NotSupported do
    defexception [:message]
  end

  alias Mudbrick.Document
  alias Mudbrick.Images.Png
  alias Mudbrick.Stream

  @doc false
  @spec new(Keyword.t()) :: t() | Png.t()
  def new(opts) do
    case ExImageInfo.info(opts[:file]) do
      {"image/png", _width, _height, _variant} ->
        Png.new(opts)

      info ->
        struct!(__MODULE__, Keyword.merge(opts, file_dependent_opts(info, opts[:file])))
    end
  end

  @doc false
  # A JPEG's colour space follows from the number of components in its frame
  # header. Declaring the wrong one shifts every scanline against the sample
  # data, which shows up as a sheared, stretched, discoloured image.
  @spec colour_space(t()) :: :DeviceGray | :DeviceRGB | :DeviceCMYK
  def colour_space(%__MODULE__{components: 1}), do: :DeviceGray
  def colour_space(%__MODULE__{components: 4}), do: :DeviceCMYK
  def colour_space(%__MODULE__{}), do: :DeviceRGB

  @doc false
  # Adobe applications store CMYK JPEGs with inverted samples and mark them with
  # an APP14 segment. Such an image needs a /Decode array to be inverted back.
  @spec decode(t()) :: [number()] | nil
  def decode(%__MODULE__{components: 4, adobe?: true}), do: [1, 0, 1, 0, 1, 0, 1, 0]
  def decode(%__MODULE__{}), do: nil

  @doc false
  def add_objects(doc, images) do
    {doc, image_objects, _id} =
      for {human_name, image_data} <- images, reduce: {doc, %{}, 0} do
        {doc, image_objects, id} ->
          {doc, image} =
            add_image(doc, new(file: image_data, resource_identifier: :"I#{id + 1}"))

          {doc, Map.put(image_objects, human_name, image), id + 1}
      end

    {doc, image_objects}
  end

  # A PNG image dictionary may reference a palette and/or a soft mask, each of
  # which is a separate PDF object. Add those first so their references are
  # known before the image dictionary is finalised.
  defp add_image(doc, %Png{} = png) do
    {doc, palette_ref} = maybe_add(doc, Png.palette_object(png))
    {doc, smask_ref} = maybe_add(doc, Png.soft_mask(png))

    refs =
      %{}
      |> put_ref(:palette, palette_ref)
      |> put_ref(:smask, smask_ref)

    Document.add(doc, Png.put_dictionary(png, refs))
  end

  defp add_image(doc, %__MODULE__{} = image) do
    Document.add(doc, image)
  end

  defp maybe_add(doc, nil), do: {doc, nil}

  defp maybe_add(doc, object) do
    {doc, added} = Document.add(doc, object)
    {doc, added.ref}
  end

  defp put_ref(refs, _key, nil), do: refs
  defp put_ref(refs, key, ref), do: Map.put(refs, key, ref)

  @supported_components [1, 3, 4]

  defp file_dependent_opts({"image/jpeg", width, height, _variant}, file) do
    %{components: components, adobe?: adobe?} = jpeg_colour_info(file)

    # Guessing here is what produced sheared, discoloured output before the
    # frame header was read at all; refuse rather than declare a colour space
    # the sample data doesn't match.
    if components not in @supported_components do
      raise NotSupported, "Unsupported number of JPEG colour components: #{components}"
    end

    [
      width: width,
      height: height,
      filter: :DCTDecode,
      bits_per_component: 8,
      components: components,
      adobe?: adobe?
    ]
  end

  defp file_dependent_opts({format, _width, _height, _variant}, _file) do
    raise NotSupported, "Unsupported image format: #{format}"
  end

  defp file_dependent_opts(nil, _file) do
    raise NotSupported, "Unrecognised image format"
  end

  # --- JPEG colour information --------------------------------------------

  # Baseline, extended, progressive and lossless frame headers, both Huffman and
  # arithmetic. The excluded C4/C8/CC markers are tables, not frames.
  @start_of_frame [0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF]

  # Markers that carry no payload, so no length field follows them.
  @standalone [0x01 | Enum.to_list(0xD0..0xD7)]

  # What a JPEG without a readable frame header is assumed to be, which is what
  # every JPEG was assumed to be before the header was read at all.
  @default_components 3

  # Walks the segment lengths rather than scanning for marker bytes: Photoshop
  # and Illustrator embed a whole thumbnail JPEG inside APP1/APP13, and a naive
  # scan would read that thumbnail's frame header instead of the image's.
  defp jpeg_colour_info(<<0xFF, 0xD8, rest::binary>>) do
    info = walk_segments(rest, %{components: nil, adobe?: false})
    %{info | components: info.components || @default_components}
  end

  defp jpeg_colour_info(_file), do: %{components: @default_components, adobe?: false}

  # Start of scan or end of image: no headers left to read. Everything up to
  # here is walked, because APPn segments may follow the frame header.
  defp walk_segments(<<0xFF, marker, _rest::binary>>, acc) when marker in [0xDA, 0xD9], do: acc

  # Any number of fill bytes may precede a marker.
  defp walk_segments(<<0xFF, 0xFF, _rest::binary>> = data, acc) do
    skipped = fill_bytes(data, 0)
    walk_segments(binary_part(data, skipped, byte_size(data) - skipped), acc)
  end

  defp walk_segments(<<0xFF, marker, rest::binary>>, acc) when marker in @standalone,
    do: walk_segments(rest, acc)

  defp walk_segments(<<0xFF, marker, length::16, rest::binary>>, acc) when length >= 2 do
    payload_size = length - 2

    case rest do
      <<payload::binary-size(payload_size), tail::binary>> ->
        walk_segments(tail, segment(marker, payload, acc))

      # The declared length runs past the end of the file. Read what is there:
      # falling back to a guessed colour space is what corrupts the image.
      truncated ->
        segment(marker, truncated, acc)
    end
  end

  defp walk_segments(_rest, acc), do: acc

  # Leaves the final 0xFF in place, since it introduces the marker that follows.
  defp fill_bytes(<<0xFF, rest::binary>>, count), do: fill_bytes(rest, count + 1)
  defp fill_bytes(_rest, count), do: count - 1

  # Hierarchical JPEGs repeat the frame header per frame; the first one decides.
  defp segment(
         marker,
         <<_precision, _height::16, _width::16, components, _rest::binary>>,
         %{components: nil} = acc
       )
       when marker in @start_of_frame,
       do: %{acc | components: components}

  defp segment(0xEE, <<"Adobe", _rest::binary>>, acc), do: %{acc | adobe?: true}

  defp segment(_marker, _payload, acc), do: acc

  defimpl Mudbrick.Object do
    def to_iodata(image) do
      Stream.new(
        data: image.file,
        additional_entries:
          %{
            Type: :XObject,
            Subtype: :Image,
            Width: image.width,
            Height: image.height,
            BitsPerComponent: image.bits_per_component,
            ColorSpace: Mudbrick.Image.colour_space(image),
            Filter: image.filter
          }
          |> put_decode(Mudbrick.Image.decode(image))
      )
      |> Mudbrick.Object.to_iodata()
    end

    defp put_decode(entries, nil), do: entries
    defp put_decode(entries, decode), do: Map.put(entries, :Decode, decode)
  end
end
