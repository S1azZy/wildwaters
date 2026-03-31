module Regions
  class SyncImportedRegion < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:region_id).filled(:string)
        required(:name).filled(:string)
        required(:region_kind).filled(:string)
        optional(:parent_id).maybe(:string)
        optional(:country_code).maybe(:string)
        optional(:latitude).maybe(:float)
        optional(:longitude).maybe(:float)
      end
    end

    def call
      in_transaction do
        region = yield find_region
        parent = yield find_parent
        previous_parent_id = region.parent_id

        region.assign_attributes(
          parent:,
          name: input[:name],
          region_kind: input[:region_kind],
          country_code: input[:country_code],
          center: build_center
        )

        return fail_with(code: :validation_error, errors: region.errors.to_hash) unless region.save

        yield rebuild_closure_rows(region) if previous_parent_id != parent&.id

        Success(region:)
      end
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    private

    def find_region
      region = Region.find_by(id: input[:region_id])
      return Success(region) if region

      fail_with(code: :region_not_found, errors: { region_id: [ "not found" ] })
    end

    def find_parent
      return Success(nil) if input[:parent_id].blank?

      parent = Region.find_by(id: input[:parent_id])
      return Success(parent) if parent

      fail_with(code: :parent_not_found, errors: { parent_id: [ "not found" ] })
    end

    def rebuild_closure_rows(region)
      subtree_depths = region.descendant_closures.pluck(:descendant_id, :depth).to_h
      ordered_region_ids = subtree_depths.sort_by { |_region_id, depth| depth }.map(&:first)
      parents_by_id = Region.where(id: ordered_region_ids).pluck(:id, :parent_id).to_h
      now = Time.current

      RegionClosure.where(descendant_id: ordered_region_ids).delete_all

      ordered_region_ids.each do |region_id|
        parent_id = parents_by_id.fetch(region_id)
        rows = [
          {
            ancestor_id: region_id,
            descendant_id: region_id,
            depth: 0,
            created_at: now,
            updated_at: now
          }
        ]

        if parent_id.present?
          rows.concat(
            RegionClosure.where(descendant_id: parent_id).pluck(:ancestor_id, :depth).map do |ancestor_id, depth|
              {
                ancestor_id:,
                descendant_id: region_id,
                depth: depth + 1,
                created_at: now,
                updated_at: now
              }
            end
          )
        end

        RegionClosure.insert_all!(rows)
      end

      Success()
    end

    def build_center
      return if input[:latitude].blank? || input[:longitude].blank?

      Region.spatial_factory.point(input[:longitude], input[:latitude])
    end
  end
end
