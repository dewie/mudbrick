defmodule Mudbrick.PDFObjectTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Mudbrick.Catalog
  alias Mudbrick.IndirectObject
  alias Mudbrick.Name
  alias Mudbrick.PageTree
  alias Mudbrick.PDFObject

  describe "indirect object" do
    test "includes object number, static generation and contents" do
      assert PDFObject.from(IndirectObject.new("Brillig", number: 12)) ==
               """
               12 0 obj
               (Brillig)
               endobj\
               """
    end

    test "reference has number, static generation and letter R" do
      assert PDFObject.from(
               IndirectObject.new("Brillig", number: 12)
               |> IndirectObject.Reference.new()
             ) == "12 0 R"
    end
  end

  describe "catalog" do
    test "is a dictionary with a reference to a page tree" do
      page_tree = IndirectObject.new(PageTree.new(), number: 42)

      catalog =
        IndirectObject.new(Catalog.new(page_tree: IndirectObject.Reference.new(page_tree)),
          number: 999
        )

      assert PDFObject.from(catalog) ==
               """
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

      assert PDFObject.from(example) ==
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
      assert PDFObject.from(Name.new("Name1")) == "/Name1"
      assert PDFObject.from(Name.new("ASomewhatLongerName")) == "/ASomewhatLongerName"

      assert PDFObject.from(Name.new("A;Name_With-Various***Characters?")) ==
               "/A;Name_With-Various***Characters?"

      assert PDFObject.from(Name.new("1.2")) == "/1.2"
    end

    test "literal whitespace is escaped as hex" do
      assert PDFObject.from(Name.new("hi there")) == "/hi#20there"
    end

    property "characters outside of ! to ~ don't appear as literals" do
      check all s <- string([0..(?! - 1), (?~ + 1)..999], min_length: 1) do
        rendered = PDFObject.from(Name.new(s))
        refute rendered =~ s
        assert rendered =~ "#"
      end
    end
  end

  describe "lists" do
    test "become PDF arrays, elements separated by space" do
      assert PDFObject.from([]) == "[]"

      assert PDFObject.from([549, 3.14, false, "Ralph", :SomeName]) ==
               "[549 3.14 false (Ralph) /SomeName]"
    end
  end

  describe "strings" do
    test "escape certain characters" do
      assert PDFObject.from("\n \r \t \b \f ) ( \\ #{[0xDDD]}") ==
               "(\\n \\r \\t \\b \\f \\) \\( \\ \\ddd)"
    end
  end
end
