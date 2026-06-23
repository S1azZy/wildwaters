import {
  type ChangeEvent,
  type FormEvent,
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from "react"

import AppShell from "../../components/AppShell"
import { loadMapLibre, type MapInstance } from "../../lib/maplibre"
import type { SharedPageProps } from "../../types/page"

interface ExploreAssets {
  maplibreScriptUrl: string
  maplibreStylesheetUrl: string
}

interface ExploreCopy {
  title: string
  filters: {
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
    visibleLabel: string
  }
}

interface ExploreFilters {
  approachDifficulty: string | null
  minHeightMeters: string | null
  plungePool: string | null
  regionPublicId: string | null
}

interface ExploreMapConfig {
  defaultStyleId: string
  initialLatitude: number
  initialLongitude: number
  initialZoom: number
  panelOpenClass: string
  stylePreferenceKey: string
}

interface ExploreMapStyle {
  id: string
  name: string
  styleUrl: string
}

interface RegionOption {
  label: string
  value: string
}

interface WaterfallFeature {
  type: "Feature"
  geometry: {
    type: "Point"
    coordinates: [number, number]
  }
  properties: {
    approach_difficulty: string | null
    height_label: string | null
    height_meters: number | null
    name: string
    path: string
    plunge_pool: boolean
    plunge_pool_label: string | null
    public_id: string
    region_name: string
    summary: string | null
  }
}

interface WaterfallFeatureCollection {
  type: "FeatureCollection"
  features: WaterfallFeature[]
}

interface ExploreUrls {
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

const cardClassTemplate =
  "group rounded-[1.35rem] border border-white/80 bg-white/95 p-4 shadow-[0_18px_50px_rgba(15,23,42,0.1)] transition hover:-translate-y-0.5 hover:border-emerald-300 hover:shadow-[0_28px_80px_rgba(15,23,42,0.14)] focus-within:border-emerald-300 focus-within:ring-2 focus-within:ring-emerald-200 backdrop-blur"
const selectedCardClass =
  "ring-2 ring-emerald-700 border-emerald-300 shadow-[0_28px_80px_rgba(5,150,105,0.18)]"
const activeStyleButtonClass =
  "border-fuchsia-700 bg-white text-slate-950 shadow-[0_16px_34px_rgba(15,23,42,0.14)]"
const inactiveStyleButtonClass =
  "border-transparent bg-transparent text-slate-700 hover:border-stone-200 hover:bg-stone-50"

const difficultyLabels = new Map([
  ["easy", "Easy"],
  ["moderate", "Moderate"],
  ["hard", "Hard"],
])

export default function Index({
  assets,
  copy,
  filters: initialFilters,
  map,
  mapStyles,
  regions,
  shell,
  urls,
  waterfalls,
}: WaterfallIndexPageProps) {
  const [filters, setFilters] = useState<ExploreFilters>(initialFilters)
  const [search, setSearch] = useState("")
  const [features, setFeatures] = useState(waterfalls.features)
  const [resultsOpen, setResultsOpen] = useState(false)
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
  const visibleFeatures = useMemo(
    () =>
      search.trim().length === 0
        ? features
        : features.filter((feature) =>
            searchableText(feature).includes(search),
          ),
    [features, search],
  )
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

      setIsLoading(true)
      abortRef.current?.abort()
      abortRef.current = new AbortController()

      try {
        const response = await fetch(
          mapDataUrl(urls.mapData, filters, mapRef.current),
          {
            headers: { Accept: "application/json" },
            signal: abortRef.current.signal,
          },
        )

        if (!response.ok) {
          setMapUnavailable(true)
          return
        }

        const featureCollection =
          (await response.json()) as WaterfallFeatureCollection

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
        if (!(error instanceof DOMException && error.name === "AbortError")) {
          setMapUnavailable(true)
        }
      } finally {
        setIsLoading(false)
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

  function changeFilter(
    key: keyof ExploreFilters,
    event: ChangeEvent<HTMLInputElement | HTMLSelectElement>,
  ) {
    setFilters((currentFilters) => ({
      ...currentFilters,
      [key]: event.target.value === "" ? null : event.target.value,
    }))
  }

  function preventEnhancedSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    void loadFeatures({ fitToResults: true })
  }

  function selectStyle(styleId: string) {
    setActiveStyleId(styleId)
    persistStylePreference(map.stylePreferenceKey, styleId)
  }

  function zoomIn() {
    mapRef.current?.zoomIn()
  }

  function zoomOut() {
    mapRef.current?.zoomOut()
  }

  return (
    <AppShell
      mainClassName="flex w-full min-h-0 p-0"
      shell={shell}
      title={copy.title}
    >
      <section
        aria-busy={isLoading ? "true" : "false"}
        className="explore-layout-shell flex w-full flex-1 flex-col"
        id="explore-home"
      >
        <div
          className="explore-filter-band border-b border-stone-200/70 bg-white/94 px-4 py-1.5"
          data-explore-map-target="controlsPanel"
        >
          <div
            className="explore-filter-row mx-auto flex w-full flex-col gap-2.5 xl:grid xl:grid-cols-[minmax(0,14rem)_minmax(0,1fr)_auto] xl:items-center xl:gap-3"
            data-desktop-layout="single-row"
          >
            <div className="explore-filter-search min-w-0">
              <label className="sr-only" htmlFor="explore_search">
                {copy.filters.search}
              </label>
              <input
                autoComplete="off"
                className="w-full rounded-full border border-stone-200 bg-white px-4 py-[0.82rem] text-[0.93rem] text-slate-900 outline-none transition placeholder:text-slate-400 focus:border-emerald-400 focus:ring-2 focus:ring-emerald-100"
                data-explore-map-target="search"
                id="explore_search"
                name="explore_search"
                onChange={(event) =>
                  setSearch(event.target.value.toLowerCase())
                }
                placeholder={copy.filters.searchPlaceholder}
                type="search"
                value={search}
              />
            </div>

            <form
              action={urls.explore}
              className="explore-filter-form grid gap-2.5 md:grid-cols-2 xl:min-w-0 xl:grid-cols-[repeat(4,minmax(0,1fr))_auto] xl:items-center"
              data-desktop-wrap="never"
              data-explore-map-target="filters"
              method="get"
              onSubmit={preventEnhancedSubmit}
            >
              <div className="explore-filter-field grid min-w-0 gap-2">
                <label className="sr-only" htmlFor="region_public_id">
                  {copy.filters.region}
                </label>
                <select
                  className="w-full rounded-full border border-stone-200 bg-white px-4 py-[0.82rem] text-[0.93rem] text-slate-900 outline-none transition focus:border-emerald-400 focus:ring-2 focus:ring-emerald-100"
                  id="region_public_id"
                  name="region_public_id"
                  onChange={(event) => changeFilter("regionPublicId", event)}
                  value={filters.regionPublicId ?? ""}
                >
                  <option value="">{copy.filters.allRegions}</option>
                  {regions.map((region) => (
                    <option key={region.value} value={region.value}>
                      {region.label}
                    </option>
                  ))}
                </select>
              </div>

              <div className="explore-filter-field grid min-w-0 gap-2">
                <label className="sr-only" htmlFor="min_height_meters">
                  {copy.filters.minHeight}
                </label>
                <input
                  autoComplete="off"
                  className="w-full rounded-full border border-stone-200 bg-white px-4 py-[0.82rem] text-[0.93rem] text-slate-900 outline-none transition focus:border-emerald-400 focus:ring-2 focus:ring-emerald-100"
                  id="min_height_meters"
                  min="0"
                  name="min_height_meters"
                  onChange={(event) => changeFilter("minHeightMeters", event)}
                  placeholder={copy.filters.minHeightPlaceholder}
                  step="5"
                  type="number"
                  value={filters.minHeightMeters ?? ""}
                />
              </div>

              <div className="explore-filter-field grid min-w-0 gap-2">
                <label className="sr-only" htmlFor="plunge_pool">
                  {copy.filters.plungePool}
                </label>
                <select
                  className="w-full rounded-full border border-stone-200 bg-white px-4 py-[0.82rem] text-[0.93rem] text-slate-900 outline-none transition focus:border-emerald-400 focus:ring-2 focus:ring-emerald-100"
                  id="plunge_pool"
                  name="plunge_pool"
                  onChange={(event) => changeFilter("plungePool", event)}
                  value={filters.plungePool ?? ""}
                >
                  <option value="">{copy.filters.anyPlungePool}</option>
                  <option value="true">{copy.filters.plungePoolYes}</option>
                  <option value="false">{copy.filters.plungePoolNo}</option>
                </select>
              </div>

              <div className="explore-filter-field grid min-w-0 gap-2">
                <label className="sr-only" htmlFor="approach_difficulty">
                  {copy.filters.approachDifficulty}
                </label>
                <select
                  className="w-full rounded-full border border-stone-200 bg-white px-4 py-[0.82rem] text-[0.93rem] text-slate-900 outline-none transition focus:border-emerald-400 focus:ring-2 focus:ring-emerald-100"
                  id="approach_difficulty"
                  name="approach_difficulty"
                  onChange={(event) =>
                    changeFilter("approachDifficulty", event)
                  }
                  value={filters.approachDifficulty ?? ""}
                >
                  <option value="">{copy.filters.anyDifficulty}</option>
                  <option value="easy">{copy.filters.easy}</option>
                  <option value="moderate">{copy.filters.moderate}</option>
                  <option value="hard">{copy.filters.hard}</option>
                </select>
              </div>

              <div className="explore-filter-actions flex items-center gap-2.5 whitespace-nowrap">
                <a
                  className="inline-flex min-h-[2.85rem] items-center justify-center rounded-full border border-stone-300 bg-white px-4 text-[0.92rem] font-medium text-slate-700 transition hover:border-slate-400 hover:text-slate-950"
                  href={urls.explore}
                >
                  {copy.filters.reset}
                </a>
              </div>
            </form>
          </div>
        </div>

        <div
          className="explore-map-shell explore-map-shell--full-bleed explore-map-shell--viewport-fit relative flex-1 overflow-hidden"
          data-explore-map-target="shell"
          ref={shellRef}
        >
          <div className="explore-map-surface absolute inset-0">
            <div
              className="h-full w-full explore-map-canvas"
              data-explore-map-target="canvas"
              ref={canvasRef}
            />
          </div>

          {mapUnavailable ? (
            <div className="absolute inset-x-4 top-24 z-20 flex justify-center">
              <p className="rounded-full border border-white/30 bg-black/45 px-4 py-2 text-sm text-white shadow-[0_18px_80px_rgba(0,0,0,0.28)]">
                {copy.map.mapUnavailable}
              </p>
            </div>
          ) : null}

          <div className="explore-map-toolbar absolute right-4 top-4 z-20">
            <div className="flex flex-col items-center gap-2.5">
              <details
                className="explore-map-style-menu relative"
                data-explore-map-target="styleMenu"
              >
                <summary
                  aria-label={copy.map.styleMenu}
                  className="explore-map-style-toggle explore-map-toolbar-button flex cursor-pointer list-none items-center justify-center"
                >
                  <svg
                    aria-hidden="true"
                    className="h-[1.45rem] w-[1.45rem] text-slate-700"
                    focusable="false"
                    viewBox="0 0 24 24"
                  >
                    <path
                      d="M12 3.6 4.8 6.9 12 10.2l7.2-3.3z"
                      fill="none"
                      stroke="currentColor"
                      strokeLinejoin="round"
                      strokeWidth="1.65"
                    />
                    <path
                      d="M4.8 11.1 12 14.4l7.2-3.3"
                      fill="none"
                      stroke="currentColor"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth="1.65"
                    />
                    <path
                      d="M4.8 15.3 12 18.6l7.2-3.3"
                      fill="none"
                      stroke="currentColor"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth="1.65"
                    />
                  </svg>
                  <span className="sr-only">{copy.map.styleMenu}</span>
                </summary>

                <div className="explore-map-style-panel absolute right-[calc(100%+0.9rem)] top-0 z-20 w-[min(22rem,calc(100vw-2.5rem))] rounded-[1.5rem] border border-stone-200 bg-white/98 p-5 text-slate-900 shadow-[0_28px_90px_rgba(15,23,42,0.22)]">
                  <p className="mb-4 text-sm font-semibold uppercase tracking-[0.18em] text-slate-500">
                    {copy.map.stylePanelHeading}
                  </p>

                  <div className="grid grid-cols-2 gap-4">
                    {mapStyles.map((style) => (
                      <button
                        aria-pressed={style.id === activeStyleId}
                        className={`explore-map-style-option group text-left transition ${
                          style.id === activeStyleId
                            ? activeStyleButtonClass
                            : inactiveStyleButtonClass
                        }`}
                        data-explore-map-target="styleButton"
                        data-style-id={style.id}
                        data-style-url={style.styleUrl}
                        key={style.id}
                        onClick={() => selectStyle(style.id)}
                        type="button"
                      >
                        <span
                          className={`explore-map-style-preview explore-map-style-preview--${style.id}`}
                        >
                          <span className="explore-map-style-preview-inner" />
                        </span>
                        <span className="mt-2 block text-lg font-semibold leading-tight text-slate-800">
                          {style.name}
                        </span>
                      </button>
                    ))}
                  </div>
                </div>
              </details>

              <button
                aria-label="Zoom in"
                className="explore-map-toolbar-button"
                onClick={zoomIn}
                type="button"
              >
                <svg
                  aria-hidden="true"
                  className="h-[1.42rem] w-[1.42rem] text-slate-800"
                  focusable="false"
                  viewBox="0 0 24 24"
                >
                  <path
                    d="M12 5v14M5 12h14"
                    fill="none"
                    stroke="currentColor"
                    strokeLinecap="round"
                    strokeWidth="1.75"
                  />
                </svg>
              </button>

              <button
                aria-label="Zoom out"
                className="explore-map-toolbar-button"
                onClick={zoomOut}
                type="button"
              >
                <svg
                  aria-hidden="true"
                  className="h-[1.42rem] w-[1.42rem] text-slate-800"
                  focusable="false"
                  viewBox="0 0 24 24"
                >
                  <path
                    d="M5 12h14"
                    fill="none"
                    stroke="currentColor"
                    strokeLinecap="round"
                    strokeWidth="1.75"
                  />
                </svg>
              </button>
            </div>
          </div>

          <aside
            className="explore-results-shell pointer-events-auto absolute left-3 top-3 z-20 max-w-[calc(100%-1.5rem)] sm:left-4 sm:top-4 sm:max-w-[calc(100%-2rem)] lg:left-5 lg:top-5 lg:max-w-[24rem]"
            data-results-shell
            data-results-state={resultsOpen ? "expanded" : "collapsed"}
          >
            <button
              aria-controls="explore-results-panel"
              aria-expanded={resultsOpen}
              className="explore-results-toggle flex min-h-[4.05rem] w-full items-center justify-between gap-4 px-5 text-left transition"
              data-explore-map-target="resultsToggle"
              data-results-state={resultsOpen ? "expanded" : "collapsed"}
              onClick={() => {
                setResultsOpen((current) => !current)
                window.setTimeout(() => mapRef.current?.resize(), 280)
              }}
              type="button"
            >
              <span className="truncate whitespace-nowrap text-[1.02rem] font-semibold tracking-[-0.025em] text-slate-950 sm:text-[1.08rem]">
                {copy.map.railToggle}
              </span>
              <span className="explore-results-toggle-chevron flex h-[2.55rem] w-[2.55rem] shrink-0 items-center justify-center rounded-full border-[3px] border-blue-400/85 bg-stone-100/94 text-slate-800 shadow-[0_10px_24px_rgba(59,130,246,0.18)]">
                <svg
                  aria-hidden="true"
                  className="h-[0.98rem] w-[0.98rem]"
                  focusable="false"
                  viewBox="0 0 24 24"
                >
                  <path
                    d="M6 9.5 12 15.5 18 9.5"
                    fill="none"
                    stroke="currentColor"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth="1.9"
                  />
                </svg>
              </span>
            </button>

            <aside
              className={`explore-results-overlay flex flex-col overflow-hidden lg:w-[24rem] ${
                resultsOpen ? map.panelOpenClass : "is-collapsed"
              }`}
              data-explore-map-target="resultsPanel"
              data-results-state={resultsOpen ? "expanded" : "collapsed"}
              id="explore-results-panel"
            >
              <div
                className="border-b border-stone-200/90 px-5 py-4"
                data-explore-map-target="resultsHeader"
              >
                <div className="flex items-center justify-between gap-3">
                  <p
                    aria-live="polite"
                    className="min-w-0 text-sm font-semibold text-slate-900"
                  >
                    <span data-explore-map-target="resultCount">
                      {visibleFeatures.length}
                    </span>{" "}
                    {copy.map.resultSuffix}
                  </p>
                </div>
              </div>

              <div
                className="explore-scrollbar min-h-0 flex-1 overflow-y-auto px-4 pb-5 pt-4"
                data-explore-map-target="resultsScroll"
              >
                <div
                  aria-live="polite"
                  className={`grid gap-4 ${isLoading ? "opacity-60" : ""}`}
                  data-card-class-template={cardClassTemplate}
                  data-explore-map-target="list"
                >
                  {visibleFeatures.map((feature) => (
                    <WaterfallCard
                      copy={copy}
                      feature={feature}
                      key={feature.properties.public_id}
                      onFocus={focusFeature}
                      selected={
                        selectedPublicId === feature.properties.public_id
                      }
                    />
                  ))}
                </div>

                <p
                  className={`rounded-[1.75rem] border border-dashed border-stone-300 bg-white/80 px-5 py-8 text-center text-sm leading-6 text-slate-500 ${
                    visibleFeatures.length === 0 ? "" : "hidden"
                  }`}
                  data-explore-map-target="empty"
                >
                  {copy.map.empty}
                </p>

                <div
                  aria-hidden="true"
                  className={`mt-4 h-5 shrink-0 ${
                    visibleFeatures.length === 0 ? "hidden" : ""
                  }`}
                  data-explore-map-target="endCap"
                />
              </div>
            </aside>
          </aside>

          <noscript>
            <div className="absolute inset-x-4 bottom-4 z-20 rounded-[1.5rem] border border-white/15 bg-black/35 px-4 py-4 text-sm leading-6 text-white/84 shadow-[0_18px_80px_rgba(0,0,0,0.28)]">
              {copy.map.noJavascript}
            </div>
          </noscript>
        </div>
      </section>
    </AppShell>
  )
}

function WaterfallCard({
  copy,
  feature,
  onFocus,
  selected,
}: {
  copy: ExploreCopy
  feature: WaterfallFeature
  onFocus: (publicId: string, flyTo?: boolean) => void
  selected: boolean
}) {
  const classes = `${cardClassTemplate} ${selected ? selectedCardClass : ""}`

  return (
    <article
      className={classes}
      data-explore-map-target="card"
      data-latitude={feature.geometry.coordinates[1]}
      data-longitude={feature.geometry.coordinates[0]}
      data-public-id={feature.properties.public_id}
      data-search-text={searchableText(feature)}
    >
      <div className="flex items-start justify-between gap-4">
        <div className="min-w-0 flex-1 space-y-3">
          <div className="flex flex-wrap items-center gap-2">
            <span className="rounded-full bg-stone-100 px-3 py-1 text-[0.68rem] font-semibold uppercase tracking-[0.24em] text-emerald-900/65">
              {feature.properties.region_name}
            </span>

            {feature.properties.approach_difficulty ? (
              <span className="rounded-full bg-emerald-50 px-3 py-1 text-[0.68rem] font-semibold uppercase tracking-[0.24em] text-emerald-900">
                {humanizeDifficulty(feature.properties.approach_difficulty)}
              </span>
            ) : null}
          </div>

          <a
            className="block font-serif text-2xl leading-tight text-slate-950 transition group-hover:text-emerald-900"
            href={feature.properties.path}
          >
            {feature.properties.name}
          </a>

          {feature.properties.summary ? (
            <p className="line-clamp-2 text-sm leading-6 text-slate-600">
              {feature.properties.summary}
            </p>
          ) : null}
        </div>

        {feature.properties.height_label ? (
          <span className="shrink-0 rounded-full bg-emerald-950 px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em] text-emerald-50">
            {feature.properties.height_label}
          </span>
        ) : null}
      </div>

      {feature.properties.plunge_pool_label ? (
        <div className="mt-4 flex flex-wrap gap-2 text-xs font-medium text-slate-600">
          <span className="rounded-full bg-sky-50 px-3 py-1 text-sky-800">
            {feature.properties.plunge_pool_label}
          </span>
        </div>
      ) : null}

      <div className="mt-5 flex items-center gap-3 border-t border-stone-200/80 pt-4">
        <div className="ml-auto flex items-center gap-2">
          <button
            className="inline-flex items-center gap-2 rounded-full border border-emerald-200 bg-emerald-50 px-3 py-2 text-[0.68rem] font-semibold uppercase tracking-[0.16em] text-emerald-900 transition hover:border-emerald-300 hover:bg-emerald-100"
            data-public-id={feature.properties.public_id}
            onClick={() => onFocus(feature.properties.public_id, true)}
            type="button"
          >
            {copy.map.locate}
          </button>

          <a
            className="inline-flex items-center gap-2 rounded-full px-3 py-2 text-[0.68rem] font-semibold uppercase tracking-[0.16em] text-slate-600 transition hover:bg-stone-100 hover:text-slate-950"
            href={feature.properties.path}
          >
            {copy.map.details}
          </a>
        </div>
      </div>
    </article>
  )
}

function resolveInitialStyleId(
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

function readStylePreference(preferenceKey: string) {
  try {
    return window.localStorage.getItem(preferenceKey)
  } catch {
    return null
  }
}

function persistStylePreference(preferenceKey: string, styleId: string) {
  try {
    window.localStorage.setItem(preferenceKey, styleId)
  } catch {
    // Storage may be unavailable in private browsing; in-memory state is enough.
  }
}

function mapDataUrl(
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

function appendFilter(
  query: URLSearchParams,
  key: string,
  value: string | null,
) {
  if (value) {
    query.set(key, value)
  }
}

function ensureMapLayers(
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

function fitToFeatures(
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

function fitPadding(shell: HTMLElement | null, resultsOpen: boolean) {
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

function searchableText(feature: WaterfallFeature) {
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

function humanizeDifficulty(value: string) {
  return (
    difficultyLabels.get(value) ??
    value.replaceAll("_", " ").replace(/\b\w/g, (match) => match.toUpperCase())
  )
}
