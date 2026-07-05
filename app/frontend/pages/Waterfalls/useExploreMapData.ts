import type { MutableRefObject } from "react"
import { useCallback, useEffect, useRef, useState } from "react"

import type { MapInstance } from "../../lib/maplibre"
import { fitToFeatures, mapDataUrl } from "./exploreMapUtils"
import type {
  ExploreFilters,
  ExploreUrls,
  WaterfallFeature,
  WaterfallFeatureCollection,
} from "./exploreTypes"

interface UseExploreMapDataOptions {
  filters: ExploreFilters
  initialFeatures: WaterfallFeature[]
  mapRef: MutableRefObject<MapInstance | null>
  shellRef: MutableRefObject<HTMLDivElement | null>
  urls: ExploreUrls
}

export function useExploreMapData({
  filters,
  initialFeatures,
  mapRef,
  shellRef,
  urls,
}: UseExploreMapDataOptions) {
  const [features, setFeatures] = useState(initialFeatures)
  const [mapUnavailable, setMapUnavailable] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const abortRef = useRef<AbortController | null>(null)
  const requestIdRef = useRef(0)
  const featuresRef = useRef(features)

  featuresRef.current = features

  const syncMapSource = useCallback(
    (nextFeatures: WaterfallFeature[]) => {
      mapRef.current?.getSource("waterfalls")?.setData({
        type: "FeatureCollection",
        features: nextFeatures,
      })
    },
    [mapRef],
  )

  const cancelFeatureRequests = useCallback(() => {
    requestIdRef.current += 1
    abortRef.current?.abort()
  }, [])

  const loadFeatures = useCallback(
    async ({ fitToResults = false }: { fitToResults?: boolean } = {}) => {
      if (!mapRef.current?.isStyleLoaded()) {
        return
      }

      const requestId = requestIdRef.current + 1
      requestIdRef.current = requestId
      abortRef.current?.abort()

      const controller = new AbortController()
      abortRef.current = controller
      setIsLoading(true)

      try {
        const response = await fetch(
          mapDataUrl(urls.mapData, filters, mapRef.current),
          {
            headers: { Accept: "application/json" },
            signal: controller.signal,
          },
        )

        if (requestIdRef.current !== requestId || controller.signal.aborted) {
          return
        }

        if (!response.ok) {
          setMapUnavailable(true)
          return
        }

        const featureCollection =
          (await response.json()) as WaterfallFeatureCollection

        if (requestIdRef.current !== requestId || controller.signal.aborted) {
          return
        }

        setFeatures(featureCollection.features)
        syncMapSource(featureCollection.features)
        setMapUnavailable(false)

        if (fitToResults) {
          fitToFeatures(
            featureCollection.features,
            mapRef.current,
            shellRef.current,
          )
        }
      } catch (error) {
        if (
          requestIdRef.current === requestId &&
          !(error instanceof DOMException && error.name === "AbortError")
        ) {
          setMapUnavailable(true)
        }
      } finally {
        if (requestIdRef.current === requestId) {
          setIsLoading(false)
        }

        if (abortRef.current === controller) {
          abortRef.current = null
        }
      }
    },
    [filters, mapRef, shellRef, syncMapSource, urls.mapData],
  )

  useEffect(() => {
    syncMapSource(features)
  }, [features, syncMapSource])

  useEffect(() => {
    const timer = window.setTimeout(() => {
      void loadFeatures({ fitToResults: true })
    }, 180)

    return () => window.clearTimeout(timer)
  }, [filters, loadFeatures])

  return {
    cancelFeatureRequests,
    features,
    featuresRef,
    isLoading,
    loadFeatures,
    mapUnavailable,
    setIsLoading,
    setMapUnavailable,
    syncMapSource,
  }
}
