defmodule Mudbrick.ParserTest do
  use ExUnit.Case, async: true

  alias Mudbrick.Parser

  describe "parsing to AST" do
    test "strings bounded by parens" do
      assert Parser.parse("(hello, world!)", :string) == [string: ["hello, world!"]]
      assert Parser.parse("()", :string) == [string: []]
    end

    test "real numbers" do
      assert Parser.parse("0.1", :real) == [real: ["0", ".", "1"]]
    end

    test "booleans" do
      assert Parser.parse("true", :boolean) == [boolean: true]
    end

    test "empty dictionary" do
      assert Parser.parse("<<>>", :dictionary) == [{:dictionary, []}]
    end

    test "nonempty dictionary" do
      assert Parser.parse(
               """
               <</Name 123 /Type /Font
               /Pages 1 0 R
               /Page (hello)
               >>\
               """,
               :dictionary
             ) ==
               [
                 dictionary: [
                   {:pair, [name: "Name", integer: ["123"]]},
                   {:pair, [name: "Type", name: "Font"]},
                   {:pair, [name: "Pages", indirect_reference: ["1", "0", "R"]]},
                   {:pair, [name: "Page", string: ["hello"]]}
                 ]
               ]
    end

    test "dictionary in a dictionary" do
      assert Parser.parse("<</Font <</Type /CIDFont>>>>", :dictionary) ==
               [
                 dictionary: [
                   pair: [
                     name: "Font",
                     dictionary: [
                       {:pair,
                        [
                          name: "Type",
                          name: "CIDFont"
                        ]}
                     ]
                   ]
                 ]
               ]
    end

    test "empty array" do
      assert Parser.parse("[]", :array) == [{:array, []}]
    end

    test "empty array inside array" do
      assert Parser.parse("[[]]", :array) == [{:array, [array: []]}]
    end

    test "nonempty nested array" do
      assert Parser.parse("[[true false] true]", :array) == [
               {:array, [array: [boolean: true, boolean: false], boolean: true]}
             ]
    end

    test "array with negative integers" do
      assert Parser.parse("[-416 -326 1379 924]", :array) == [
               {:array,
                [
                  integer: ["-", "416"],
                  integer: ["-", "326"],
                  integer: ["1379"],
                  integer: ["924"]
                ]}
             ]
    end

    test "true on its own in an array" do
      assert Parser.parse("[true]", :array) == [
               {:array, [boolean: true]}
             ]
    end

    test "text blocks" do
      assert Parser.parse(
               """
               BT
               /F1 12 Tf
               14.399999999999999 TL
               0 0 0 rg
               [ <00D5> 24 <00C0> <00ED> <00ED> <00FC> <0195> <01B7> <0138> <00FC> <010F> 12 <00ED> <00BB> <0197> ] TJ
               ET
               BT
               /F2 12 Tf
               14.399999999999999 TL
               0 0 0 rg
               [ <0105> 44 <00EA> <011E> <011E> <012C> <01F0> <0109> <0125> <01F0> <00C3> <0125> <012C> 35 <015A> 13 <0105> 1 3 <00EA> 63 <014B> <01F0> 13 <00FF> <012C> <0125> <015A> ] TJ
               ET\
               """,
               :text_blocks
             ) == [
               text_block: [
                 BT: [],
                 Tf: ["1", "12"],
                 TL: [real: ["14", ".", "399999999999999"]],
                 rg: [integer: ["0"], integer: ["0"], integer: ["0"]],
                 TJ: [
                   glyph_id: "00D5",
                   offset: "24",
                   glyph_id: "00C0",
                   glyph_id: "00ED",
                   glyph_id: "00ED",
                   glyph_id: "00FC",
                   glyph_id: "0195",
                   glyph_id: "01B7",
                   glyph_id: "0138",
                   glyph_id: "00FC",
                   glyph_id: "010F",
                   offset: "12",
                   glyph_id: "00ED",
                   glyph_id: "00BB",
                   glyph_id: "0197"
                 ],
                 ET: []
               ],
               text_block: [
                 BT: [],
                 Tf: ["2", "12"],
                 TL: [real: ["14", ".", "399999999999999"]],
                 rg: [integer: ["0"], integer: ["0"], integer: ["0"]],
                 TJ: [
                   {:glyph_id, "0105"},
                   {:offset, "44"},
                   {:glyph_id, "00EA"},
                   {:glyph_id, "011E"},
                   {:glyph_id, "011E"},
                   {:glyph_id, "012C"},
                   {:glyph_id, "01F0"},
                   {:glyph_id, "0109"},
                   {:glyph_id, "0125"},
                   {:glyph_id, "01F0"},
                   {:glyph_id, "00C3"},
                   {:glyph_id, "0125"},
                   {:glyph_id, "012C"},
                   {:offset, "35"},
                   {:glyph_id, "015A"},
                   {:offset, "13"},
                   {:glyph_id, "0105"},
                   {:offset, "1"},
                   {:offset, "3"},
                   {:glyph_id, "00EA"},
                   {:offset, "63"},
                   {:glyph_id, "014B"},
                   {:glyph_id, "01F0"},
                   {:offset, "13"},
                   {:glyph_id, "00FF"},
                   {:glyph_id, "012C"},
                   {:glyph_id, "0125"},
                   {:glyph_id, "015A"}
                 ],
                 ET: []
               ]
             ]
    end
  end
end
