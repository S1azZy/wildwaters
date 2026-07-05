module Imports
  module Regions
    class SourceLinkRefresher < ApplicationInteractor
      option :input

      class ValidationContract < ApplicationContract
        params do
          required(:source).filled
          required(:source_record).filled
          required(:region).filled
          required(:record).filled(:hash)
        end
      end

      def call
        link = source_record.region_source_link || source_record.build_region_source_link
        link.assign_attributes(
          region:,
          match_strategy: link.match_strategy || match_strategy_for,
          confidence: 1.0,
          primary_identity: source.source_role_canonical_identity?,
          matched_at: Time.current
        )

        return Success(link) if link.save

        fail_with(code: :validation_error, errors: link.errors.to_hash)
      end

      private

      def source
        input.fetch(:source)
      end

      def source_record
        input.fetch(:source_record)
      end

      def region
        input.fetch(:region)
      end

      def record
        input.fetch(:record)
      end

      def match_strategy_for
        return "existing_source_link" if region.source_links.exists?
        return "structural_match" if Region.exists?(id: region.id)

        record[:parent_external_uid].present? ? "canonical_hierarchy_create" : "canonical_root_create"
      end
    end
  end
end
