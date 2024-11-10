defmodule Mudbrick.TextBlock.Output do
  @moduledoc false

  defstruct position: nil,
            font: nil,
            font_size: nil,
            operations: [],
            drawings: []

  alias Mudbrick.ContentStream.{BT, ET}
  alias Mudbrick.ContentStream.Rg
  alias Mudbrick.ContentStream.Td
  alias Mudbrick.ContentStream.Tf
  alias Mudbrick.ContentStream.{Apostrophe, Tj}
  alias Mudbrick.ContentStream.TL
  alias Mudbrick.Path
  alias Mudbrick.TextBlock.Line

  defmodule LeftAlign do
    @moduledoc false

    alias Mudbrick.TextBlock.Output

    defp leading(output, line) do
      output
      |> Output.add(%TL{leading: line.leading})
    end

    def reduce_lines(output, [line]) do
      output
      |> leading(line)
      |> reduce_parts(line, Tj, :first_line)
    end

    def reduce_lines(output, [line | lines]) do
      output
      |> leading(line)
      |> reduce_parts(line, Tj, nil)
      |> reduce_lines(lines)
    end

    defp reduce_parts(output, %Line{parts: []}, _operator, :first_line) do
      output
    end

    defp reduce_parts(output, %Line{parts: [part]}, _operator, :first_line) do
      output
      |> Output.add_part(part, Tj)
      |> underline(part)
    end

    defp reduce_parts(output, %Line{parts: []}, _operator, nil) do
      output
      |> Output.add(%Apostrophe{font: output.font, text: ""})
    end

    defp reduce_parts(output, %Line{parts: [part]}, _operator, nil) do
      Output.add_part(output, part, Apostrophe)
      |> underline(part)
    end

    defp reduce_parts(output, %Line{parts: [part | parts]} = line, operator, line_kind) do
      output
      |> Output.add_part(part, operator)
      |> underline(part)
      |> reduce_parts(%{line | parts: parts}, Tj, line_kind)
    end

    defp underline(output, %Line.Part{underline: nil}), do: output

    defp underline(output, part) do
      Map.update!(output, :drawings, fn drawings ->
        [underline_path(output, part) | drawings]
      end)
    end

    defp underline_path(output, part) do
      {x, y} = output.position
      {offset_x, offset_y} = part.left_offset

      x = x + offset_x
      y = y + offset_y - 2

      Path.new()
      |> Path.move(to: {x, y})
      |> Path.line(Keyword.put(part.underline, :to, {x + Line.Part.width(part), y}))
      |> Path.Output.from()
    end
  end

  defmodule RightAlign do
    @moduledoc false

    alias Mudbrick.TextBlock.Output

    def reduce_lines(output, [line], measure) do
      output
      |> Output.end_block()
      |> reduce_parts(line)
      |> measure.(line, 1)
      |> Output.start_block()
    end

    def reduce_lines(output, [line | lines], measure) do
      output
      |> Output.end_block()
      |> reduce_parts(line)
      |> measure.(line, length(lines) + 1)
      |> Output.start_block()
      |> reduce_lines(lines, measure)
    end

    defp reduce_parts(output, %Line{parts: []}) do
      output
    end

    defp reduce_parts(output, %Line{parts: [part]}) do
      Output.add_part(output, part, Tj)
    end

    defp reduce_parts(output, %Line{parts: [part | parts]} = line) do
      output
      |> Output.add_part(part, Tj)
      |> reduce_parts(%{line | parts: parts})
    end
  end

  defp drawings(output) do
    Map.update!(output, :operations, fn ops ->
      for drawing <- output.drawings, reduce: ops do
        ops ->
          Enum.reverse(drawing.operations) ++ ops
      end
    end)
  end

  def from(
        %Mudbrick.TextBlock{
          align: :left,
          font: font,
          font_size: font_size,
          position: position = {x, y}
        } = tb
      ) do
    tl = %TL{leading: tb.leading}
    tf = %Tf{font: font, size: font_size}

    %__MODULE__{position: position, font: font, font_size: font_size}
    |> end_block()
    |> LeftAlign.reduce_lines(tb.lines)
    |> add(%Td{tx: x, ty: y})
    |> add(tl)
    |> add(tf)
    |> start_block()
    |> drawings()
    |> deduplicate(tl)
    |> deduplicate(tf)
    |> Map.update!(:operations, &Enum.reverse/1)
  end

  def from(
        %Mudbrick.TextBlock{
          align: :right,
          font: font,
          font_size: font_size
        } = tb
      ) do
    tf = %Tf{font: font, size: font_size}

    %__MODULE__{font: font, font_size: font_size}
    |> RightAlign.reduce_lines(tb.lines, fn output, line, line_number ->
      right_offset(output, tb, line, line_number)
    end)
    |> add(%TL{leading: tb.leading})
    |> add(tf)
    |> deduplicate(tf)
    |> Map.update!(:operations, &Enum.reverse/1)
  end

  def add(%__MODULE__{} = output, op) do
    Map.update!(output, :operations, &[op | &1])
  end

  def add_part(output, part, operator) do
    output
    |> with_font(
      struct!(operator, font: part.font, text: part.text),
      part
    )
    |> colour(part.colour)
  end

  def with_font(output, op, part) do
    output
    |> add(%Tf{font: output.font, size: output.font_size})
    |> add(op)
    |> add(%Tf{font: part.font, size: part.font_size})
  end

  def colour(output, {r, g, b}) do
    new_colour = Rg.new(r: r, g: g, b: b)
    latest_colour = Enum.find(output.operations, &match?(%Rg{}, &1)) || %Rg{r: 0, g: 0, b: 0}

    if latest_colour == new_colour do
      remove(output, new_colour)
    else
      output
    end
    |> add(new_colour)
  end

  def start_block(output) do
    add(output, %BT{})
  end

  def end_block(output) do
    add(output, %ET{})
  end

  def right_offset(output, tb, line, line_number) do
    n = line_number - 1
    {x, y} = tb.position

    add(output, %Td{
      tx: x - Line.width(line),
      ty: y - tb.leading * n
    })
  end

  defp deduplicate(output, initial_operator) do
    Map.update!(output, :operations, fn ops ->
      ops
      |> deduplicate_update(initial_operator)
      |> Enum.reverse()
    end)
  end

  defp deduplicate_update(ops, initial_operator) do
    {_, ops} =
      List.foldl(ops, {initial_operator, []}, fn
        current_operator, {current_operator, acc} ->
          if current_operator in acc do
            {current_operator, acc}
          else
            {current_operator, [current_operator | acc]}
          end

        op, {current_operator, acc} ->
          if op.__struct__ == initial_operator.__struct__ do
            {op, [op | acc]}
          else
            {current_operator, [op | acc]}
          end
      end)

    ops
  end

  defp remove(output, operation) do
    Map.update!(output, :operations, &List.delete(&1, operation))
  end
end
