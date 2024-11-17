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
  alias Mudbrick.ContentStream.{TJ, TStar}
  alias Mudbrick.ContentStream.TL
  alias Mudbrick.Path
  alias Mudbrick.TextBlock.Line

  def from(
        %Mudbrick.TextBlock{
          font: font,
          font_size: font_size,
          position: position
        } = tb
      ) do
    tl = %TL{leading: tb.leading}
    tf = %Tf{font: font, size: font_size}

    %__MODULE__{position: position, font: font, font_size: font_size}
    |> end_block()
    |> reduce_lines(
      tb.lines,
      if(tb.align == :left, do: fn _ -> 0 end, else: &Line.width/1)
    )
    |> td(position)
    |> add(tl)
    |> add(tf)
    |> start_block()
    |> drawings()
    |> deduplicate(tl)
    |> deduplicate(tf)
    |> Map.update!(:operations, &Enum.reverse/1)
  end

  defp add_part(output, part, operator) do
    output
    |> with_font(
      struct!(operator, font: part.font, text: part.text),
      part
    )
    |> colour(part.colour)
  end

  defp add(%__MODULE__{} = output, op) do
    Map.update!(output, :operations, &[op | &1])
  end

  defp remove(output, operation) do
    Map.update!(output, :operations, &List.delete(&1, operation))
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

  defp reduce_lines(output, [line], x_offsetter) do
    output
    |> leading(line)
    |> reset_offset(x_offsetter.(line))
    |> reduce_parts(line, TJ, :first_line, x_offsetter)
    |> offset(x_offsetter.(line))
  end

  defp reduce_lines(output, [line | lines], x_offsetter) do
    output
    |> leading(line)
    |> reset_offset(x_offsetter.(line))
    |> reduce_parts(line, TJ, nil, x_offsetter)
    |> offset(x_offsetter.(line))
    |> reduce_lines(lines, x_offsetter)
  end

  defp reduce_parts(output, %Line{parts: []}, _operator, :first_line, _x_offsetter) do
    output
  end

  defp reduce_parts(output, %Line{parts: [part]} = line, _operator, :first_line, x_offsetter) do
    output
    |> add_part(part, TJ)
    |> underline(part, x_offsetter.(line))
  end

  defp reduce_parts(output, %Line{parts: []}, _operator, nil, _x_offsetter) do
    output
    |> add(%TJ{font: output.font, text: ""})
    |> add(%TStar{})
  end

  defp reduce_parts(output, %Line{parts: [part]} = line, _operator, nil, x_offsetter) do
    output
    |> add_part(part, TJ)
    |> add(%TStar{})
    |> underline(part, x_offsetter.(line))
  end

  defp reduce_parts(
         output,
         %Line{parts: [part | parts]} = line,
         operator,
         line_kind,
         x_offsetter
       ) do
    output
    |> add_part(part, operator)
    |> underline(part, x_offsetter.(line))
    |> reduce_parts(%{line | parts: parts}, TJ, line_kind, x_offsetter)
  end

  defp leading(output, line) do
    output
    |> add(%TL{leading: line.leading})
  end

  defp offset(output, offset) do
    td(output, {-offset, 0})
  end

  defp reset_offset(output, offset) do
    td(output, {offset, 0})
  end

  defp underline(output, %Line.Part{underline: nil}, _line_x_offset), do: output

  defp underline(output, part, line_x_offset) do
    Map.update!(output, :drawings, fn drawings ->
      [underline_path(output, part, line_x_offset) | drawings]
    end)
  end

  defp underline_path(output, part, line_x_offset) do
    {x, y} = output.position
    {offset_x, offset_y} = part.left_offset

    x = x + offset_x - line_x_offset
    y = y + offset_y - part.font_size / 10

    Path.new()
    |> Path.move(to: {x, y})
    |> Path.line(Keyword.put(part.underline, :to, {x + Line.Part.width(part), y}))
    |> Path.Output.from()
  end

  defp drawings(output) do
    Map.update!(output, :operations, fn ops ->
      for drawing <- output.drawings, reduce: ops do
        ops ->
          Enum.reverse(drawing.operations) ++ ops
      end
    end)
  end

  defp td(output, {0, 0}), do: output
  defp td(output, {x, y}), do: add(output, %Td{tx: x, ty: y})

  defp with_font(output, op, part) do
    output
    |> add(%Tf{font: output.font, size: output.font_size})
    |> add(op)
    |> add(%Tf{font: part.font, size: part.font_size})
  end

  defp colour(output, {r, g, b}) do
    new_colour = Rg.new(r: r, g: g, b: b)
    latest_colour = Enum.find(output.operations, &match?(%Rg{}, &1)) || %Rg{r: 0, g: 0, b: 0}

    if latest_colour == new_colour do
      remove(output, new_colour)
    else
      output
    end
    |> add(new_colour)
  end

  defp start_block(output) do
    add(output, %BT{})
  end

  defp end_block(output) do
    add(output, %ET{})
  end
end
