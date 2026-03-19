module Waterfalls
  class ExploreQuery < ApplicationInteractor
    LATITUDE_RANGE = -90.0..90.0
    LONGITUDE_RANGE = -180.0..180.0

    option :input, default: proc { {} }
    option :require_bounds, default: proc { false }

    class ValidationContract < ApplicationContract
      params do
        optional(:west).maybe(:string)
        optional(:south).maybe(:string)
        optional(:east).maybe(:string)
        optional(:north).maybe(:string)
        optional(:region_public_id).maybe(:string)
        optional(:min_height_meters).maybe(:string)
        optional(:plunge_pool).maybe(:string)
        optional(:approach_difficulty).maybe(:string)
      end
    end

    def call
      bounds = yield parse_bounds

      Success(waterfalls: filtered_scope(bounds))
    end

    def validate_contract(validation_contract)
      return Success() unless validation_contract

      validation_contract.new.call(normalized_input)
    end

    private

    def parse_bounds
      return invalid_bounds if require_bounds && bounds_absent?
      return Success(nil) if bounds_absent?
      return invalid_bounds if bounds_partial?

      west = parse_float(normalized_input[:west])
      south = parse_float(normalized_input[:south])
      east = parse_float(normalized_input[:east])
      north = parse_float(normalized_input[:north])

      return invalid_bounds unless coordinates_valid?(west:, south:, east:, north:)

      Success(west:, south:, east:, north:)
    end

    def filtered_scope(bounds)
      scope = Waterfall.with_public_spot_data.ordered_for_catalog
      scope = filter_by_region(scope)
      scope = filter_by_min_height(scope)
      scope = filter_by_plunge_pool(scope)
      scope = filter_by_approach_difficulty(scope)
      filter_by_bounds(scope, bounds)
    end

    def filter_by_region(scope)
      return scope if normalized_input[:region_public_id].blank?

      region = Region.find_by(public_id: normalized_input[:region_public_id])
      return scope.none unless region

      scope.for_region_subtree(region)
    end

    def filter_by_min_height(scope)
      return scope if normalized_input[:min_height_meters].blank?

      height_meters = parse_float(normalized_input[:min_height_meters])
      return scope.none unless height_meters

      scope.minimum_height(height_meters)
    end

    def filter_by_plunge_pool(scope)
      return scope if normalized_input[:plunge_pool].blank?

      scope.with_plunge_pool(ActiveModel::Type::Boolean.new.cast(normalized_input[:plunge_pool]))
    end

    def filter_by_approach_difficulty(scope)
      return scope if normalized_input[:approach_difficulty].blank?

      scope.with_approach_difficulty(normalized_input[:approach_difficulty])
    end

    def filter_by_bounds(scope, bounds)
      return scope unless bounds

      scope.within_bounds(**bounds)
    end

    def bounds_absent?
      [ normalized_input[:west], normalized_input[:south], normalized_input[:east], normalized_input[:north] ].all?(&:blank?)
    end

    def bounds_partial?
      [ normalized_input[:west], normalized_input[:south], normalized_input[:east], normalized_input[:north] ].any?(&:blank?)
    end

    def coordinates_valid?(west:, south:, east:, north:)
      LONGITUDE_RANGE.cover?(west) &&
        LONGITUDE_RANGE.cover?(east) &&
        LATITUDE_RANGE.cover?(south) &&
        LATITUDE_RANGE.cover?(north) &&
        west < east &&
        south < north
    end

    def invalid_bounds
      fail_with(code: :validation_error, errors: { bounds: [ "invalid" ] })
    end

    def parse_float(value)
      Float(value)
    rescue ArgumentError, TypeError
      nil
    end

    def normalized_input
      @normalized_input ||= input.to_h.symbolize_keys
    end
  end
end
