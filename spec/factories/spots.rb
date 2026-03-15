FactoryBot.define do
  factory :spot do
    sequence(:public_id) { Nanoid.generate(size: Spot::PUBLIC_ID_LENGTH) }
    association :region
    spot_type { Spot::SPOT_TYPES[:waterfall] }
    sequence(:name) { |n| "Waterfall #{n}" }
    sequence(:slug) { |n| "waterfall-#{n}" }
    summary { "Short editorial summary" }
    description { "Longer editorial description" }
    status { Spot::STATUSES[:draft] }
    location { RGeo::Geographic.spherical_factory(srid: 4326).point(115.1606, -8.2561) }
    published_at { nil }

    trait :published do
      status { Spot::STATUSES[:published] }
      published_at { Time.current }
    end
  end
end
