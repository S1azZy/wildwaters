require "rails_helper"

RSpec.describe Imports::GeoNames::EnqueueRegionImport, type: :interactor do
  include ActiveJob::TestHelper

  subject(:result) { described_class.call(input:) }

  let(:input) do
    {
      source_key: "geonames_regions",
      countries: %w[AD FR],
      languages: %w[en ru],
      feature_codes: %w[PCLI ADM1],
      download_alternate_names: true,
      mode: Imports::Run::MODES[:full],
      queue: "imports",
      download_dir: "tmp/imports/geonames",
      initiated_by: "imports:geonames:enqueue"
    }
  end

  around do |example|
    previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
    example.run
  ensure
    clear_enqueued_jobs
    ActiveJob::Base.queue_adapter = previous_adapter
  end

  it "creates one run with a persisted settings snapshot and one queued item per country" do
    expect { result }.to change(Imports::Run, :count).by(1)
      .and change(Imports::RunItem, :count).by(2)

    run = result.value!.fetch(:run)

    expect_run_snapshot_to_match(run)
    expect_country_items_to_match(run)
  end

  it "keeps source metadata stable instead of storing run artifact settings on the source config" do
    result

    source = Imports::Source.find_by!(key: "geonames_regions")

    expect(source.config).to eq({})
    expect(source).to have_attributes(
      target_kind: "region",
      source_role: Imports::Source::SOURCE_ROLES[:canonical_identity],
      fetch_mode: Imports::Source::FETCH_MODES[:dump],
      license_key: "geonames"
    )
  end

  it "enqueues one Active Job per item with only the item id" do
    result

    run = result.value!.fetch(:run)

    run.items.each do |item|
      expect(Imports::GeoNames::ImportRunItemJob).to have_been_enqueued.with(item.id).on_queue("imports")
    end
  end

  def expect_run_snapshot_to_match(run)
    expect(run).to have_attributes(
      status: Imports::Run::STATUSES[:running],
      mode: Imports::Run::MODES[:full],
      initiated_by: "imports:geonames:enqueue"
    )
    expect(run.params).to include(
      "countries" => %w[AD FR],
      "languages" => %w[en ru],
      "feature_codes" => %w[PCLI ADM1],
      "download_alternate_names" => true,
      "queue" => "imports",
      "download_dir" => "tmp/imports/geonames"
    )
  end

  def expect_country_items_to_match(run)
    expect(run.items.order(:item_key).pluck(:item_kind, :item_key, :country_code, :status)).to eq(
      [
        [ "country", "AD", "AD", Imports::RunItem::STATUSES[:queued] ],
        [ "country", "FR", "FR", Imports::RunItem::STATUSES[:queued] ]
      ]
    )
    expect(run.items.find_by!(item_key: "AD").params).to include(
      "countries" => [ "AD" ],
      "country_code" => "AD",
      "artifact_dir" => "tmp/imports/geonames/#{run.id}/AD"
    )
  end
end
