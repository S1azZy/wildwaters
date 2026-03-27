require "rails_helper"

RSpec.describe Ui::AuthFooterComponent, type: :component do
  it "renders the footer note and author" do
    render_inline(described_class.new(author: "Designed by Wild Waters", note: "Footer note"))

    expect(page).to have_css("[data-ui='auth-footer']")
    expect(page).to have_css(".auth-footer__note", text: "Footer note")
    expect(page).to have_css(".auth-footer__author", text: "Designed by Wild Waters")
  end
end
