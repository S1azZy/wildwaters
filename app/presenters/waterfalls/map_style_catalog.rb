module Waterfalls
  class MapStyleCatalog
    DEFAULT_STYLE_ID = "outdoors"

    STYLES = [
      {
        id: "outdoors",
        name: "Outdoors",
        label_key: "waterfalls.index.map_styles.outdoors",
        style_url: "https://tiles.stadiamaps.com/styles/outdoors.json"
      },
      {
        id: "liberty",
        name: "Liberty",
        label_key: "waterfalls.index.map_styles.liberty",
        style_url: "https://tiles.openfreemap.org/styles/liberty"
      },
      {
        id: "bright",
        name: "Bright",
        label_key: "waterfalls.index.map_styles.bright",
        style_url: "https://tiles.openfreemap.org/styles/bright"
      },
      {
        id: "positron",
        name: "Positron",
        label_key: "waterfalls.index.map_styles.positron",
        style_url: "https://tiles.openfreemap.org/styles/positron"
      }
    ].freeze

    class << self
      def all
        STYLES
      end

      def default
        fetch(DEFAULT_STYLE_ID)
      end

      def fetch(style_id)
        STYLES.find { |style| style[:id] == style_id.to_s } || STYLES.first
      end
    end
  end
end
