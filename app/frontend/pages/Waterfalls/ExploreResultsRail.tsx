import { ChevronDownIcon } from "lucide-react"

import { Button } from "../../components/ui/button"
import { Card, CardContent } from "../../components/ui/card"
import { Badge, ProductEmptyState } from "../../components/ww"
import { difficultyLabel, searchableText } from "./exploreMapUtils"
import type { ExploreCopy, WaterfallFeature } from "./exploreTypes"

interface ExploreResultsRailProps {
  copy: ExploreCopy
  features: WaterfallFeature[]
  isLoading: boolean
  onFocusFeature: (publicId: string, flyTo?: boolean) => void
  onToggle: () => void
  panelOpenClass: string
  resultsOpen: boolean
  selectedPublicId: string | null
}

const cardClassTemplate =
  "group border-white/80 bg-white/95 shadow-[0_18px_50px_rgba(15,23,42,0.1)] backdrop-blur transition hover:-translate-y-0.5 hover:border-emerald-300 hover:shadow-[0_28px_80px_rgba(15,23,42,0.14)] focus-within:border-emerald-300 focus-within:ring-2 focus-within:ring-emerald-200"
const selectedCardClass =
  "ring-2 ring-emerald-700 border-emerald-300 shadow-[0_28px_80px_rgba(5,150,105,0.18)]"

export default function ExploreResultsRail({
  copy,
  features,
  isLoading,
  onFocusFeature,
  onToggle,
  panelOpenClass,
  resultsOpen,
  selectedPublicId,
}: ExploreResultsRailProps) {
  return (
    <aside
      className="explore-results-shell pointer-events-auto absolute left-3 top-3 z-20 max-w-[calc(100%-1.5rem)] sm:left-4 sm:top-4 sm:max-w-[calc(100%-2rem)] lg:left-5 lg:top-5 lg:max-w-[24rem]"
      data-results-shell
      data-results-state={resultsOpen ? "expanded" : "collapsed"}
    >
      <Button
        aria-controls="explore-results-panel"
        aria-expanded={resultsOpen}
        className="explore-results-toggle flex min-h-[4.05rem] w-full items-center justify-between gap-4 px-5 text-left transition"
        data-explore-map-target="resultsToggle"
        data-results-state={resultsOpen ? "expanded" : "collapsed"}
        onClick={onToggle}
        type="button"
        variant="ghost"
      >
        <span className="truncate whitespace-nowrap text-[1.02rem] font-semibold tracking-[-0.025em] text-slate-950 sm:text-[1.08rem]">
          {copy.map.railToggle}
        </span>
        <span className="explore-results-toggle-chevron flex h-[2.55rem] w-[2.55rem] shrink-0 items-center justify-center rounded-full border-[3px] border-blue-400/85 bg-stone-100/94 text-slate-800 shadow-[0_10px_24px_rgba(59,130,246,0.18)]">
          <ChevronDownIcon aria-hidden="true" />
        </span>
      </Button>

      <aside
        className={`explore-results-overlay flex flex-col overflow-hidden lg:w-[24rem] ${
          resultsOpen ? panelOpenClass : "is-collapsed"
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
                {features.length}
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
            {features.map((feature) => (
              <WaterfallCard
                copy={copy}
                feature={feature}
                key={feature.properties.public_id}
                onFocus={onFocusFeature}
                selected={selectedPublicId === feature.properties.public_id}
              />
            ))}
          </div>

          <div
            className={`${features.length === 0 ? "" : "hidden"}`}
            data-explore-map-target="empty"
          >
            <ProductEmptyState title={copy.map.empty} />
          </div>

          <div
            aria-hidden="true"
            className={`mt-4 h-5 shrink-0 ${features.length === 0 ? "hidden" : ""}`}
            data-explore-map-target="endCap"
          />
        </div>
      </aside>
    </aside>
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
    <Card
      asChild
      className={classes}
      data-explore-map-target="card"
      data-latitude={feature.geometry.coordinates[1]}
      data-longitude={feature.geometry.coordinates[0]}
      data-public-id={feature.properties.public_id}
      data-search-text={searchableText(feature)}
    >
      <article>
        <CardContent>
          <div className="flex items-start justify-between gap-4">
            <div className="min-w-0 flex-1 space-y-3">
              <div className="flex flex-wrap items-center gap-2">
                <Badge variant="secondary">
                  {feature.properties.region_name}
                </Badge>

                {feature.properties.approach_difficulty ? (
                  <Badge>
                    {difficultyLabel(
                      feature.properties.approach_difficulty,
                      copy.filters,
                    )}
                  </Badge>
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
              <Badge className="shrink-0">
                {feature.properties.height_label}
              </Badge>
            ) : null}
          </div>

          {feature.properties.plunge_pool_label ? (
            <div className="mt-4 flex flex-wrap gap-2 text-xs font-medium text-slate-600">
              <Badge variant="outline">
                {feature.properties.plunge_pool_label}
              </Badge>
            </div>
          ) : null}

          <div className="mt-5 flex items-center gap-3 border-t border-stone-200/80 pt-4">
            <div className="ml-auto flex items-center gap-2">
              <Button
                data-public-id={feature.properties.public_id}
                onClick={() => onFocus(feature.properties.public_id, true)}
                size="sm"
                type="button"
                variant="secondary"
              >
                {copy.map.locate}
              </Button>

              <Button asChild size="sm" variant="ghost">
                <a href={feature.properties.path}>{copy.map.details}</a>
              </Button>
            </div>
          </div>
        </CardContent>
      </article>
    </Card>
  )
}
