defmodule Mudbrick.DictionaryTest do
  use ExUnit.Case, async: true

  alias Mudbrick.Dictionary
  alias Mudbrick.Name

  test "is enclosed in double angle brackets" do
    dict =
      Dictionary.new([
        {Name.new("Type"), Name.new("Example")},
        {Name.new("SubType"), Name.new("DictionaryExample")},
        {Name.new("Version"), 0.01},
        {Name.new("IntegerItem"), 12},
        {Name.new("StringItem"), Mudbrick.String.new("a string")},
        {Name.new("SubDictionary"),
         Dictionary.new([
           {Name.new("Item1"), 0.4}
         ])}
      ])

    assert "#{dict}" ==
             """
             <</Type /Example
               /SubType /DictionaryExample
               /Version 0.01
               /IntegerItem 12
               /StringItem (a string)
               /SubDictionary <</Item1 0.4
             >>
             >>
             """
             |> String.trim_trailing()
  end
end
