FactoryBot.define do
  factory :waterfall do
    association :spot
    height_meters { 15.5 }
    plunge_pool { true }
    flow_seasonality { "year_round" }
    approach_difficulty { "moderate" }
  end
end
