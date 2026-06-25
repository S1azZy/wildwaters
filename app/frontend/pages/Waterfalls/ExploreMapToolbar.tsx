import { LayersIcon, MinusIcon, PlusIcon } from "lucide-react"

import { Button } from "../../components/ui/button"
import { IconControlButton } from "../../components/ww"
import type { ExploreCopy, ExploreMapStyle } from "./exploreTypes"

interface ExploreMapToolbarProps {
  activeStyleId: string | null
  copy: ExploreCopy["map"]
  mapStyles: ExploreMapStyle[]
  onStyleSelect: (styleId: string) => void
  onZoomIn: () => void
  onZoomOut: () => void
}

const activeStyleButtonClass =
  "border-fuchsia-700 bg-white text-slate-950 shadow-[0_16px_34px_rgba(15,23,42,0.14)]"
const inactiveStyleButtonClass =
  "border-transparent bg-transparent text-slate-700 hover:border-stone-200 hover:bg-stone-50"

export default function ExploreMapToolbar({
  activeStyleId,
  copy,
  mapStyles,
  onStyleSelect,
  onZoomIn,
  onZoomOut,
}: ExploreMapToolbarProps) {
  return (
    <div className="explore-map-toolbar absolute right-4 top-4 z-20">
      <div className="flex flex-col items-center gap-2.5">
        <details
          className="explore-map-style-menu relative"
          data-explore-map-target="styleMenu"
        >
          <Button
            asChild
            className="explore-map-style-toggle explore-map-toolbar-button rounded-full"
            size="icon"
            variant="outline"
          >
            <summary
              aria-label={copy.styleMenu}
              className="flex cursor-pointer list-none items-center justify-center"
            >
              <LayersIcon aria-hidden="true" />
              <span className="sr-only">{copy.styleMenu}</span>
            </summary>
          </Button>

          <div className="explore-map-style-panel absolute right-[calc(100%+0.9rem)] top-0 z-20 w-[min(22rem,calc(100vw-2.5rem))] rounded-[1.5rem] border border-stone-200 bg-white/98 p-5 text-slate-900 shadow-[0_28px_90px_rgba(15,23,42,0.22)]">
            <p className="mb-4 text-sm font-semibold uppercase tracking-[0.18em] text-slate-500">
              {copy.stylePanelHeading}
            </p>

            <div className="grid grid-cols-2 gap-4">
              {mapStyles.map((style) => (
                <Button
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
                  onClick={() => onStyleSelect(style.id)}
                  type="button"
                  variant="ghost"
                >
                  <span
                    className={`explore-map-style-preview explore-map-style-preview--${style.id}`}
                  >
                    <span className="explore-map-style-preview-inner" />
                  </span>
                  <span className="mt-2 block text-lg font-semibold leading-tight text-slate-800">
                    {style.name}
                  </span>
                </Button>
              ))}
            </div>
          </div>
        </details>

        <IconControlButton
          className="explore-map-toolbar-button"
          label={copy.zoomIn}
          onClick={onZoomIn}
          tooltip={copy.zoomIn}
        >
          <PlusIcon aria-hidden="true" />
        </IconControlButton>

        <IconControlButton
          className="explore-map-toolbar-button"
          label={copy.zoomOut}
          onClick={onZoomOut}
          tooltip={copy.zoomOut}
        >
          <MinusIcon aria-hidden="true" />
        </IconControlButton>
      </div>
    </div>
  )
}
