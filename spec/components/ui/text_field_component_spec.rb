require "rails_helper"

RSpec.describe Ui::TextFieldComponent, type: :component do
  def build_component(**overrides)
    described_class.new(**{
      name: "query",
      label: "Search waterfalls",
      value: "Bali",
      supporting_text: "Use region or waterfall name",
      placeholder: "Search"
    }.merge(overrides))
  end

  describe ".new" do
    it "inherits from ApplicationComponent" do
      expect(described_class).to be < ApplicationComponent
    end

    it "defaults to a medium text input" do
      component = described_class.new(name: "query", label: "Search")

      expect(component.name).to eq("query")
      expect(component.label).to eq("Search")
      expect(component.size).to eq(:md)
      expect(component.type).to eq(:text)
      expect(component.disabled).to be(false)
      expect(component.error).to be_nil
    end

    it "requires either a visible label or an aria label" do
      expect { described_class.new(name: "query") }.to raise_error(
        ArgumentError,
        /label or aria_label/
      )
    end

    it "rejects unknown sizes" do
      expect { described_class.new(name: "query", label: "Search", size: :lg) }.to raise_error(
        ArgumentError,
        /Unknown text field size/
      )
    end

    it "generates unique default input ids for repeated fields" do
      first_component = described_class.new(name: "query", label: "Search")
      second_component = described_class.new(name: "query", label: "Search")

      expect(first_component.input_id).not_to eq(second_component.input_id)
    end

    it "preserves an explicit input_id override" do
      component = described_class.new(name: "query", label: "Search", input_id: "search_field")

      expect(component.input_id).to eq("search_field")
    end
  end

  it "renders the shared text field shell with label, icon, and supporting copy" do
    component = build_component
    component.with_leading_icon { "@" }

    render_inline(component)

    expect(page).to have_css("[data-ui='text-field'][data-size='md'][data-state='default']")
    expect(page).to have_css("label", text: "Search waterfalls")
    expect(page).to have_css("[data-ui='text-field-leading-icon']", text: "@")
    expect(page).to have_field("Search waterfalls", with: "Bali", placeholder: "Search")
    expect(page).to have_css("[data-ui='text-field-supporting-text']", text: "Use region or waterfall name")
  end

  it "renders error and disabled semantics" do
    render_inline(build_component(label: nil, aria_label: "Search waterfalls", error: "Search query is required", disabled: true, size: :sm))

    expect(page).to have_css("[data-ui='text-field'][data-size='sm'][data-state='error']")
    expect(page).to have_css("input[aria-label='Search waterfalls'][disabled][aria-invalid='true']")
    expect(page).to have_css("[data-ui='text-field-error']", text: "Search query is required")
  end
end
