defmodule Mudbrick.MetadataTest do
  use ExUnit.Case, async: true

  import Mudbrick
  import Mudbrick.Predicates
  import Mudbrick.TestHelper

  alias Mudbrick.Document
  alias Mudbrick.Stream

  test "gets compressed" do
    rendered = new(compress: true) |> render() |> IO.iodata_to_binary()
    refute rendered =~ "xpacket"
    assert rendered |> has_text?("xpacket")
  end

  describe "defaults" do
    test "to having no creator names" do
      rendered = new() |> render()
      refute rendered |> has_text?("dc:creator")
    end

    test "to having no creation / modification dates" do
      rendered = new() |> render()
      refute rendered |> has_text?("xmp:CreateDate")
      refute rendered |> has_text?("xmp:ModifyDate")
    end

    test "to advertising this software" do
      rendered = new() |> render()

      assert rendered |> has_text?("<pdf:Producer>Mudbrick</pdf:Producer>")
      assert rendered |> has_text?("<xmp:CreatorTool>Mudbrick</xmp:CreatorTool>")
    end
  end

  test "metadata is rendered in the metadata stream" do
    rendered =
      new(
        creators: ["Andrew", "Jules"],
        creator_tool: "my tool",
        producer: "some other software",
        title: "my lovely pdf",
        create_date: ~U[2012-12-25 12:34:56Z],
        modify_date: ~U[2022-12-01 12:34:56Z]
      )
      |> Document.find_object(fn
        %Stream{additional_entries: entries} -> entries[:Type] == :Metadata
        _ -> false
      end)
      |> show()

    assert rendered =~ ~s(/Type /Metadata)
    assert rendered =~ ~s(/Subtype /XML)
    assert rendered =~ ~s(dc:creator)
    assert rendered =~ ~s(rdf:li>Andrew)
    assert rendered =~ ~s(rdf:li>Jules)
    assert rendered =~ ~s(<rdf:li xml:lang="x-default">my lovely pdf</rdf:li>)
    assert rendered =~ "<pdf:Producer>some other software</pdf:Producer>"
    assert rendered =~ "<xmp:CreatorTool>my tool</xmp:CreatorTool>"
    assert rendered =~ "<xmp:CreateDate>2012-12-25T12:34:56Z</xmp:CreateDate>"
    assert rendered =~ "<xmp:ModifyDate>2022-12-01T12:34:56Z</xmp:ModifyDate>"
  end

  test "document and instance IDs are unique to options" do
    opts_1 = []
    opts_2 = [title: "hi there"]

    [ids_1, ids_2] =
      for opts <- [opts_1, opts_2] do
        rendered =
          new(opts)
          |> Document.find_object(fn
            %Stream{additional_entries: entries} -> entries[:Type] == :Metadata
            _ -> false
          end)
          |> show()

        [document_id] =
          Regex.run(~r/xmpMM:DocumentID>(.*?)</s, rendered, capture: :all_but_first)

        [instance_id] =
          Regex.run(~r/xmpMM:InstanceID>(.*?)</s, rendered, capture: :all_but_first)

        assert document_id != instance_id

        {document_id, instance_id}
      end

    assert ids_1 != ids_2
  end
end
