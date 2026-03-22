require "rails_helper"

RSpec.describe Ui::FilterChipComponent, type: :component do
  describe ".new" do
    it "inherits from ApplicationComponent" do
      expect(described_class).to be < ApplicationComponent
    end

    it "defaults to an interactive unselected chip" do
      component = described_class.new

      expect(component.selected).to be(false)
      expect(component.disabled).to be(false)
    end
  end

  it "renders an unselected filter chip button" do
    render_inline(described_class.new) { "Nearby" }

    expect(page).to have_css(
      "button[data-ui='filter-chip'][aria-pressed='false'][data-state='default']",
      text: "Nearby"
    )
  end

  it "renders selected and disabled chip states" do
    render_inline(described_class.new(selected: true, disabled: true)) { "Open now" }

    expect(page).to have_css(
      "button[data-ui='filter-chip'][aria-pressed='true'][data-state='selected'][disabled]",
      text: "Open now"
    )
  end
end
