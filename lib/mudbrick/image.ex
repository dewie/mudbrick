defmodule Mudbrick.Image do
  @moduledoc false

  @enforce_keys [:file, :resource_identifier]
  defstruct [
    :file,
    :resource_identifier,
    :width,
    :height,
    :bits_per_component,
    :colour_space,
    :filter
  ]

  defmodule Unregistered do
    defexception [:message]
  end

  defmodule NotSupported do
    defexception [:message]
  end

  alias Mudbrick.Document
  alias Mudbrick.Stream

  def new(opts) do
    struct!(
      __MODULE__,
      Keyword.merge(
        opts,
        file_dependent_opts(ExImageInfo.info(opts[:file]))
      )
    )
  end

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
