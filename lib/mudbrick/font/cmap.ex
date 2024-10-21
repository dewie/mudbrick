defmodule Mudbrick.Font.CMap do
  @moduledoc false

  defstruct compress: false,
            parsed: nil

  def new(opts) do
    struct!(__MODULE__, opts)
  end

  defimpl Mudbrick.Object do
    def from(cmap) do
      pairs =
        cmap.parsed.gid2cid
        |> Enum.map(fn {gid, cid} ->
          ["<", Mudbrick.to_hex(gid), "> <", Mudbrick.to_hex(cid), ">\n"]
        end)
        |> Enum.sort()

      data = [
        """
        /CIDInit /ProcSet findresource begin
        12 dict begin
        begincmap
        /CIDSystemInfo
        <</Registry (Adobe)
          /Ordering (UCS)
          /Supplement 0
        >> def
        /CMapName /Adobe-Identity-UCS def
        /CMapType 2 def
        1 begincodespacerange
        <0000> <ffff>
        endcodespacerange
        """,
        pairs |> length() |> to_string(),
        """
         beginbfchar
        """,
        pairs,
        """
        endbfchar
        endcmap
        CMapName currentdict /CMap defineresource pop
        end
        end\
        """
      ]

      Mudbrick.Object.from(
        Mudbrick.Stream.new(
          compress: cmap.compress,
          data: data
        )
      )
    end
  end
end
