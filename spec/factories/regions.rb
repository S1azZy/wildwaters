FactoryBot.define do
  factory :region do
    sequence(:public_id) { Nanoid.generate(size: Region::PUBLIC_ID_LENGTH) }
    sequence(:name) { |n| "Region #{n}" }
    sequence(:slug) { |n| "region-#{n}" }
    region_type { Region::REGION_TYPES[:country] }
    status { Region::STATUSES[:active] }
    parent { nil }
    summary { nil }
    description { nil }
    external_ref { nil }
  end
end
