FactoryBot.define do
  factory :region_closure do
    association :ancestor, factory: :region
    association :descendant, factory: :region
    depth { 1 }
  end
end
