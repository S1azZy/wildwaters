class WaterfallsController < ApplicationController
  def index
    @waterfalls = Waterfall.with_public_spot_data.ordered_for_catalog
  end

  def show
    @waterfall = Waterfall.with_public_spot_data.find_by!(spots: { public_id: extracted_public_id })
  end

  private

  def extracted_public_id
    waterfall_params.fetch(:slugged_public_id).to_s.split("--", 2).first
  end

  def waterfall_params
    params.permit(:slugged_public_id)
  end
end
