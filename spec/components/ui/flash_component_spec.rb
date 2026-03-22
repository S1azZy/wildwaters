require "rails_helper"

RSpec.describe Ui::FlashComponent, type: :component do
  describe ".new" do
    it "inherits from ApplicationComponent" do
      expect(described_class).to be < ApplicationComponent
    end

    it "defaults to a notice flash" do
      component = described_class.new(message: "Saved")

      expect(component.type).to eq(:notice)
      expect(component.message).to eq("Saved")
      expect(component.title).to be_nil
    end

    it "rejects unsupported flash types" do
      expect { described_class.new(type: :warning, message: "Heads up") }.to raise_error(
        ArgumentError,
        /Unknown flash type/
      )
    end
  end

  describe ".collection_attributes" do
    it "normalizes supported flash types and drops blank messages" do
      flash = ActionDispatch::Flash::FlashHash.new
      flash[:notice] = "Saved"
      flash[:alert] = "Something went wrong"
      flash[:success] = [ "Uploaded", "Published" ]
      flash[:ignored] = ""
      flash[:custom] = "Queued"

      messages = described_class.collection_attributes(flash)

      expect(messages).to eq(
        [
          { type: :notice, message: "Saved" },
          { type: :alert, message: "Something went wrong" },
          { type: :success, message: "Uploaded, Published" },
          { type: :notice, message: "Queued" }
        ]
      )
    end
  end

  it "renders a notice flash with status semantics" do
    render_inline(described_class.new(type: :notice, title: "Saved", message: "Your filters were updated."))

    expect(page).to have_css("[data-ui='flash'][data-tone='notice'][role='status']")
    expect(page).to have_css("[data-ui='flash-title']", text: "Saved")
    expect(page).to have_css("[data-ui='flash-message']", text: "Your filters were updated.")
  end

  it "renders an alert flash with alert semantics" do
    render_inline(described_class.new(type: :alert, message: "Something went wrong."))

    expect(page).to have_css("[data-ui='flash'][data-tone='alert'][role='alert']", text: "Something went wrong.")
  end
end
