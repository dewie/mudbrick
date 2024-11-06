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
    :filter
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
    struct!(
      __MODULE__,
      Keyword.merge(
        opts,
        file_dependent_opts(ExImageInfo.info(opts[:file]))
      )
    )
  end

  @doc false
  def add_objects(doc, images) do
    {doc, image_objects, _id} =
      for {human_name, image_opts} <- images, reduce: {doc, %{}, 0} do
        {doc, image_objects, id} ->
          image_opts =
            Keyword.put(image_opts, :resource_identifier, :"I#{id + 1}")

          {doc, image} =
            Document.add(
              doc,
              new(Keyword.put(image_opts, :file, Keyword.fetch!(image_opts, :file)))
            )

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
    def from(image) do
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
      |> Mudbrick.Object.from()
    end
  end
end
