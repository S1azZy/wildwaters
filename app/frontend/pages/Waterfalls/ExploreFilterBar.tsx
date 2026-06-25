import type { FormEvent } from "react"

import { Button } from "../../components/ui/button"
import { SelectField, TextField } from "../../components/ww"
import type {
  ExploreFilterCopy,
  ExploreFilters,
  ExploreUrls,
  RegionOption,
} from "./exploreTypes"

interface ExploreFilterBarProps {
  copy: ExploreFilterCopy
  filters: ExploreFilters
  onFilterChange: (key: keyof ExploreFilters, value: string) => void
  onSearchChange: (value: string) => void
  onSubmit: (event: FormEvent<HTMLFormElement>) => void
  regions: RegionOption[]
  search: string
  urls: ExploreUrls
}

const controlClassName =
  "h-11 w-full rounded-full bg-white/95 px-4 text-[0.93rem] shadow-sm"
const allFilterValue = "__all__"

function filterValue(value: string | null) {
  return value ?? allFilterValue
}

function selectedFilterValue(value: string) {
  return value === allFilterValue ? "" : value
}

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
          <TextField
            autoComplete="off"
            className={controlClassName}
            data-explore-map-target="search"
            hideLabel
            id="explore_search"
            label={copy.search}
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
            <SelectField
              hideLabel
              id="region_public_id"
              label={copy.region}
              name="region_public_id"
              onValueChange={(value) =>
                onFilterChange("regionPublicId", selectedFilterValue(value))
              }
              options={[
                { label: copy.allRegions, value: allFilterValue },
                ...regions,
              ]}
              triggerClassName={controlClassName}
              value={filterValue(filters.regionPublicId)}
            />
          </div>

          <div className="explore-filter-field grid min-w-0 gap-2">
            <TextField
              autoComplete="off"
              className={controlClassName}
              hideLabel
              id="min_height_meters"
              label={copy.minHeight}
              min="0"
              name="min_height_meters"
              onChange={(event) =>
                onFilterChange("minHeightMeters", event.target.value)
              }
              placeholder={copy.minHeightPlaceholder}
              step="5"
              type="number"
              value={filters.minHeightMeters ?? ""}
            />
          </div>

          <div className="explore-filter-field grid min-w-0 gap-2">
            <SelectField
              hideLabel
              id="plunge_pool"
              label={copy.plungePool}
              name="plunge_pool"
              onValueChange={(value) =>
                onFilterChange("plungePool", selectedFilterValue(value))
              }
              options={[
                { label: copy.anyPlungePool, value: allFilterValue },
                { label: copy.plungePoolYes, value: "true" },
                { label: copy.plungePoolNo, value: "false" },
              ]}
              triggerClassName={controlClassName}
              value={filterValue(filters.plungePool)}
            />
          </div>

          <div className="explore-filter-field grid min-w-0 gap-2">
            <SelectField
              hideLabel
              id="approach_difficulty"
              label={copy.approachDifficulty}
              name="approach_difficulty"
              onValueChange={(value) =>
                onFilterChange("approachDifficulty", selectedFilterValue(value))
              }
              options={[
                { label: copy.anyDifficulty, value: allFilterValue },
                { label: copy.easy, value: "easy" },
                { label: copy.moderate, value: "moderate" },
                { label: copy.hard, value: "hard" },
              ]}
              triggerClassName={controlClassName}
              value={filterValue(filters.approachDifficulty)}
            />
          </div>

          <div className="explore-filter-actions flex items-center gap-2.5 whitespace-nowrap">
            <Button asChild className="rounded-full" variant="outline">
              <a href={urls.explore}>{copy.reset}</a>
            </Button>
          </div>
        </form>
      </div>
    </div>
  )
}
