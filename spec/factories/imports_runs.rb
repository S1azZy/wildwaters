FactoryBot.define do
  factory :imports_run, class: "Imports::Run" do
    association :import_source, factory: :imports_source
    mode { "full" }
    status { "running" }
    started_at { Time.current }
    finished_at { nil }
    cursor_in { nil }
    cursor_out { nil }
    stats { {} }
    error_class { nil }
    error_message { nil }
    initiated_by { "system" }
  end
end
