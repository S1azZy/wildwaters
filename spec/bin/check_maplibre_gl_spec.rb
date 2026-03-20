# rubocop:disable RSpec/SpecFilePathFormat
require "rails_helper"

RSpec.describe MaplibreVersionCheck do
  describe "bin/check-maplibre-gl" do
    it "exits with the CLI status code" do
      allow(described_class).to receive(:run_cli).and_return(7)

      expect { load Rails.root.join("bin/check-maplibre-gl") }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(7)
      end
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
