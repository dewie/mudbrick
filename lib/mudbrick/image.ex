defmodule Mudbrick.Image do
  @enforce_keys [:file, :resource_identifier]
  defstruct [:file, :resource_identifier]

  defmodule Unregistered do
    defexception [:message]
  end

  alias Mudbrick.Document
  alias Mudbrick.Stream

  def new(opts) do
    struct!(__MODULE__, opts)
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

  defimpl Mudbrick.Object do
    def from(image) do
      Stream.new(
        data: image.file,
        additional_entries: %{
          Type: :XObject,
          Subtype: :Image,
          Width: 500,
          Height: 477,
          BitsPerComponent: 8,
          ColorSpace: :DeviceRGB,
          Filter: :DCTDecode
        }
      )
      |> Mudbrick.Object.from()
    end
  end
end
