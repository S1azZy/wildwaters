import { useCallback, useEffect, useMemo, useRef, useState } from "react"

import { loadMapLibre, type MapInstance } from "../../lib/maplibre"
import {
  ensureMapLayers,
  fitPadding,
  fitToFeatures,
  mapDataUrl,
  persistStylePreference,
  resolveInitialStyleId,
} from "./exploreMapUtils"
import type {
  ExploreAssets,
  ExploreFilters,
  ExploreMapConfig,
  ExploreMapStyle,
  ExploreUrls,
  WaterfallFeature,
  WaterfallFeatureCollection,
} from "./exploreTypes"

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
  const [features, setFeatures] = useState(initialFeatures)
  const [selectedPublicId, setSelectedPublicId] = useState<string | null>(null)
  const [activeStyleId, setActiveStyleId] = useState(() =>
    resolveInitialStyleId(
      mapStyles,
      map.defaultStyleId,
      map.stylePreferenceKey,
    ),
  )
  const [mapUnavailable, setMapUnavailable] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const mapRef = useRef<MapInstance | null>(null)
  const canvasRef = useRef<HTMLDivElement | null>(null)
  const shellRef = useRef<HTMLDivElement | null>(null)
  const abortRef = useRef<AbortController | null>(null)
  const requestIdRef = useRef(0)
  const featuresRef = useRef(features)
  const loadFeaturesRef = useRef<
    (options?: { fitToResults?: boolean }) => Promise<void>
  >(() => Promise.resolve())

  const styleUrl = useMemo(
    () =>
      mapStyles.find((style) => style.id === activeStyleId)?.styleUrl ??
      mapStyles[0]?.styleUrl,
    [activeStyleId, mapStyles],
  )
  const styleUrlRef = useRef(styleUrl)
  const featuresByPublicId = useMemo(
    () =>
      new Map(
        features.map((feature) => [feature.properties.public_id, feature]),
      ),
    [features],
  )

  featuresRef.current = features
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

  const updateViewportOffset = useCallback(() => {
    const headerHeight =
      document.querySelector<HTMLElement>("[data-ui='site-header']")
        ?.offsetHeight ?? 0

    shellRef.current?.style.setProperty(
      "--explore-header-offset",
      `${headerHeight}px`,
    )
  }, [])

  const syncMapSource = useCallback((nextFeatures: WaterfallFeature[]) => {
    mapRef.current?.getSource("waterfalls")?.setData({
      type: "FeatureCollection",
      features: nextFeatures,
    })
  }, [])

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
          padding: fitPadding(shellRef.current, resultsOpen),
          zoom: Math.max(mapRef.current.getZoom(), 10.5),
          duration: 700,
        })
      }
    },
    [featuresByPublicId, resultsOpen],
  )

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
    [filters, syncMapSource, urls.mapData],
  )

  useEffect(() => {
    loadFeaturesRef.current = loadFeatures
  }, [loadFeatures])

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
          ensureMapLayers(mapInstance, (publicId) =>
            setSelectedPublicId(publicId),
          )
          syncMapSource(featuresRef.current)
          void loadFeaturesRef.current?.({ fitToResults: true })
        })
        mapInstance.on("moveend", () => {
          void loadFeaturesRef.current?.()
        })
      })
      .catch(() => setMapUnavailable(true))

    return () => {
      disconnected = true
      requestIdRef.current += 1
      abortRef.current?.abort()
      mapRef.current?.remove()
      mapRef.current = null
    }
  }, [
    assets.maplibreScriptUrl,
    map.initialLatitude,
    map.initialLongitude,
    map.initialZoom,
    syncMapSource,
    updateViewportOffset,
  ])

  useEffect(() => {
    updateViewportOffset()
    window.addEventListener("resize", updateViewportOffset)

    return () => window.removeEventListener("resize", updateViewportOffset)
  }, [updateViewportOffset])

  useEffect(() => {
    syncMapSource(features)
  }, [features, syncMapSource])

  useEffect(() => {
    if (mapRef.current && styleUrl) {
      setIsLoading(true)
      mapRef.current.setStyle(styleUrl)
    }
  }, [styleUrl])

  useEffect(() => {
    const timer = window.setTimeout(() => {
      void loadFeatures({ fitToResults: true })
    }, 180)

    return () => window.clearTimeout(timer)
  }, [filters, loadFeatures])

  const selectStyle = useCallback(
    (styleId: string) => {
      setActiveStyleId(styleId)
      persistStylePreference(map.stylePreferenceKey, styleId)
    },
    [map.stylePreferenceKey],
  )

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
