require "rails_helper"

RSpec.describe Imports::Source do
  it "seeds the canonical GeoNames import source idempotently" do
    expect { load_seed_data }.to change(described_class, :count).by(1)
    expect { load_seed_data }.not_to change(described_class, :count)

    expect(described_class.find_by!(key: "geonames_regions")).to have_attributes(
      target_kind: "region",
      source_role: Imports::Source::SOURCE_ROLES[:canonical_identity],
      fetch_mode: Imports::Source::FETCH_MODES[:dump],
      enabled: true,
      config: {}
    )
  end

  it "seeds canonical GeoNames attribution metadata" do
    load_seed_data

    expect(described_class.find_by!(key: "geonames_regions")).to have_attributes(
      license_key: "geonames",
      license_url: "https://www.geonames.org/export/",
      attribution_text: "GeoNames",
      display_policy: Imports::Source::DISPLAY_POLICIES[:public_display_allowed]
    )
  end

  def load_seed_data
    load Rails.root.join("db/seeds.rb")
  end
end
