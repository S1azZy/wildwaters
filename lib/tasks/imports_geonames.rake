require Rails.root.join("app/models/imports")

namespace :imports do
  namespace :geonames do
    desc "Enqueue queued GeoNames region import items"
    task enqueue: :environment do |rake_task|
      settings = Imports::GeoNames::Settings.from_env(initiated_by: rake_task.name)
      result = Imports::GeoNames::EnqueueRegionImport.call(input: settings.to_h)

      if result.failure?
        failure = result.failure
        raise "Unable to enqueue GeoNames import: #{failure[:code]}"
      end

      run = result.value!.fetch(:run)
      puts "Enqueued GeoNames region import run #{run.id}"
    end

    desc "Retry failed queued GeoNames region import items for RUN_ID"
    task retry_failed: :environment do
      run_id = ENV.fetch("RUN_ID").to_i
      result = Imports::GeoNames::RetryFailedItems.call(input: { import_run_id: run_id })

      if result.failure?
        failure = result.failure
        raise "Unable to retry failed GeoNames import items: #{failure[:code]}"
      end

      puts "Requeued failed GeoNames import items for run #{run_id}"
    end
  end
end
