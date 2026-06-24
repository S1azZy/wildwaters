import type { MapInstance } from "../../lib/maplibre"
import type {
  ExploreFilterCopy,
  ExploreFilters,
  ExploreMapStyle,
  WaterfallFeature,
} from "./exploreTypes"

export function resolveInitialStyleId(
  mapStyles: ExploreMapStyle[],
  defaultStyleId: string,
  preferenceKey: string,
) {
  const styleIds = mapStyles.map((style) => style.id)
  const savedStyleId = readStylePreference(preferenceKey)

  if (savedStyleId && styleIds.includes(savedStyleId)) {
    return savedStyleId
  }

  if (styleIds.includes(defaultStyleId)) {
    return defaultStyleId
  }

  return styleIds[0] ?? null
}

export function persistStylePreference(preferenceKey: string, styleId: string) {
  try {
    window.localStorage.setItem(preferenceKey, styleId)
  } catch {
    // Storage may be unavailable in private browsing; in-memory state is enough.
  }
}

export function mapDataUrl(
  baseUrl: string,
  filters: ExploreFilters,
  mapInstance: MapInstance,
) {
  const bounds = mapInstance.getBounds()
  const query = new URLSearchParams()

  appendFilter(query, "region_public_id", filters.regionPublicId)
  appendFilter(query, "min_height_meters", filters.minHeightMeters)
  appendFilter(query, "plunge_pool", filters.plungePool)
  appendFilter(query, "approach_difficulty", filters.approachDifficulty)
  query.set("west", String(bounds.getWest()))
  query.set("south", String(bounds.getSouth()))
  query.set("east", String(bounds.getEast()))
  query.set("north", String(bounds.getNorth()))

  return `${baseUrl}?${query.toString()}`
}

export function ensureMapLayers(
  mapInstance: MapInstance,
  selectPublicId: (publicId: string) => void,
) {
  if (mapInstance.getSource("waterfalls")) {
    return
  }

  mapInstance.addSource("waterfalls", {
    cluster: true,
    clusterMaxZoom: 11,
    clusterRadius: 42,
    data: { type: "FeatureCollection", features: [] },
    type: "geojson",
  })
  mapInstance.addLayer({
    filter: ["has", "point_count"],
    id: "waterfall-clusters",
    paint: {
      "circle-color": "#183028",
      "circle-radius": ["step", ["get", "point_count"], 20, 8, 24, 16, 30],
      "circle-stroke-color": "#efe6d5",
      "circle-stroke-width": 3,
    },
    source: "waterfalls",
    type: "circle",
  })
  mapInstance.addLayer({
    filter: ["has", "point_count"],
    id: "waterfall-cluster-count",
    layout: {
      "text-field": ["get", "point_count_abbreviated"],
      "text-size": 12,
    },
    paint: {
      "text-color": "#f8fafc",
    },
    source: "waterfalls",
    type: "symbol",
  })
  mapInstance.addLayer({
    filter: ["!", ["has", "point_count"]],
    id: "waterfall-points",
    paint: {
      "circle-color": "#c2743f",
      "circle-radius": 8,
      "circle-stroke-color": "#fffbeb",
      "circle-stroke-width": 2.5,
    },
    source: "waterfalls",
    type: "circle",
  })
  mapInstance.on("click", "waterfall-points", (event) => {
    const publicId = event.features?.[0]?.properties?.public_id

    if (publicId) {
      selectPublicId(publicId)
    }
  })
  mapInstance.on("click", "waterfall-clusters", (event) => {
    const clusterFeature = event.features?.[0]
    const clusterId = clusterFeature?.properties?.cluster_id

    if (!clusterFeature || clusterId == null) {
      return
    }

    mapInstance
      .getSource("waterfalls")
      ?.getClusterExpansionZoom(clusterId, (error, zoom) => {
        if (error) {
          return
        }

        mapInstance.easeTo({
          center: clusterFeature.geometry.coordinates,
          zoom,
        })
      })
  })
  mapInstance.on("mouseenter", "waterfall-points", () => {
    mapInstance.getCanvas().style.cursor = "pointer"
  })
  mapInstance.on("mouseleave", "waterfall-points", () => {
    mapInstance.getCanvas().style.cursor = ""
  })
}

export function fitToFeatures(
  features: WaterfallFeature[],
  mapInstance: MapInstance,
  shell: HTMLElement | null,
) {
  if (features.length === 0 || !window.maplibregl) {
    return
  }

  const bounds = new window.maplibregl.LngLatBounds()
  features.forEach((feature) => bounds.extend(feature.geometry.coordinates))
  mapInstance.fitBounds(bounds, {
    duration: 0,
    maxZoom: 11,
    padding: fitPadding(shell, false),
  })
}

export function fitPadding(shell: HTMLElement | null, resultsOpen: boolean) {
  const padding = { bottom: 56, left: 56, right: 56, top: 72 }

  if (!shell) {
    return padding
  }

  const shellRect = shell.getBoundingClientRect()
  const controls = shell
    .closest("#explore-home")
    ?.querySelector<HTMLElement>("[data-explore-map-target='controlsPanel']")

  if (controls) {
    const controlsRect = controls.getBoundingClientRect()
    padding.top = Math.max(
      padding.top,
      Math.ceil(controlsRect.bottom - shellRect.top) + 24,
    )
  }

  if (resultsOpen) {
    const results = shell.querySelector<HTMLElement>(
      "[data-explore-map-target='resultsPanel']",
    )

    if (results) {
      const resultsRect = results.getBoundingClientRect()
      const resultsWidthRatio = resultsRect.width / Math.max(shellRect.width, 1)
      const bottomInset = Math.ceil(shellRect.bottom - resultsRect.top) + 24

      if (resultsWidthRatio > 0.55) {
        padding.bottom = Math.max(padding.bottom, bottomInset)
      } else {
        padding.left = Math.max(
          padding.left,
          Math.ceil(resultsRect.right - shellRect.left) + 24,
        )
      }
    }
  }

  return padding
}

export function searchableText(feature: WaterfallFeature) {
  return [
    feature.properties.name,
    feature.properties.summary,
    feature.properties.region_name,
    feature.properties.approach_difficulty,
  ]
    .filter(Boolean)
    .join(" ")
    .toLowerCase()
}

export function difficultyLabel(value: string, labels: ExploreFilterCopy) {
  switch (value) {
    case "easy":
      return labels.easy
    case "moderate":
      return labels.moderate
    case "hard":
      return labels.hard
    default:
      return value
        .replaceAll("_", " ")
        .replace(/\b\w/g, (match) => match.toUpperCase())
  }
}

function readStylePreference(preferenceKey: string) {
  try {
    return window.localStorage.getItem(preferenceKey)
  } catch {
    return null
  }
}

function appendFilter(
  query: URLSearchParams,
  key: string,
  value: string | null,
) {
  if (value) {
    query.set(key, value)
  }
}
