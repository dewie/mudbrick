defmodule Mudbrick.Parser.Helpers do
  import NimbleParsec

  def eol, do: string("\n")
  def whitespace, do: ascii_string([?\n, ?\s], min: 1)

  def version do
    ignore(string("%PDF-"))
    |> integer(1)
    |> ignore(string("."))
    |> integer(1)
    |> ignore(eol())
    |> tag(:version)
  end

  def name do
    ignore(string("/"))
    |> utf8_string(
      [
        not: ?\s,
        not: ?\n,
        not: ?],
        not: ?[,
        not: ?/,
        not: ?<,
        not: ?>
      ],
      min: 1
    )
    |> unwrap_and_tag(:name)
  end

  def non_negative_integer do
    ascii_string([?0..?9], min: 1)
  end

  def negative_integer do
    string("-")
    |> concat(non_negative_integer())
  end

  def indirect_reference do
    non_negative_integer()
    |> ignore(whitespace())
    |> concat(non_negative_integer())
    |> ignore(whitespace())
    |> string("R")
    |> tag(:indirect_reference)
  end

  def integer do
    choice([
      non_negative_integer(),
      negative_integer()
    ])
    |> tag(:integer)
  end

  def real do
    choice([
      non_negative_integer(),
      negative_integer()
    ])
    |> string(".")
    |> optional(non_negative_integer())
    |> tag(:real)
  end

  def number do
    choice([real(), integer()])
  end

  def string do
    ignore(string("("))
    |> optional(ascii_string([not: ?(, not: ?)], min: 1))
    |> ignore(string(")"))
    |> tag(:string)
  end

  def boolean do
    choice([
      string("true") |> replace(true),
      string("false") |> replace(false)
    ])
    |> unwrap_and_tag(:boolean)
  end

  def xref do
    ignore(string("xref"))
    |> ignore(eol())
  end

  def tf do
    ignore(string("/F"))
    |> concat(non_negative_integer())
    |> ignore(whitespace())
    |> concat(non_negative_integer())
    |> ignore(whitespace())
    |> ignore(string("Tf"))
    |> tag(:Tf)
  end

  def tl do
    real()
    |> ignore(string(" TL"))
    |> tag(:TL)
  end

  def rg_stroking do
    three_number_operation("RG")
    |> tag(:RG)
  end

  def rg_non_stroking do
    three_number_operation("rg")
    |> tag(:rg)
  end

  def m do
    two_number_operation("m")
    |> tag(:m)
  end

  def w do
    one_number_operation("w")
    |> tag(:w)
  end

  def glyph_id_hex do
    ignore(string("<"))
    |> ascii_string([?A..?Z, ?0..?9], min: 1)
    |> ignore(string(">"))
    |> unwrap_and_tag(:glyph_id)
  end

  def tj do
    ignore(string("["))
    |> ignore(whitespace())
    |> repeat(
      choice([
        glyph_id_hex(),
        non_negative_integer() |> unwrap_and_tag(:offset)
      ])
      |> ignore(whitespace())
    )
    |> ignore(string("]"))
    |> ignore(whitespace())
    |> ignore(string("TJ"))
    |> tag(:TJ)
  end

  def td do
    two_number_operation("Td")
    |> tag(:Td)
  end

  def l do
    two_number_operation("l")
    |> tag(:l)
  end

  def q_push do
    ignore(string("q")) |> tag(:q)
  end

  def re do
    four_number_operation("re")
    |> tag(:re)
  end

  def s do
    ignore(string("S")) |> tag(:S)
  end

  def t_star do
    ignore(string("T*")) |> tag(:TStar)
  end

  def q_pop do
    ignore(string("Q")) |> tag(:Q)
  end

  def graphics_block do
    q_push()
    |> ignore(whitespace())
    |> repeat(
      choice([
        l(),
        m(),
        re(),
        rg_non_stroking(),
        rg_stroking(),
        s(),
        w()
      ])
      |> ignore(whitespace())
    )
    |> concat(q_pop())
    |> tag(:graphics_block)
  end

  def text_block do
    tag(ignore(string("BT")), :BT)
    |> ignore(whitespace())
    |> repeat(
      choice([
        l(),
        m(),
        q_pop(),
        q_push(),
        rg_non_stroking(),
        rg_stroking(),
        s(),
        td(),
        tf(),
        tj(),
        tl(),
        t_star(),
        w()
      ])
      |> ignore(whitespace())
    )
    |> tag(ignore(string("ET")), :ET)
    |> tag(:text_block)
  end

  defp one_number_operation(operator) do
    number()
    |> ignore(whitespace())
    |> ignore(string(operator))
  end

  defp two_number_operation(operator) do
    number()
    |> ignore(whitespace())
    |> concat(number())
    |> ignore(whitespace())
    |> ignore(string(operator))
  end

  defp three_number_operation(operator) do
    number()
    |> ignore(whitespace())
    |> concat(number())
    |> ignore(whitespace())
    |> concat(number())
    |> ignore(whitespace())
    |> ignore(string(operator))
  end

  defp four_number_operation(operator) do
    number()
    |> ignore(whitespace())
    |> concat(number())
    |> ignore(whitespace())
    |> concat(number())
    |> ignore(whitespace())
    |> concat(number())
    |> ignore(whitespace())
    |> ignore(string(operator))
  end
end
