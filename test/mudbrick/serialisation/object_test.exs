defmodule Mudbrick.ObjectTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Mudbrick.Object

  describe "dictionary (map)" do
    test "is enclosed in double angle brackets" do
      example =
        %{
          Version: 0.01,
          Type: :Example,
          SubType: :DictionaryExample,
          SubDictionary: %{Item1: 0.4},
          StringItem: "a string",
          IntegerItem: 12,
          AString: "hi there"
        }

      assert example |> as_string() ==
               """
               <</Type /Example
                 /AString (hi there)
                 /IntegerItem 12
                 /StringItem (a string)
                 /SubDictionary <</Item1 0.4
               >>
                 /SubType /DictionaryExample
                 /Version 0.01
               >>\
               """
    end
  end

  describe "names (atoms)" do
    test "are prefixed with a solidus" do
      assert as_string(:Name1) == "/Name1"
      assert as_string(:ASomewhatLongerName) == "/ASomewhatLongerName"

      assert as_string(:"A;Name_With-Various***Characters?") ==
               "/A;Name_With-Various***Characters?"

      assert as_string(:"1.2") == "/1.2"
    end

    test "literal whitespace is escaped as hex" do
      assert as_string(:"hi there") == "/hi#20there"
    end

    property "characters outside of ! to ~ don't appear as literals" do
      check all s <- string([0..(?! - 1), (?~ + 1)..999], min_length: 1) do
        rendered = as_string(:"#{s}")
        refute rendered =~ s
        assert rendered =~ "#"
      end
    end
  end

  describe "lists" do
    test "become PDF arrays, elements separated by space" do
      assert as_string([]) == "[]"

      assert as_string([549, 3.14, false, "Ralph", :SomeName]) ==
               "[549 3.14 false (Ralph) /SomeName]"
    end
  end

  describe "strings" do
    test "escape certain characters" do
      assert as_string("\n \r \t \b \f ) ( \\ #{[0xDDD]}") ==
               "(\\n \\r \\t \\b \\f \\) \\( \\ \\ddd)"
    end
  end

  defp as_string(l), do: l |> Object.from() |> to_string()
end
