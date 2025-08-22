defmodule Mudbrick.Image do
  @type t :: %__MODULE__{
          file: iodata(),
          resource_identifier: atom(),
          width: number(),
          height: number(),
          bits_per_component: number(),
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
    dictionary: %{}
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
  alias Mudbrick.Stream

  @doc false
  @spec new(Keyword.t()) :: t()
  def new(opts) do
    case identify_image(opts[:file]) do
      :jpeg ->
        Mudbrick.Images.Jpeg.new(opts)

      :png ->
        Mudbrick.Images.Png.new(opts)

      # Mudbrick.Images.PNG.prepare_image(image_data, objects)

      _else ->
        {:error, :image_format_not_recognised}
    end

    # struct!(
    #   __MODULE__,
    #   Keyword.merge(
    #     opts,
    #     file_dependent_opts(ExImageInfo.info(opts[:file]))
    #   )
    # )

    # struct!(
    #   __MODULE__,
    #   Keyword.merge(
    #     opts,
    #     file_dependent_opts(ExImageInfo.info(opts[:file]))
    #   )
    # )
  end

  def identify_image(<<255, 216, _rest::binary>>), do: :jpeg
  def identify_image(<<137, 80, 78, 71, 13, 10, 26, 10, _rest::binary>>), do: :png
  def identify_image(_), do: {:error, :image_format_not_recognised}

  @doc false
  def add_objects(doc, images) do
    {doc, image_objects, _id} =
      for {human_name, image_data} <- images, reduce: {doc, %{}, 0} do
        {doc, image_objects, id} ->
          {doc, image} =
            Document.add(
              doc,
              new(file: image_data, doc: doc, resource_identifier: :"I#{id + 1}")
            )

          doc =
            case Enum.count(image.value.extra_objects) do
              0 ->
                doc

              _ ->
                {doc, _extra_objects} = Document.add(doc, image.value.extra_objects)
                doc
            end

          {doc, Map.put(image_objects, human_name, image), id + 1}
      end

    {doc, image_objects}
  end

  defp file_dependent_opts({"image/jpeg", width, height, _variant}) do
    [
      width: width,
      height: height,
      filter: :DCTDecode,
      bits_per_component: 8
    ]
  end

  defp file_dependent_opts({"image/png", _width, _height, _variant}) do
    raise NotSupported, "PNGs are currently not supported"
  end

  defimpl Mudbrick.Object do
    def to_iodata(image) do
      Stream.new(
        data: image.file,
        additional_entries: %{
          Type: :XObject,
          Subtype: :Image,
          Width: image.width,
          Height: image.height,
          BitsPerComponent: image.bits_per_component,
          ColorSpace: :DeviceRGB,
          Filter: image.filter
        }
      )
      |> Mudbrick.Object.to_iodata()
    end
  end
end
