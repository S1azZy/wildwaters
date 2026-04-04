module Regions
  class CreateRegion < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:name).filled(:string)
        required(:region_kind).filled(:string)
        optional(:parent_id).maybe(:string)
        optional(:slug).maybe(:string)
        optional(:country_code).maybe(:string)
        optional(:summary).maybe(:string)
        optional(:description).maybe(:string)
        optional(:latitude).maybe(:float)
        optional(:longitude).maybe(:float)
      end
    end

    def call
      in_transaction do
        parent = yield find_parent(input[:parent_id])
        region = yield create_region(parent)
        yield create_primary_name(region)
        yield create_closure_rows(region, parent)

        Success(region:)
      end
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    private

    def find_parent(parent_id)
      return Success(nil) if parent_id.blank?

      parent = Region.find_by(id: parent_id)

      return Success(parent) if parent

      fail_with(code: :parent_not_found, errors: { parent_id: [ "not found" ] })
    end

    def create_region(parent)
      region = Region.new(
        parent:,
        name: input[:name],
        slug: input[:slug] || input[:name],
        region_kind: input[:region_kind],
        country_code: input[:country_code],
        summary: input[:summary],
        description: input[:description],
        center: build_center,
        status: Region::STATUSES[:active]
      )

      return Success(region) if region.save

      fail_with(code: :validation_error, errors: region.errors.to_hash)
    end

    def create_primary_name(region)
      region_name = region.region_names.new(
        name: region.name,
        name_role: RegionName::NAME_ROLES[:primary],
        preferred: true,
        searchable: true
      )

      return Success(region_name) if region_name.save

      fail_with(code: :validation_error, errors: region_name.errors.to_hash)
    end

    def create_closure_rows(region, parent)
      now = Time.current
      rows = [
        {
          ancestor_id: region.id,
          descendant_id: region.id,
          depth: 0,
          created_at: now,
          updated_at: now
        }
      ]

      if parent
        rows.concat(
          parent.ancestor_closures.pluck(:ancestor_id, :depth).map do |ancestor_id, depth|
            {
              ancestor_id:,
              descendant_id: region.id,
              depth: depth + 1,
              created_at: now,
              updated_at: now
            }
          end
        )
      end

      RegionClosure.insert_all!(rows)

      Success()
    end

    def build_center
      return if input[:latitude].blank? || input[:longitude].blank?

      Region.spatial_factory.point(input[:longitude], input[:latitude])
    end
  end
end
