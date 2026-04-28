FactoryBot.define do
  factory :imports_run_item, class: "Imports::RunItem" do
    association :import_run, factory: :imports_run
    item_kind { "country" }
    item_key { "AD" }
    status { "queued" }
    params { {} }
    artifact_paths { {} }
    stats { {} }
    attempts_count { 0 }
    started_at { nil }
    finished_at { nil }
    error_class { nil }
    error_message { nil }
  end
end
