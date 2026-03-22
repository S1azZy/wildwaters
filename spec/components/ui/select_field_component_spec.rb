require "rails_helper"

RSpec.describe Ui::SelectFieldComponent, type: :component do
  def build_component(**overrides)
    described_class.new(**{
      name: "region",
      label: "Region",
      options: [ [ "Bali", "bali" ], [ "Iceland", "iceland" ] ],
      prompt: "Choose a region",
      selected: "iceland",
      supporting_text: "Filter the public waterfall catalog"
    }.merge(overrides))
  end

  describe ".new" do
    it "inherits from ApplicationComponent" do
      expect(described_class).to be < ApplicationComponent
    end

    it "defaults to a medium select" do
      component = described_class.new(name: "region", label: "Region", options: [])

      expect(component.name).to eq("region")
      expect(component.label).to eq("Region")
      expect(component.size).to eq(:md)
      expect(component.disabled).to be(false)
      expect(component.error).to be_nil
    end

    it "requires either a visible label or an aria label" do
      expect { described_class.new(name: "region", options: []) }.to raise_error(
        ArgumentError,
        /label or aria_label/
      )
    end

    it "rejects unknown sizes" do
      expect { described_class.new(name: "region", label: "Region", options: [], size: :xl) }.to raise_error(
        ArgumentError,
        /Unknown select field size/
      )
    end
  end

  it "renders a matching select field shell with prompt and options" do
    render_inline(build_component)

    expect(page).to have_css("[data-ui='select-field'][data-size='md'][data-state='default']")
    expect(page).to have_select("Region", selected: "Iceland", options: [ "Choose a region", "Bali", "Iceland" ])
    expect(page).to have_css("[data-ui='select-field-supporting-text']", text: "Filter the public waterfall catalog")
  end

  it "renders error and disabled semantics" do
    render_inline(build_component(label: nil, aria_label: "Region", options: [ [ "Bali", "bali" ] ], error: "Choose a region", disabled: true))

    expect(page).to have_css("[data-ui='select-field'][data-state='error']")
    expect(page).to have_css("select[aria-label='Region'][disabled][aria-invalid='true']")
    expect(page).to have_css("[data-ui='select-field-error']", text: "Choose a region")
  end
end
