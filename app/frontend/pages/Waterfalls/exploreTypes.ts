import type { SharedPageProps } from "../../types/page"

export interface ExploreAssets {
  maplibreScriptUrl: string
  maplibreStylesheetUrl: string
}

export interface ExploreFilterCopy {
  allRegions: string
  anyDifficulty: string
  anyPlungePool: string
  approachDifficulty: string
  easy: string
  hard: string
  minHeight: string
  minHeightPlaceholder: string
  moderate: string
  plungePool: string
  plungePoolNo: string
  plungePoolYes: string
  region: string
  reset: string
  search: string
  searchPlaceholder: string
}

export interface ExploreCopy {
  title: string
  filters: ExploreFilterCopy
  map: {
    details: string
    empty: string
    locate: string
    mapUnavailable: string
    noJavascript: string
    railToggle: string
    resultSuffix: string
    styleMenu: string
    stylePanelHeading: string
    zoomIn: string
    zoomOut: string
  }
}

export interface ExploreFilters {
  approachDifficulty: string | null
  minHeightMeters: string | null
  plungePool: string | null
  regionPublicId: string | null
}

export interface ExploreMapConfig {
  defaultStyleId: string
  initialLatitude: number
  initialLongitude: number
  initialZoom: number
  panelOpenClass: string
  stylePreferenceKey: string
}

export interface ExploreMapStyle {
  id: string
  name: string
  styleUrl: string
}

export interface RegionOption {
  label: string
  value: string
}

export interface WaterfallFeature {
  type: "Feature"
  geometry: {
    type: "Point"
    coordinates: [number, number]
  }
  properties: {
    approach_difficulty: string | null
    height_label: string | null
    name: string
    path: string
    plunge_pool_label: string | null
    public_id: string
    region_name: string
    summary: string | null
  }
}

export interface WaterfallFeatureCollection {
  type: "FeatureCollection"
  features: WaterfallFeature[]
}

export interface ExploreUrls {
  explore: string
  mapData: string
}

export interface WaterfallIndexPageProps extends SharedPageProps {
  assets: ExploreAssets
  copy: ExploreCopy
  filters: ExploreFilters
  map: ExploreMapConfig
  mapStyles: ExploreMapStyle[]
  regions: RegionOption[]
  urls: ExploreUrls
  waterfalls: WaterfallFeatureCollection
}
