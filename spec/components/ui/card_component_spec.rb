require "rails_helper"

RSpec.describe Ui::CardComponent, type: :component do
  describe ".new" do
    it "inherits from ApplicationComponent" do
      expect(described_class).to be < ApplicationComponent
    end

    it "defaults to the standard card surface" do
      component = described_class.new

      expect(component.variant).to eq(:default)
      expect(component.padding).to eq(:md)
      expect(component.tag).to eq(:div)
    end

    it "rejects unknown variants" do
      expect { described_class.new(variant: :glass) }.to raise_error(
        ArgumentError,
        /Unknown card variant/
      )
    end

    it "rejects unknown padding values" do
      expect { described_class.new(padding: :xl) }.to raise_error(
        ArgumentError,
        /Unknown card padding/
      )
    end
  end

  it "renders the chosen tag and content" do
    render_inline(described_class.new(tag: :section, variant: :elevated, padding: :lg)) { "Card body" }

    expect(page).to have_css(
      "section[data-ui='card'][data-variant='elevated'][data-padding='lg']",
      text: "Card body"
    )
  end
end
