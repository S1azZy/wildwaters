module Spots
  class CreateWaterfall < ApplicationInteractor
    option :input

    class ValidationContract < ApplicationContract
      params do
        required(:region_id).filled(:string)
        required(:name).filled(:string)
        required(:latitude).filled(:float)
        required(:longitude).filled(:float)
        optional(:summary).maybe(:string)
        optional(:description).maybe(:string)
        optional(:height_meters).maybe(:float)
        optional(:plunge_pool).maybe(:bool)
        optional(:flow_seasonality).maybe(:string)
        optional(:approach_difficulty).maybe(:string)
        optional(:status).maybe(:string)
      end
    end

    def call
      in_transaction do
        region = yield find_region(input[:region_id])
        spot = yield create_spot(region)
        waterfall = yield create_waterfall(spot)

        Success(spot:, waterfall:)
      end
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    private

    def find_region(region_id)
      region = Region.find_by(id: region_id)

      return Success(region) if region

      fail_with(code: :region_not_found, errors: { region_id: [ "not found" ] })
    end

    def create_spot(region)
      spot = Spot.new(
        region:,
        spot_type: Spot::SPOT_TYPES[:waterfall],
        name: input[:name],
        slug: input[:name],
        summary: input[:summary],
        description: input[:description],
        status: input[:status] || Spot::STATUSES[:draft],
        location: build_location(input[:longitude], input[:latitude])
      )

      return Success(spot) if spot.save

      fail_with(code: :validation_error, errors: spot.errors.to_hash)
    end

    def create_waterfall(spot)
      waterfall = Waterfall.new(
        spot:,
        height_meters: input[:height_meters],
        plunge_pool: input[:plunge_pool],
        flow_seasonality: input[:flow_seasonality],
        approach_difficulty: input[:approach_difficulty]
      )

      return Success(waterfall) if waterfall.save

      fail_with(code: :validation_error, errors: waterfall.errors.to_hash)
    end

    def build_location(longitude, latitude)
      Spot.spatial_factory.point(longitude, latitude)
    end
  end
end
