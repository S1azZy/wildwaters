FactoryBot.define do
  factory :region do
    sequence(:public_id) { Nanoid.generate(size: Region::PUBLIC_ID_LENGTH) }
    sequence(:name) { |n| "Region #{n}" }
    sequence(:slug) { |n| "region-#{n}" }
    region_kind { Region::REGION_KINDS[:country] }
    country_code { "ID" }
    status { Region::STATUSES[:active] }
    parent { nil }
    summary { nil }
    description { nil }
    center { nil }
  end
end
