require "rails_helper"

RSpec.describe MaplibreVersionCheck do
  describe ".parse_version" do
    it "extracts the vendored maplibre version from the license header" do
      contents = <<~TEXT
        /**
         * MapLibre GL JS
         * @license 3-Clause BSD. Full text of license: https://github.com/maplibre/maplibre-gl-js/blob/v5.21.0/LICENSE.txt
         */
      TEXT

      expect(described_class.parse_version(contents)).to eq("5.21.0")
    end

    it "raises when the version header is missing" do
      expect { described_class.parse_version("missing") }.to raise_error(
        MaplibreVersionCheck::Error,
        /Unable to parse maplibre-gl version/
      )
    end
  end

  describe ".parse_registry_version" do
    it "extracts the latest version from npm registry metadata" do
      body = { version: "5.21.0" }.to_json

      expect(described_class.parse_registry_version(body)).to eq("5.21.0")
    end

    it "raises when the registry payload is malformed" do
      expect { described_class.parse_registry_version({ version: nil }.to_json) }.to raise_error(
        MaplibreVersionCheck::Error,
        /Unable to parse latest maplibre-gl version/
      )
    end
  end

  describe ".call" do
    let(:asset_path) { Rails.root.join("tmp/maplibre-version-check.js") }
    let(:asset_contents) do
      <<~TEXT
        /**
         * MapLibre GL JS
         * @license 3-Clause BSD. Full text of license: https://github.com/maplibre/maplibre-gl-js/blob/v5.21.0/LICENSE.txt
         */
      TEXT
    end

    before do
      File.write(asset_path, asset_contents)
    end

    after do
      File.delete(asset_path) if File.exist?(asset_path)
    end

    it "returns the local and latest versions when they match" do
      result = described_class.call(
        local_asset_path: asset_path,
        latest_version_fetcher: -> { "5.21.0" }
      )

      expect(result).to eq(
        local_version: "5.21.0",
        latest_version: "5.21.0",
        up_to_date: true
      )
    end

    it "returns an outdated result when a newer upstream version exists" do
      result = described_class.call(
        local_asset_path: asset_path,
        latest_version_fetcher: -> { "5.21.1" }
      )

      expect(result).to eq(
        local_version: "5.21.0",
        latest_version: "5.21.1",
        up_to_date: false
      )
    end

    it "raises a wrapped error when the vendored asset is missing" do
      expect do
        described_class.call(
          local_asset_path: Rails.root.join("tmp/missing-maplibre.js"),
          latest_version_fetcher: -> { "5.21.0" }
        )
      end.to raise_error(MaplibreVersionCheck::Error, /Unable to read vendored maplibre-gl asset/)
    end
  end

  describe ".fetch_latest_version" do
    let(:success_response) { instance_double(Net::HTTPSuccess, body: { version: "5.21.0" }.to_json) }

    before do
      allow(success_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    end

    it "returns the latest version from the registry response" do
      allow(Net::HTTP).to receive(:get_response).and_return(success_response)

      expect(described_class.fetch_latest_version).to eq("5.21.0")
    end

    it "raises a wrapped error when the registry request fails" do
      allow(Net::HTTP).to receive(:get_response).and_raise(SocketError, "nope")

      expect { described_class.fetch_latest_version }.to raise_error(
        MaplibreVersionCheck::Error,
        /Unable to fetch latest maplibre-gl version from npm registry: nope/
      )
    end
  end

  describe ".run_cli" do
    subject(:exit_code) do
      described_class.run_cli(
        stdout:,
        stderr:,
        checker:
      )
    end

    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }
    let(:result) do
      {
        local_version: "5.21.0",
        latest_version: "5.21.0",
        up_to_date: true
      }
    end
    let(:checker) { -> { result } }


    it "prints success output and returns zero when current" do
      expect(exit_code).to eq(0)
      expect(stdout.string).to include("maplibre-gl is up to date")
      expect(stderr.string).to be_empty
    end

    context "when the vendored version is outdated" do
      let(:result) do
        {
          local_version: "5.21.0",
          latest_version: "5.21.0",
          up_to_date: false
        }
      end

      it "prints stderr and returns non-zero" do
        expect(exit_code).to eq(1)
        expect(stdout.string).to be_empty
        expect(stderr.string).to include("maplibre-gl is outdated")
      end
    end

    context "when the checker raises an error" do
      let(:checker) { -> { raise MaplibreVersionCheck::Error, "boom" } }

      it "prints stderr and returns non-zero" do
        expect(exit_code).to eq(1)
        expect(stderr.string).to include("maplibre-gl check failed: boom")
      end
    end
  end
end
