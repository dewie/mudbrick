defmodule Mudbrick.TextBlock do
  defstruct align: :left,
            font: nil,
            font_size: nil,
            lines: [],
            position: {0, 0}

  defmodule Line do
    defstruct parts: []

    defmodule Part do
      defstruct colour: {0, 0, 0},
                text: ""

      def wrap(text, opts) do
        struct!(%Part{text: text}, opts)
      end
    end

    def wrap(text, opts) do
      %Line{parts: [Part.wrap(text, opts)]}
    end
  end

  defmodule Output do
    defstruct operations: []

    alias Mudbrick.ContentStream.{BT, ET}
    alias Mudbrick.ContentStream.Rg
    alias Mudbrick.ContentStream.Td
    alias Mudbrick.ContentStream.Tf
    alias Mudbrick.ContentStream.{Tj, Apostrophe}
    alias Mudbrick.ContentStream.TL
    alias Mudbrick.Font

    def from(
          %Mudbrick.TextBlock{
            align: :left,
            font: font,
            font_size: font_size,
            position: {x, y}
          } = tb
        ) do
      output =
        %Output{}
        |> start_block()
        |> add(%Tf{font: font, size: font_size})
        |> add(%TL{leading: leading(tb)})
        |> add(%Td{tx: x, ty: y})
        |> then(fn output ->
          [%Line{parts: first_parts} | other_lines] = tb.lines |> Enum.reverse()

          output
          |> then(
            &List.foldr(first_parts, &1, fn %Line.Part{text: text, colour: colour}, acc ->
              acc
              |> colour(colour)
              |> add(%Tj{font: font, text: text})
            end)
          )
          |> then(fn output ->
            for %Line{parts: parts} <- other_lines, reduce: output do
              acc ->
                {_, acc} =
                  List.foldr(parts, {false, acc}, fn
                    %Line.Part{text: text, colour: colour}, {false, inner_acc} ->
                      {
                        true,
                        inner_acc
                        |> colour(colour)
                        |> add(%Apostrophe{font: font, text: text})
                      }

                    %Line.Part{text: text, colour: colour}, {true, inner_acc} ->
                      {
                        true,
                        inner_acc
                        |> colour(colour)
                        |> add(%Tj{font: font, text: text})
                      }
                  end)

                acc
            end
          end)
        end)
        |> end_block()

      output.operations
    end

    def from(
          %Mudbrick.TextBlock{
            align: :right,
            font: font,
            font_size: font_size
          } = tb
        ) do
      output =
        %Output{}
        |> start_block()
        |> add(%Tf{font: font, size: font_size})
        |> add(%TL{leading: leading(tb)})
        |> then(fn output ->
          [%{parts: [first_part]} | rest] = Enum.reverse(tb.lines)

          output
          |> right_offset(tb, first_part.text, 1)
          |> add(%Tj{font: font, text: first_part.text})
          |> end_block()
          |> then(fn output ->
            {_line, output} =
              for %{parts: [part]} <- rest, reduce: {2, output} do
                {line, acc} ->
                  {
                    line + 1,
                    acc
                    |> start_block()
                    |> right_offset(tb, part.text, line)
                    |> add(%Tj{font: font, text: part.text})
                    |> end_block()
                  }
              end

            output
          end)
        end)

      output.operations
    end

    defp start_block(output) do
      add(output, %BT{})
    end

    defp end_block(output) do
      add(output, %ET{})
    end

    defp right_offset(output, tb, text, line) do
      n = line - 1
      {x, y} = tb.position

      add(output, %Td{
        tx: x - Font.width(tb.font, tb.font_size, text),
        ty: y - leading(tb) * n
      })
    end

    defp colour(output, {r, g, b}) do
      new_colour = %Rg{r: r, g: g, b: b}
      latest_colour = Enum.find(output.operations, &match?(%Rg{}, &1)) || %Rg{r: 0, g: 0, b: 0}

      if latest_colour != new_colour do
        add(output, new_colour)
      else
        output
      end
    end

    defp add(%__MODULE__{} = output, op) do
      Map.update!(output, :operations, &[op | &1])
    end

    defp leading(tb) do
      tb.font_size * 1.2
    end
  end

  alias Line.Part
  alias Mudbrick.ContentStream.{BT, ET}
  alias Mudbrick.ContentStream.Td
  alias Mudbrick.ContentStream.Tf
  alias Mudbrick.ContentStream.{Tj, Apostrophe}
  alias Mudbrick.ContentStream.TL
  alias Mudbrick.Font

  def new(opts \\ []) do
    struct!(__MODULE__, opts)
  end

  def write(tb, text, opts \\ []) do
    Map.update!(tb, :lines, fn
      [] ->
        for text <- String.split(text, "\n"), reduce: [] do
          acc -> [Line.wrap(text, opts) | acc]
        end

      [%Line{} = previous_line | existing_lines] ->
        [first_new_line_text | new_line_texts] = String.split(text, "\n")

        previous_line =
          Map.update!(previous_line, :parts, &[Part.wrap(first_new_line_text, opts) | &1])

        for text <- new_line_texts, reduce: [previous_line | existing_lines] do
          acc -> [Line.wrap(text, opts) | acc]
        end
    end)
  end
end
