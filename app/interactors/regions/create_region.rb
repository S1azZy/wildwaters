module Regions
  class CreateRegion < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:name).filled(:string)
        required(:region_type).filled(:string)
        optional(:parent_id).maybe(:string)
        optional(:slug).maybe(:string)
        optional(:summary).maybe(:string)
        optional(:description).maybe(:string)
        optional(:external_ref).maybe(:string)
      end
    end

    def call
      in_transaction do
        parent = yield find_parent(input[:parent_id])
        region = yield create_region(parent)
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
        region_type: input[:region_type],
        summary: input[:summary],
        description: input[:description],
        external_ref: input[:external_ref],
        status: Region::STATUSES[:active]
      )

      return Success(region) if region.save

      fail_with(code: :validation_error, errors: region.errors.to_hash)
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
  end
end
