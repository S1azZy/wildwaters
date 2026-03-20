# rubocop:disable RSpec/SpecFilePathFormat
require "rails_helper"
require "stringio"

load Rails.root.join("bin/check-outdated")

RSpec.describe DependencyFreshnessCheck do
  describe ".run" do
    subject(:result) do
      described_class.run(stdout: output, shell_runner: lambda { |*command|
        calls << command
        statuses.fetch(command)
      })
    end

    let(:calls) { [] }
    let(:output) { StringIO.new }
    let(:statuses) do
      {
        [ "bundle", "outdated" ] => false,
        [ "bin/importmap", "outdated" ] => true,
        [ "bin/check-maplibre-gl" ] => false
      }
    end

    it "runs all freshness checks and returns non-zero if any check fails" do
      expect(result).to eq(1)
      expect(calls).to eq(
        [
          [ "bundle", "outdated" ],
          [ "bin/importmap", "outdated" ],
          [ "bin/check-maplibre-gl" ]
        ]
      )
      expect(output.string).to include("bundle outdated")
      expect(output.string).to include("bin/importmap outdated")
      expect(output.string).to include("bin/check-maplibre-gl")
    end

    it "returns zero when all freshness checks succeed" do
      result = described_class.run(shell_runner: ->(*) { true })

      expect(result).to eq(0)
    end
  end

  describe ".run_cli" do
    it "exits with the aggregate status code" do
      allow(described_class).to receive(:run).and_return(4)

      expect { described_class.run_cli }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(4)
      end
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
