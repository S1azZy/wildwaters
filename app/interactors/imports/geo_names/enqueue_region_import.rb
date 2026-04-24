module Imports
  module GeoNames
    class EnqueueRegionImport < ApplicationInteractor
      option :input

      def call
        source = nil
        run = nil
        items = []

        ActiveRecord::Base.transaction do
          source = upsert_source!
          run = create_run!(source:)
          items = create_items!(run:)
        end

        items.each { |item| ImportRunItemJob.set(queue: queue).perform_later(item.id) }

        Success(run:, items:)
      rescue ActiveRecord::RecordNotUnique
        fail_with(code: :run_already_active, errors: { source_key: [ "already has an active run" ] })
      end

      private

      def upsert_source!
        Imports::Source.find_or_initialize_by(key: source_key).tap do |source|
          source.assign_attributes(
            target_kind: "region",
            source_role: Imports::Source::SOURCE_ROLES[:canonical_identity],
            fetch_mode: Imports::Source::FETCH_MODES[:dump],
            enabled: true,
            license_key: "geonames",
            license_url: "https://www.geonames.org/export/",
            attribution_text: "GeoNames",
            display_policy: Imports::Source::DISPLAY_POLICIES[:public_display_allowed]
          )
          source.config ||= {}
          source.save!
        end
      end

      def create_run!(source:)
        source.runs.create!(
          mode: mode,
          status: Imports::Run::STATUSES[:running],
          started_at: Time.current,
          initiated_by: initiated_by,
          params: run_params,
          stats: { "total_item_count" => country_codes.size }
        )
      end

      def create_items!(run:)
        country_codes.map do |country_code|
          run.items.create!(
            item_kind: "country",
            item_key: country_code,
            country_code:,
            status: Imports::RunItem::STATUSES[:queued],
            params: item_params(run:, country_code:)
          )
        end
      end

      def item_params(run:, country_code:)
        run_params.merge(
          "country_code" => country_code,
          "countries" => [ country_code ],
          "artifact_dir" => File.join(download_dir, run.id.to_s, country_code)
        )
      end

      def run_params
        @run_params ||= {
          "source_key" => source_key,
          "countries" => country_codes,
          "languages" => languages,
          "feature_codes" => feature_codes,
          "download_alternate_names" => download_alternate_names,
          "mode" => mode,
          "queue" => queue,
          "download_dir" => download_dir
        }
      end

      def source_key
        input.fetch(:source_key)
      end

      def country_codes
        @country_codes ||= normalize_list(input.fetch(:countries)).map(&:upcase)
      end

      def languages
        @languages ||= normalize_list(input.fetch(:languages)).map(&:downcase)
      end

      def feature_codes
        @feature_codes ||= normalize_list(input.fetch(:feature_codes)).map(&:upcase)
      end

      def download_alternate_names
        input.fetch(:download_alternate_names)
      end

      def mode
        input.fetch(:mode)
      end

      def queue
        input.fetch(:queue)
      end

      def download_dir
        input.fetch(:download_dir)
      end

      def initiated_by
        input.fetch(:initiated_by)
      end

      def normalize_list(value)
        Array(value)
          .flat_map { |item| item.to_s.split(",") }
          .map(&:strip)
          .reject(&:blank?)
          .uniq
      end
    end
  end
end
