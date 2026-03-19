module Waterfalls
  class MapFeatureCollectionPresenter
    include Rails.application.routes.url_helpers

    def initialize(waterfalls)
      @waterfalls = waterfalls
    end

    def as_json(*)
      {
        type: "FeatureCollection",
        features: waterfalls.map { |waterfall| feature_for(waterfall) }
      }
    end

    private

    attr_reader :waterfalls

    def feature_for(waterfall)
      spot = waterfall.spot
      point = spot.location

      {
        type: "Feature",
        geometry: {
          type: "Point",
          coordinates: [ point.longitude, point.latitude ]
        },
        properties: {
          public_id: spot.public_id,
          path: waterfall_path(spot),
          name: spot.name,
          summary: spot.summary,
          region_name: spot.region.name,
          height_meters: waterfall.height_meters,
          height_label: height_label_for(waterfall),
          plunge_pool: waterfall.plunge_pool,
          plunge_pool_label: plunge_pool_label_for(waterfall),
          approach_difficulty: waterfall.approach_difficulty
        }
      }
    end

    def height_label_for(waterfall)
      return if waterfall.height_meters.blank?

      I18n.t("waterfalls.shared.height", value: waterfall.height_meters)
    end

    def plunge_pool_label_for(waterfall)
      return unless waterfall.plunge_pool?

      I18n.t("waterfalls.index.filters.plunge_pool_yes")
    end
  end
end
