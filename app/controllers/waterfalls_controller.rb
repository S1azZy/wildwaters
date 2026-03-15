class WaterfallsController < ApplicationController
  def index
    @waterfalls = Waterfall.joins(:spot)
      .includes(spot: :region)
      .merge(Spot.waterfalls.published)
      .order(published_spot_order)
  end

  def show
    @waterfall = Waterfall.joins(:spot)
      .includes(spot: :region)
      .merge(Spot.waterfalls.published)
      .find_by!(spots: { public_id: extracted_public_id })
  end

  private

  def extracted_public_id
    params.fetch(:slugged_public_id).to_s.split("-", 2).first
  end

  def published_spot_order
    Arel.sql("spots.published_at DESC NULLS LAST, spots.created_at DESC")
  end
end
