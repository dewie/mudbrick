defmodule Mudbrick.ObjectTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Mudbrick.Catalog
  alias Mudbrick.Indirect
  alias Mudbrick.Name
  alias Mudbrick.Object

  describe "indirect object" do
    test "includes object number, static generation and contents" do
      assert Indirect.Ref.new(12)
             |> Indirect.Object.new("Brillig")
             |> Object.from() ==
               """
               12 0 obj
               (Brillig)
               endobj\
               """
    end

    test "ref has number, static generation and letter R" do
      assert Object.from(Indirect.Ref.new(12)) == "12 0 R"
    end
  end

  describe "catalog" do
    test "is a dictionary with a ref to a page tree" do
      ref = Indirect.Ref.new(42)

      assert Indirect.Ref.new(999)
             |> Indirect.Object.new(Catalog.new(page_tree: ref))
             |> Object.from() == """
             999 0 obj
             <</Pages 42 0 R
               /Type /Catalog
             >>
             endobj\
             """
    end
  end

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

      assert Object.from(example) ==
               """
               <</AString (hi there)
                 /IntegerItem 12
                 /StringItem (a string)
                 /SubDictionary <</Item1 0.4
               >>
                 /SubType /DictionaryExample
                 /Type /Example
                 /Version 0.01
               >>\
               """
    end
  end

  describe "names" do
    test "are prefixed with a solidus" do
      assert Object.from(Name.new("Name1")) == "/Name1"
      assert Object.from(Name.new("ASomewhatLongerName")) == "/ASomewhatLongerName"

      assert Object.from(Name.new("A;Name_With-Various***Characters?")) ==
               "/A;Name_With-Various***Characters?"

      assert Object.from(Name.new("1.2")) == "/1.2"
    end

    test "literal whitespace is escaped as hex" do
      assert Object.from(Name.new("hi there")) == "/hi#20there"
    end

    property "characters outside of ! to ~ don't appear as literals" do
      check all s <- string([0..(?! - 1), (?~ + 1)..999], min_length: 1) do
        rendered = Object.from(Name.new(s))
        refute rendered =~ s
        assert rendered =~ "#"
      end
    end
  end

  describe "lists" do
    test "become PDF arrays, elements separated by space" do
      assert Object.from([]) == "[]"

      assert Object.from([549, 3.14, false, "Ralph", :SomeName]) ==
               "[549 3.14 false (Ralph) /SomeName]"
    end
  end

  describe "strings" do
    test "escape certain characters" do
      assert Object.from("\n \r \t \b \f ) ( \\ #{[0xDDD]}") ==
               "(\\n \\r \\t \\b \\f \\) \\( \\ \\ddd)"
    end
  end
end
