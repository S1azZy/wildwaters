class WaterfallsController < ApplicationController
  MAP_RESULTS_LIMIT = 60

  layout "inertia", only: %i[index show]

  def index
    @filters = explore_filter_input
    @waterfalls = limited_waterfalls(explore_result(input: @filters))
    @map_styles = Waterfalls::MapStyleCatalog.all
    @default_map_style = Waterfalls::MapStyleCatalog.default
    @default_map_style_id = @default_map_style.fetch(:id)
    @regions = Region.ordered_for_explore

    render inertia: "Waterfalls/Index", props: waterfall_index_props
  end

  def map_data
    result = explore_result(input: explore_map_input, require_bounds: true)
    return render_invalid_bounds unless result.success?

    render json: Waterfalls::MapFeatureCollectionPresenter.new(limited_waterfalls(result)).as_json
  end

  def show
    @waterfall = Waterfall.with_public_spot_data.find_by!(spots: { public_id: extracted_public_id })

    render inertia: "Waterfalls/Show", props: waterfall_show_props
  end

  private

  def waterfall_index_props
    {
      assets: {
        maplibreScriptUrl: view_context.asset_path("maplibre-gl.js"),
        maplibreStylesheetUrl: view_context.asset_path("maplibre-gl.css")
      },
      copy: waterfall_index_copy_props,
      filters: waterfall_index_filter_props,
      map: {
        defaultStyleId: @default_map_style_id,
        initialLatitude: -8.2601,
        initialLongitude: 115.1889,
        initialZoom: 7.4,
        panelOpenClass: "is-expanded",
        stylePreferenceKey: "wildwaters:explore-map-style"
      },
      mapStyles: waterfall_index_map_style_props,
      regions: waterfall_index_region_props,
      urls: {
        explore: waterfalls_path,
        mapData: map_data_waterfalls_path
      },
      waterfalls: Waterfalls::MapFeatureCollectionPresenter.new(@waterfalls).as_json
    }
  end

  def waterfall_index_copy_props
    {
      title: t("waterfalls.index.title"),
      filters: {
        allRegions: t("waterfalls.index.filters.all_regions"),
        anyDifficulty: t("waterfalls.index.filters.any_difficulty"),
        anyPlungePool: t("waterfalls.index.filters.any_plunge_pool"),
        approachDifficulty: t("waterfalls.index.filters.approach_difficulty"),
        easy: t("waterfalls.index.filters.easy"),
        hard: t("waterfalls.index.filters.hard"),
        minHeight: t("waterfalls.index.filters.min_height"),
        minHeightPlaceholder: t("waterfalls.index.filters.min_height_placeholder"),
        moderate: t("waterfalls.index.filters.moderate"),
        plungePool: t("waterfalls.index.filters.plunge_pool"),
        plungePoolNo: t("waterfalls.index.filters.plunge_pool_no"),
        plungePoolYes: t("waterfalls.index.filters.plunge_pool_yes"),
        region: t("waterfalls.index.filters.region"),
        reset: t("waterfalls.index.filters.reset"),
        search: t("waterfalls.index.filters.search"),
        searchPlaceholder: t("waterfalls.index.filters.search_placeholder")
      },
      map: {
        details: t("waterfalls.index.actions.details"),
        empty: t("waterfalls.index.empty"),
        locate: t("waterfalls.index.actions.locate"),
        mapUnavailable: t("waterfalls.index.map_unavailable"),
        noJavascript: t("waterfalls.index.no_javascript"),
        railToggle: t("waterfalls.index.rail_toggle"),
        resultSuffix: t("waterfalls.index.result_suffix"),
        styleMenu: t("waterfalls.index.map_styles.menu_label"),
        stylePanelHeading: t("waterfalls.index.map_styles.panel_heading"),
        visibleLabel: t("waterfalls.index.visible_label")
      }
    }
  end

  def waterfall_index_filter_props
    {
      approachDifficulty: @filters[:approach_difficulty],
      minHeightMeters: @filters[:min_height_meters],
      plungePool: @filters[:plunge_pool],
      regionPublicId: @filters[:region_public_id]
    }
  end

  def waterfall_index_map_style_props
    @map_styles.map do |style|
      {
        id: style.fetch(:id),
        name: style[:label_key] ? t(style.fetch(:label_key)) : style.fetch(:name),
        styleUrl: style.fetch(:style_url)
      }
    end
  end

  def waterfall_index_region_props
    @regions.map do |region|
      {
        label: region.name,
        value: region.public_id
      }
    end
  end

  def waterfall_show_props
    {
      copy: {
        back: t("waterfalls.show.back")
      },
      urls: {
        explore: waterfalls_path
      },
      waterfall: {
        publicId: @waterfall.spot.public_id,
        name: @waterfall.spot.name,
        regionName: @waterfall.spot.region.name,
        summary: @waterfall.spot.summary,
        description: @waterfall.spot.description,
        facts: waterfall_facts
      }
    }
  end

  def waterfall_facts
    [
      waterfall_height_fact,
      waterfall_flow_seasonality_fact,
      waterfall_approach_difficulty_fact,
      waterfall_plunge_pool_fact
    ].compact
  end

  def waterfall_height_fact
    return if @waterfall.height_meters.blank?

    {
      key: "height",
      label: t("waterfalls.show.height_label"),
      value: t("waterfalls.shared.height", value: @waterfall.height_meters)
    }
  end

  def waterfall_flow_seasonality_fact
    return if @waterfall.flow_seasonality.blank?

    {
      key: "flowSeasonality",
      label: t("waterfalls.show.flow_seasonality_label"),
      value: @waterfall.flow_seasonality.humanize
    }
  end

  def waterfall_approach_difficulty_fact
    return if @waterfall.approach_difficulty.blank?

    {
      key: "approachDifficulty",
      label: t("waterfalls.show.approach_difficulty_label"),
      value: @waterfall.approach_difficulty.humanize
    }
  end

  def waterfall_plunge_pool_fact
    {
      key: "plungePool",
      label: t("waterfalls.show.plunge_pool_label"),
      value: t(@waterfall.plunge_pool? ? "waterfalls.show.plunge_pool_yes" : "waterfalls.show.plunge_pool_no")
    }
  end

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

  def explore_map_input
    @explore_map_input ||= params
      .permit(:region_public_id, :min_height_meters, :plunge_pool, :approach_difficulty, :west, :south, :east, :north)
      .to_h
      .compact_blank
      .symbolize_keys
  end

  def waterfall_params
    params.permit(:slugged_public_id)
  end
end
