require "spec_helper"

module CardinalityTest
  class SimpleItem < Lutaml::Model::Serializable
    attribute :name, :string
    attribute :value, :integer
  end

  class ComplexItem < Lutaml::Model::Serializable
    attribute :title, :string, default: "Default Title"
    attribute :items, SimpleItem, collection: true
    attribute :single_item, SimpleItem
    attribute :tags, :string, collection: true
    attribute :category, :string, default: -> { "Default Category" }

    xml do
      root "complex-item"
      map_element "title", to: :title
      map_element "item", to: :items
      map_element "single-item", to: :single_item
      map_element "tag", to: :tags
      map_element "category", to: :category
    end
  end

  class CustomMethodItem < Lutaml::Model::Serializable
    attribute :content, :string
    attribute :metadata, :string

    xml do
      root "custom-item"
      map_element "content", with: { to: :content_to_xml, from: :content_from_xml }
      map_element "metadata", to: :metadata
    end

    def content_to_xml(model, parent, doc)
      content_el = doc.create_element("content")
      doc.add_text(content_el, "Custom: #{model.content}")
      doc.add_element(parent, content_el)
    end

    def content_from_xml(model, value)
      model.content = value.sub(/^Custom: /, "")
    end
  end
end

RSpec.describe "Cardinality" do
  describe "JSON serialization" do
    context "when collection: true is not set" do
      it "raises error for multiple elements" do
        json = '{"single_item": [{"name": "Item1", "value": 1}, {"name": "Item2", "value": 2}]}'

        expect do
          CardinalityTest::ComplexItem.from_json(json)
        end.to raise_error(Lutaml::Model::CardinalityError, /single_item/)
      end

      it "accepts single element in array" do
        json = '{"single_item": [{"name": "Item1", "value": 1}]}'
        item = CardinalityTest::ComplexItem.from_json(json)

        expect(item.single_item.name).to eq("Item1")
        expect(item.single_item.value).to eq(1)
      end
    end

    context "with default values" do
      it "handles cardinality with default values" do
        json = '{"items": [{"name": "Item1", "value": 1}]}'
        item = CardinalityTest::ComplexItem.from_json(json)

        expect(item.title).to eq("Default Title")
        expect(item.category).to eq("Default Category")
        expect(item.items.size).to eq(1)
      end
    end
  end

  describe "XML serialization" do
    context "when collection: true is not set" do
      it "raises error for multiple elements" do
        xml = <<~XML
          <complex-item>
            <single-item>
              <name>Item1</name>
              <value>1</value>
            </single-item>
            <single-item>
              <name>Item2</name>
              <value>2</value>
            </single-item>
          </complex-item>
        XML

        expect do
          CardinalityTest::ComplexItem.from_xml(xml)
        end.to raise_error(Lutaml::Model::CardinalityError, /single_item/)
      end

      it "accepts single element" do
        xml = <<~XML
          <complex-item>
            <single-item>
              <name>Item1</name>
              <value>1</value>
            </single-item>
          </complex-item>
        XML

        item = CardinalityTest::ComplexItem.from_xml(xml)
        expect(item.single_item.name).to eq("Item1")
        expect(item.single_item.value).to eq(1)
      end
    end

    context "with custom methods" do
      it "respects cardinality with custom XML methods" do
        xml = <<~XML
          <custom-item>
            <content>Custom: Test Content</content>
            <metadata>Meta Info</metadata>
          </custom-item>
        XML

        item = CardinalityTest::CustomMethodItem.from_xml(xml)
        expect(item.content).to eq("Test Content")
        expect(item.metadata).to eq("Meta Info")
      end
    end

    context "with mixed content and cardinality" do
      it "handles both collection and non-collection attributes" do
        xml = <<~XML
          <complex-item>
            <title>Test Title</title>
            <item>
              <name>Item1</name>
              <value>1</value>
            </item>
            <item>
              <name>Item2</name>
              <value>2</value>
            </item>
            <tag>tag1</tag>
            <tag>tag2</tag>
          </complex-item>
        XML

        item = CardinalityTest::ComplexItem.from_xml(xml)
        expect(item.title).to eq("Test Title")
        expect(item.items.size).to eq(2)
        expect(item.tags).to eq(["tag1", "tag2"])
      end
    end
  end
end
