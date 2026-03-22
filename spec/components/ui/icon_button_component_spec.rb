require "rails_helper"

RSpec.describe Ui::IconButtonComponent, type: :component do
  describe ".new" do
    it "inherits from ApplicationComponent" do
      expect(described_class).to be < ApplicationComponent
    end

    it "defaults to the secondary medium circle button" do
      component = described_class.new(label: "Open filters")

      expect(component.label).to eq("Open filters")
      expect(component.variant).to eq(:secondary)
      expect(component.size).to eq(:md)
      expect(component.shape).to eq(:circle)
      expect(component.href).to be_nil
      expect(component.disabled).to be(false)
    end

    it "requires an accessible label" do
      expect { described_class.new(label: nil) }.to raise_error(
        ArgumentError,
        /accessible label/
      )
    end

    it "rejects unknown variants" do
      expect { described_class.new(label: "Open filters", variant: :outlined) }.to raise_error(
        ArgumentError,
        /Unknown icon button variant/
      )
    end
  end

  it "renders an icon-only button with an aria label" do
    render_inline(described_class.new(label: "Open filters", variant: :ghost, size: :sm)) { "?" }

    expect(page).to have_css(
      "button.ui-icon-button.ui-icon-button--ghost.ui-icon-button--sm[aria-label='Open filters']",
      text: "?"
    )
  end

  it "renders a link form when href is provided" do
    render_inline(described_class.new(label: "View map", href: "/")) { "M" }

    expect(page).to have_css("a.ui-icon-button[aria-label='View map'][href='/']", text: "M")
  end

  it "renders disabled semantics for non-link buttons" do
    render_inline(described_class.new(label: "Open filters", disabled: true, shape: :rounded)) { "?" }

    expect(page).to have_css(
      "button.ui-icon-button.ui-icon-button--rounded[aria-label='Open filters'][disabled]"
    )
  end
end
