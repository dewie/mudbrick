defmodule Mudbrick.Image do
  @moduledoc """
  Back-compat image facade and helpers.

  This module:
  - Detects image format and delegates to `Mudbrick.Images.Jpeg` or `Mudbrick.Images.Png`
  - Provides helpers to register images as PDF objects on a `Mudbrick.Document`
  - Implements a legacy object serialiser (used only for older code paths)
  """
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

  @doc """
  Create an image object by detecting the format and delegating to
  `Mudbrick.Images.Jpeg` or `Mudbrick.Images.Png`.

  Required options:
  - `:file` – raw image bytes
  - `:resource_identifier` – atom reference like `:I1`
  - `:doc` – document context (used by PNG indexed/alpha paths)

  Returns a format-specific struct implementing `Mudbrick.Object`.
  """
  @spec new(Keyword.t()) :: t() | Mudbrick.Images.Jpeg.t() | Mudbrick.Images.Png.t() | {:error, term()}
  def new(opts) do
    case identify_image(opts[:file]) do
      :jpeg ->
        Mudbrick.Images.Jpeg.new(opts)

      :png ->
        Mudbrick.Images.Png.new(opts)

      _else ->
        {:error, :image_format_not_recognised}
    end

  end

  @doc """
  Identify image type by magic bytes.
  Returns `:jpeg`, `:png`, or `{:error, :image_format_not_recognised}`.
  """
  @spec identify_image(binary()) :: :jpeg | :png | {:error, :image_format_not_recognised}
  def identify_image(<<255, 216, _rest::binary>>), do: :jpeg
  def identify_image(<<137, 80, 78, 71, 13, 10, 26, 10, _rest::binary>>), do: :png
  def identify_image(_), do: {:error, :image_format_not_recognised}

  @doc """
  Add images to a document object table, returning the updated document and a
  map of human names to registered image objects.

  The images map is `%{name => image_bytes}`. Each is added via `new/1` and any
  additional objects (e.g., PNG palette or SMask) are appended to the document.
  """
  @spec add_objects(Mudbrick.Document.t(), %{optional(atom() | String.t()) => binary()}) ::
          {Mudbrick.Document.t(), map()}
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
            case Enum.count(image.value.additional_objects) do
              0 ->
                doc

              _ ->
                  {doc, _additional_objects} = Document.add(doc, image.value.additional_objects)
                doc
            end

          {doc, Map.put(image_objects, human_name, image), id + 1}
      end

    {doc, image_objects}
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
