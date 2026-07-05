import type { MutableRefObject } from "react"
import { useEffect, useRef } from "react"

import { loadMapLibre, type MapInstance } from "../../lib/maplibre"
import { ensureMapLayers } from "./exploreMapUtils"
import type {
  ExploreAssets,
  ExploreMapConfig,
  WaterfallFeature,
} from "./exploreTypes"

interface UseExploreMapLifecycleOptions {
  assets: ExploreAssets
  canvasRef: MutableRefObject<HTMLDivElement | null>
  cancelFeatureRequests: () => void
  featuresRef: MutableRefObject<WaterfallFeature[]>
  loadFeatures: (options?: { fitToResults?: boolean }) => Promise<void>
  map: ExploreMapConfig
  mapRef: MutableRefObject<MapInstance | null>
  onMapUnavailable: (mapUnavailable: boolean) => void
  onSelectFeature: (publicId: string) => void
  setLoading: (isLoading: boolean) => void
  styleUrl: string | undefined
  syncMapSource: (nextFeatures: WaterfallFeature[]) => void
  updateViewportOffset: () => void
}

export function useExploreMapLifecycle({
  assets,
  canvasRef,
  cancelFeatureRequests,
  featuresRef,
  loadFeatures,
  map,
  mapRef,
  onMapUnavailable,
  onSelectFeature,
  setLoading,
  styleUrl,
  syncMapSource,
  updateViewportOffset,
}: UseExploreMapLifecycleOptions) {
  const loadFeaturesRef = useRef(loadFeatures)
  const styleUrlRef = useRef(styleUrl)

  loadFeaturesRef.current = loadFeatures
  styleUrlRef.current = styleUrl

  useEffect(() => {
    const existingLink = document.querySelector<HTMLLinkElement>(
      `link[data-maplibre-stylesheet][href="${assets.maplibreStylesheetUrl}"]`,
    )

    if (existingLink) {
      return
    }

    const link = document.createElement("link")
    link.dataset.maplibreStylesheet = "true"
    link.href = assets.maplibreStylesheetUrl
    link.rel = "stylesheet"
    document.head.append(link)

    return () => link.remove()
  }, [assets.maplibreStylesheetUrl])

  useEffect(() => {
    let disconnected = false

    void loadMapLibre(assets.maplibreScriptUrl)
      .then((maplibre) => {
        if (disconnected || !canvasRef.current || !styleUrlRef.current) {
          return
        }

        const mapInstance = new maplibre.Map({
          attributionControl: false,
          center: [map.initialLongitude, map.initialLatitude],
          container: canvasRef.current,
          style: styleUrlRef.current,
          zoom: map.initialZoom,
        })
        mapRef.current = mapInstance

        mapInstance.addControl(
          new maplibre.AttributionControl({ compact: true }),
          "bottom-right",
        )
        mapInstance.on("style.load", () => {
          updateViewportOffset()
          mapInstance.resize()
          ensureMapLayers(mapInstance, onSelectFeature)
          syncMapSource(featuresRef.current)
          void loadFeaturesRef.current({ fitToResults: true })
        })
        mapInstance.on("moveend", () => {
          void loadFeaturesRef.current()
        })
      })
      .catch(() => onMapUnavailable(true))

    return () => {
      disconnected = true
      cancelFeatureRequests()
      mapRef.current?.remove()
      mapRef.current = null
    }
  }, [
    assets.maplibreScriptUrl,
    canvasRef,
    cancelFeatureRequests,
    featuresRef,
    map.initialLatitude,
    map.initialLongitude,
    map.initialZoom,
    mapRef,
    onMapUnavailable,
    onSelectFeature,
    syncMapSource,
    updateViewportOffset,
  ])

  useEffect(() => {
    if (mapRef.current && styleUrl) {
      setLoading(true)
      mapRef.current.setStyle(styleUrl)
    }
  }, [mapRef, setLoading, styleUrl])
}
