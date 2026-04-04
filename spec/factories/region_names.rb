FactoryBot.define do
  factory :region_name do
    association :region
    import_source_record { nil }
    language_code { "en" }
    sequence(:name) { |n| "Region Name #{n}" }
    normalized_name { nil }
    name_role { "primary" }
    preferred { false }
    searchable { true }
  end
end
