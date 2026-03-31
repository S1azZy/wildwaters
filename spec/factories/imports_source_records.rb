FactoryBot.define do
  factory :imports_source_record, class: "Imports::SourceRecord" do
    association :import_source, factory: :imports_source
    record_kind { "region" }
    sequence(:external_uid) { |n| "external-#{n}" }
    external_url { "https://example.com/record" }
    status { "pending" }
    checksum { SecureRandom.hex(16) }
    raw_payload { { "name" => "Bali" } }
    normalized_payload { {} }
    first_seen_at { Time.current }
    last_seen_at { Time.current }
    last_changed_at { Time.current }
    association :last_import_run, factory: :imports_run
  end
end
