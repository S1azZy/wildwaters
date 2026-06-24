import type { ChangeEvent, FormEvent } from "react"

import type {
  ExploreFilterCopy,
  ExploreFilters,
  ExploreUrls,
  RegionOption,
} from "./exploreTypes"

interface ExploreFilterBarProps {
  copy: ExploreFilterCopy
  filters: ExploreFilters
  onFilterChange: (
    key: keyof ExploreFilters,
    event: ChangeEvent<HTMLInputElement | HTMLSelectElement>,
  ) => void
  onSearchChange: (value: string) => void
  onSubmit: (event: FormEvent<HTMLFormElement>) => void
  regions: RegionOption[]
  search: string
  urls: ExploreUrls
}

const controlClassName =
  "w-full rounded-full border border-stone-200 bg-white px-4 py-[0.82rem] text-[0.93rem] text-slate-900 outline-none transition focus:border-emerald-400 focus:ring-2 focus:ring-emerald-100"

export default function ExploreFilterBar({
  copy,
  filters,
  onFilterChange,
  onSearchChange,
  onSubmit,
  regions,
  search,
  urls,
}: ExploreFilterBarProps) {
  return (
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
            {copy.search}
          </label>
          <input
            autoComplete="off"
            className={`${controlClassName} placeholder:text-slate-400`}
            data-explore-map-target="search"
            id="explore_search"
            name="explore_search"
            onChange={(event) => onSearchChange(event.target.value)}
            placeholder={copy.searchPlaceholder}
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
          onSubmit={onSubmit}
        >
          <div className="explore-filter-field grid min-w-0 gap-2">
            <label className="sr-only" htmlFor="region_public_id">
              {copy.region}
            </label>
            <select
              className={controlClassName}
              id="region_public_id"
              name="region_public_id"
              onChange={(event) => onFilterChange("regionPublicId", event)}
              value={filters.regionPublicId ?? ""}
            >
              <option value="">{copy.allRegions}</option>
              {regions.map((region) => (
                <option key={region.value} value={region.value}>
                  {region.label}
                </option>
              ))}
            </select>
          </div>

          <div className="explore-filter-field grid min-w-0 gap-2">
            <label className="sr-only" htmlFor="min_height_meters">
              {copy.minHeight}
            </label>
            <input
              autoComplete="off"
              className={controlClassName}
              id="min_height_meters"
              min="0"
              name="min_height_meters"
              onChange={(event) => onFilterChange("minHeightMeters", event)}
              placeholder={copy.minHeightPlaceholder}
              step="5"
              type="number"
              value={filters.minHeightMeters ?? ""}
            />
          </div>

          <div className="explore-filter-field grid min-w-0 gap-2">
            <label className="sr-only" htmlFor="plunge_pool">
              {copy.plungePool}
            </label>
            <select
              className={controlClassName}
              id="plunge_pool"
              name="plunge_pool"
              onChange={(event) => onFilterChange("plungePool", event)}
              value={filters.plungePool ?? ""}
            >
              <option value="">{copy.anyPlungePool}</option>
              <option value="true">{copy.plungePoolYes}</option>
              <option value="false">{copy.plungePoolNo}</option>
            </select>
          </div>

          <div className="explore-filter-field grid min-w-0 gap-2">
            <label className="sr-only" htmlFor="approach_difficulty">
              {copy.approachDifficulty}
            </label>
            <select
              className={controlClassName}
              id="approach_difficulty"
              name="approach_difficulty"
              onChange={(event) => onFilterChange("approachDifficulty", event)}
              value={filters.approachDifficulty ?? ""}
            >
              <option value="">{copy.anyDifficulty}</option>
              <option value="easy">{copy.easy}</option>
              <option value="moderate">{copy.moderate}</option>
              <option value="hard">{copy.hard}</option>
            </select>
          </div>

          <div className="explore-filter-actions flex items-center gap-2.5 whitespace-nowrap">
            <a
              className="inline-flex min-h-[2.85rem] items-center justify-center rounded-full border border-stone-300 bg-white px-4 text-[0.92rem] font-medium text-slate-700 transition hover:border-slate-400 hover:text-slate-950"
              href={urls.explore}
            >
              {copy.reset}
            </a>
          </div>
        </form>
      </div>
    </div>
  )
}
