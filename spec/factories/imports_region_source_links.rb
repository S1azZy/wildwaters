FactoryBot.define do
  factory :imports_region_source_link, class: "Imports::RegionSourceLink" do
    association :region
    association :import_source_record, factory: :imports_source_record
    match_strategy { "external_uid" }
    confidence { 1.0 }
    locked { false }
    primary_identity { false }
    matched_at { Time.current }
  end
end
