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
          <summary
            aria-label={copy.styleMenu}
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
            <span className="sr-only">{copy.styleMenu}</span>
          </summary>

          <div className="explore-map-style-panel absolute right-[calc(100%+0.9rem)] top-0 z-20 w-[min(22rem,calc(100vw-2.5rem))] rounded-[1.5rem] border border-stone-200 bg-white/98 p-5 text-slate-900 shadow-[0_28px_90px_rgba(15,23,42,0.22)]">
            <p className="mb-4 text-sm font-semibold uppercase tracking-[0.18em] text-slate-500">
              {copy.stylePanelHeading}
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
                  onClick={() => onStyleSelect(style.id)}
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
          aria-label={copy.zoomIn}
          className="explore-map-toolbar-button"
          onClick={onZoomIn}
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
          aria-label={copy.zoomOut}
          className="explore-map-toolbar-button"
          onClick={onZoomOut}
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
  )
}
