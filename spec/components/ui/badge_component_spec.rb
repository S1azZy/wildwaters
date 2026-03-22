require "rails_helper"

RSpec.describe Ui::BadgeComponent, type: :component do
  describe ".new" do
    it "inherits from ApplicationComponent" do
      expect(described_class).to be < ApplicationComponent
    end

    it "defaults to a subtle neutral badge" do
      component = described_class.new

      expect(component.tone).to eq(:neutral)
      expect(component.emphasis).to eq(:subtle)
    end

    it "rejects unsupported tones" do
      expect { described_class.new(tone: :danger) }.to raise_error(
        ArgumentError,
        /Unknown badge tone/
      )
    end

    it "rejects unsupported emphasis values" do
      expect { described_class.new(emphasis: :outline) }.to raise_error(
        ArgumentError,
        /Unknown badge emphasis/
      )
    end
  end

  it "renders a semantic badge" do
    render_inline(described_class.new(tone: :primary, emphasis: :solid)) { "Waterfall" }

    expect(page).to have_css(
      "[data-ui='badge'][data-tone='primary'][data-emphasis='solid']",
      text: "Waterfall"
    )
  end
end
