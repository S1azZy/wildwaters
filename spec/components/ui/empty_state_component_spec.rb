require "rails_helper"

RSpec.describe Ui::EmptyStateComponent, type: :component do
  describe ".new" do
    it "inherits from ApplicationComponent" do
      expect(described_class).to be < ApplicationComponent
    end
  end

  it "renders the title and body" do
    render_inline(described_class.new(title: "Nothing here yet", body: "Try another filter."))

    expect(page).to have_css("[data-ui='empty-state']")
    expect(page).to have_css("[data-ui='empty-state-title']", text: "Nothing here yet")
    expect(page).to have_css("[data-ui='empty-state-body']", text: "Try another filter.")
  end

  it "renders optional icon and action slots" do
    component = described_class.new(title: "No waterfalls found", body: "Clear one or more filters.")
    component.with_icon { "~" }
    component.with_action { "Reset filters" }

    render_inline(component)

    expect(page).to have_css("[data-ui='empty-state-icon']", text: "~")
    expect(page).to have_css("[data-ui='empty-state-action']", text: "Reset filters")
  end
end
