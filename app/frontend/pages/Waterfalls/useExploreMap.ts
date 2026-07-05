import { useCallback, useMemo, useRef, useState } from "react"

import type { MapInstance } from "../../lib/maplibre"
import type {
  ExploreAssets,
  ExploreFilters,
  ExploreMapConfig,
  ExploreMapStyle,
  ExploreUrls,
  WaterfallFeature,
} from "./exploreTypes"
import { useExploreMapData } from "./useExploreMapData"
import { useExploreMapLifecycle } from "./useExploreMapLifecycle"
import { useExploreStylePreference } from "./useExploreStylePreference"
import { useExploreViewport } from "./useExploreViewport"

interface UseExploreMapOptions {
  assets: ExploreAssets
  filters: ExploreFilters
  initialFeatures: WaterfallFeature[]
  map: ExploreMapConfig
  mapStyles: ExploreMapStyle[]
  resultsOpen: boolean
  urls: ExploreUrls
}

export function useExploreMap({
  assets,
  filters,
  initialFeatures,
  map,
  mapStyles,
  resultsOpen,
  urls,
}: UseExploreMapOptions) {
  const [selectedPublicId, setSelectedPublicId] = useState<string | null>(null)
  const mapRef = useRef<MapInstance | null>(null)
  const canvasRef = useRef<HTMLDivElement | null>(null)
  const { activeStyleId, selectStyle, styleUrl } = useExploreStylePreference(
    mapStyles,
    map.defaultStyleId,
    map.stylePreferenceKey,
  )
  const { currentFitPadding, shellRef, updateViewportOffset } =
    useExploreViewport(resultsOpen)
  const {
    cancelFeatureRequests,
    features,
    featuresRef,
    isLoading,
    loadFeatures,
    mapUnavailable,
    setIsLoading,
    setMapUnavailable,
    syncMapSource,
  } = useExploreMapData({
    filters,
    initialFeatures,
    mapRef,
    shellRef,
    urls,
  })
  const featuresByPublicId = useMemo(
    () =>
      new Map(
        features.map((feature) => [feature.properties.public_id, feature]),
      ),
    [features],
  )

  const focusFeature = useCallback(
    (publicId: string, flyTo = false) => {
      const feature = featuresByPublicId.get(publicId)

      if (!feature) {
        return
      }

      setSelectedPublicId(publicId)

      if (flyTo) {
        mapRef.current?.easeTo({
          center: feature.geometry.coordinates,
          padding: currentFitPadding(),
          zoom: Math.max(mapRef.current.getZoom(), 10.5),
          duration: 700,
        })
      }
    },
    [currentFitPadding, featuresByPublicId],
  )

  useExploreMapLifecycle({
    assets,
    canvasRef,
    cancelFeatureRequests,
    featuresRef,
    loadFeatures,
    map,
    mapRef,
    onMapUnavailable: setMapUnavailable,
    onSelectFeature: setSelectedPublicId,
    setLoading: setIsLoading,
    styleUrl,
    syncMapSource,
    updateViewportOffset,
  })

  const resizeMapAfterTransition = useCallback(() => {
    window.setTimeout(() => mapRef.current?.resize(), 280)
  }, [])

  const zoomIn = useCallback(() => {
    mapRef.current?.zoomIn()
  }, [])

  const zoomOut = useCallback(() => {
    mapRef.current?.zoomOut()
  }, [])

  return {
    activeStyleId,
    canvasRef,
    features,
    focusFeature,
    isLoading,
    mapUnavailable,
    resizeMapAfterTransition,
    selectStyle,
    selectedPublicId,
    shellRef,
    zoomIn,
    zoomOut,
  }
}
