require "rails_helper"

RSpec.describe Nanoid do
  describe ".generate" do
    subject(:id) { described_class.generate(**options) }

    let(:options) { {} }

    it "returns the default length" do
      expect(id.length).to eq(21)
    end

    it "uses the safe alphabet by default" do
      expect(id).to match(/\A[#{Regexp.escape(described_class::SAFE_ALPHABET)}]+\z/)
    end

    it "does not include underscore or dash in the default alphabet" do
      expect(described_class::SAFE_ALPHABET).not_to include("_", "-")
    end

    context "when a custom size is provided" do
      let(:options) { { size: 12 } }

      it "returns an id with the requested length" do
        expect(id.length).to eq(12)
      end
    end

    context "when a custom alphabet is provided" do
      let(:options) { { size: 24, alphabet: "abc123" } }

      it "uses only characters from the custom alphabet" do
        expect(id).to match(/\A[abc123]+\z/)
      end
    end

    context "when non secure generation is requested" do
      let(:options) { { size: 10, alphabet: "abc", non_secure: true } }

      it "uses only characters from the custom alphabet" do
        expect(id).to match(/\A[abc]+\z/)
      end
    end
  end
end
