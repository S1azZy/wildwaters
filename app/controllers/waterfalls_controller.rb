class WaterfallsController < ApplicationController
  MAP_RESULTS_LIMIT = 60

  def index
    @filters = explore_filter_input
    @waterfalls = limited_waterfalls(explore_result(input: @filters))
    @regions = Region.ordered_for_explore
  end

  def map_data
    result = explore_result(input: explore_map_input, require_bounds: true)
    return render_invalid_bounds unless result.success?

    render json: Waterfalls::MapFeatureCollectionPresenter.new(limited_waterfalls(result)).as_json
  end

  def show
    @waterfall = Waterfall.with_public_spot_data.find_by!(spots: { public_id: extracted_public_id })
  end

  private

  def extracted_public_id
    waterfall_params.fetch(:slugged_public_id).to_s.split("--", 2).first
  end

  def render_invalid_bounds
    render json: { error: t("waterfalls.map_data.invalid_bounds") }, status: :unprocessable_content
  end

  def limited_waterfalls(result)
    return Waterfall.none unless result.success?

    result.value![:waterfalls].limit(MAP_RESULTS_LIMIT)
  end

  def explore_result(input:, require_bounds: false)
    Waterfalls::ExploreQuery.call(input:, require_bounds:)
  end

  def explore_filter_params
    params.permit(:region_public_id, :min_height_meters, :plunge_pool, :approach_difficulty)
  end

  def explore_filter_input
    @explore_filter_input ||= explore_filter_params.to_h.compact_blank.symbolize_keys
  end

  def map_bounds_params
    params.permit(:west, :south, :east, :north)
  end

  def map_bounds_input
    @map_bounds_input ||= map_bounds_params.to_h.symbolize_keys
  end

  def explore_map_input
    explore_filter_input.merge(map_bounds_input)
  end

  def waterfall_params
    params.permit(:slugged_public_id)
  end
end
