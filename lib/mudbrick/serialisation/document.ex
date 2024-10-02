defimpl String.Chars, for: Mudbrick.Document do
  @initial_generation "00000"
  @free_entries_first_generation "65535"

  alias Mudbrick.Document
  alias Mudbrick.Object

  def to_string(%Document{objects: [catalog | _rest] = raw_objects}) do
    version = "%PDF-2.0"
    objects = Enum.map(raw_objects, &Object.from/1)
    sections = [version] ++ objects

    trailer =
      Object.from(%{
        Size: length(objects) + 1,
        Root: catalog.reference
      })

    """
    #{Enum.join(sections, "\n")}
    xref
    0 #{length(objects) + 1}
    #{offsets(sections)}
    trailer
    #{trailer}
    startxref
    #{offset(sections)}
    %%EOF\
    """
  end

  defp offsets(sections) do
    {_, retval} =
      for section <- sections, reduce: {[], ""} do
        {past_sections, ""} ->
          {[section | past_sections],
           "#{padded_offset(past_sections)} #{@free_entries_first_generation} f "}

        {past_sections, acc} ->
          {[section | past_sections],
           "#{acc}\n#{padded_offset(past_sections)} #{@initial_generation} n "}
      end

    retval
  end

  defp padded_offset(strings) do
    strings
    |> offset()
    |> String.pad_leading(10, "0")
  end

  defp offset(strings) do
    strings
    |> Enum.map(&byte_size("#{&1}\n"))
    |> Enum.sum()
    |> Kernel.to_string()
  end
end
