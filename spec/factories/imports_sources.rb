FactoryBot.define do
  factory :imports_source, class: "Imports::Source" do
    sequence(:key) { |n| "source-#{n}" }
    target_kind { "region" }
    source_role { "canonical_identity" }
    fetch_mode { "manual_file" }
    enabled { true }
    license_key { "test-license" }
    license_url { "https://example.com/license" }
    attribution_text { "Test attribution" }
    display_policy { "public_display_allowed" }
    compliance_notes { nil }
    config { {} }
    last_successful_run_at { nil }
  end
end
