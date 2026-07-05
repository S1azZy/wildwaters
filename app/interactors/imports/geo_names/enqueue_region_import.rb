module Imports
  module GeoNames
    class EnqueueRegionImport < ApplicationInteractor
      option :settings_interactor, default: -> { Imports::GeoNames::Settings }

      class EffectiveSettingsContract < ApplicationContract
        params do
          required(:source_key).filled(:string)
          required(:countries).filled(:array)
          required(:languages).filled(:array)
          required(:feature_codes).filled(:array)
          required(:download_alternate_names).filled(:bool)
          required(:mode).filled(:string)
          required(:download_dir).filled(:string)
          required(:initiated_by).filled(:string)
        end
      end

      def call
        settings = yield settings_interactor.call(input: {})
        yield validate_settings(settings)

        source = yield find_source(settings)
        persisted = yield persist_run_with_items(source:, settings:)
        items = persisted.fetch(:items)

        yield enqueue_items(items)

        Success(run: persisted.fetch(:run), items:)
      end

      private

      def validate_settings(settings)
        validation = EffectiveSettingsContract.new.call(settings)
        return Success() if validation.success?

        log_warning_and_return_failure(validation)
      end

      def find_source(settings)
        source = Imports::Source.find_by(key: settings.fetch(:source_key))
        return Success(source) if source

        fail_with(code: :source_not_found, errors: { source_key: [ "not found" ] })
      end

      def persist_run_with_items(source:, settings:)
        run = nil
        items = []

        in_transaction do
          run = yield create_run(source:, settings:)
          items = yield create_items(run:, settings:)
        end

        Success(run:, items:)
      end

      def create_run(source:, settings:)
        safe_call(
          ActiveRecord::RecordNotUnique,
          on_error: ->(_) { fail_with(code: :run_already_active, errors: { source_key: [ "already has an active run" ] }) }
        ) do
          source.runs.create!(
            mode: settings.fetch(:mode),
            status: Imports::Run::STATUSES[:running],
            started_at: Time.current,
            initiated_by: settings.fetch(:initiated_by),
            params: run_params(settings),
            stats: { "total_item_count" => country_codes(settings).size }
          )
        end
      end

      def create_items(run:, settings:)
        safe_call(
          ActiveRecord::RecordNotUnique,
          on_error: ->(_) { fail_with(code: :run_item_already_exists, errors: { item_key: [ "already exists for this run" ] }) }
        ) do
          country_codes(settings).map do |country_code|
            run.items.create!(
              item_kind: "country",
              item_key: country_code,
              status: Imports::RunItem::STATUSES[:queued],
              params: item_params(run:, country_code:, settings:)
            )
          end
        end
      end

      def enqueue_items(items)
        items.each { |item| ImportRunItemJob.perform_later(item.id) }

        Success()
      end

      def item_params(run:, country_code:, settings:)
        run_params(settings).merge(
          "country_code" => country_code,
          "countries" => [ country_code ],
          "artifact_dir" => File.join(settings.fetch(:download_dir), run.id.to_s, country_code)
        )
      end

      def run_params(settings)
        {
          "source_key" => settings.fetch(:source_key),
          "countries" => country_codes(settings),
          "languages" => languages(settings),
          "feature_codes" => feature_codes(settings),
          "download_alternate_names" => settings.fetch(:download_alternate_names),
          "mode" => settings.fetch(:mode),
          "download_dir" => settings.fetch(:download_dir)
        }
      end

      def country_codes(settings)
        normalize_list(settings.fetch(:countries)).map(&:upcase)
      end

      def languages(settings)
        normalize_list(settings.fetch(:languages)).map(&:downcase)
      end

      def feature_codes(settings)
        normalize_list(settings.fetch(:feature_codes)).map(&:upcase)
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
