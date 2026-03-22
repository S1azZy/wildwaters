require "rails_helper"

RSpec.describe Ui::ButtonComponent, type: :component do
  describe ".new" do
    it "inherits from ApplicationComponent" do
      expect(described_class).to be < ApplicationComponent
    end

    it "defaults to the primary medium button" do
      component = described_class.new

      expect(component.variant).to eq(:primary)
      expect(component.size).to eq(:md)
      expect(component.href).to be_nil
      expect(component.link?).to be(false)
      expect(component.tag_name).to eq(:button)
    end

    it "does not accept unsupported transport options in the public api" do
      expect { described_class.new(method: :delete) }.to raise_error(ArgumentError)
      expect { described_class.new(disabled: true) }.to raise_error(ArgumentError)
    end

    it "treats href buttons as links" do
      component = described_class.new(href: "/waterfalls")

      expect(component.link?).to be(true)
      expect(component.tag_name).to eq(:a)
    end

    it "rejects unknown variants" do
      expect { described_class.new(variant: :ghost) }.to raise_error(
        ArgumentError,
        /Unknown button variant/
      )
    end

    it "rejects unknown sizes" do
      expect { described_class.new(size: :xl) }.to raise_error(
        ArgumentError,
        /Unknown button size/
      )
    end
  end
end
