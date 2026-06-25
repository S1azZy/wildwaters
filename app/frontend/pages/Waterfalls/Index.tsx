import { type FormEvent, useMemo, useState } from "react"

import AppShell from "../../components/AppShell"
import ExploreFilterBar from "./ExploreFilterBar"
import ExploreMapToolbar from "./ExploreMapToolbar"
import ExploreResultsRail from "./ExploreResultsRail"
import { searchableText } from "./exploreMapUtils"
import type { ExploreFilters, WaterfallIndexPageProps } from "./exploreTypes"
import { useExploreMap } from "./useExploreMap"

export type { WaterfallIndexPageProps } from "./exploreTypes"

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
  const [resultsOpen, setResultsOpen] = useState(false)
  const {
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
  } = useExploreMap({
    assets,
    filters,
    initialFeatures: waterfalls.features,
    map,
    mapStyles,
    resultsOpen,
    urls,
  })
  const visibleFeatures = useMemo(
    () =>
      search.trim().length === 0
        ? features
        : features.filter((feature) =>
            searchableText(feature).includes(search),
          ),
    [features, search],
  )

  function changeFilter(key: keyof ExploreFilters, value: string) {
    setFilters((currentFilters) => ({
      ...currentFilters,
      [key]: value === "" ? null : value,
    }))
  }

  function preventEnhancedSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
  }

  function toggleResults() {
    setResultsOpen((current) => !current)
    resizeMapAfterTransition()
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
        <ExploreFilterBar
          copy={copy.filters}
          filters={filters}
          onFilterChange={changeFilter}
          onSearchChange={(value) => setSearch(value.toLowerCase())}
          onSubmit={preventEnhancedSubmit}
          regions={regions}
          search={search}
          urls={urls}
        />

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

          <ExploreMapToolbar
            activeStyleId={activeStyleId}
            copy={copy.map}
            mapStyles={mapStyles}
            onStyleSelect={selectStyle}
            onZoomIn={zoomIn}
            onZoomOut={zoomOut}
          />

          <ExploreResultsRail
            copy={copy}
            features={visibleFeatures}
            isLoading={isLoading}
            onFocusFeature={focusFeature}
            onToggle={toggleResults}
            panelOpenClass={map.panelOpenClass}
            resultsOpen={resultsOpen}
            selectedPublicId={selectedPublicId}
          />

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
