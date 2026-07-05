import { useCallback, useEffect, useRef } from "react"

import { fitPadding } from "./exploreMapUtils"

export function useExploreViewport(resultsOpen: boolean) {
  const shellRef = useRef<HTMLDivElement | null>(null)

  const updateViewportOffset = useCallback(() => {
    const headerHeight =
      document.querySelector<HTMLElement>("[data-ui='site-header']")
        ?.offsetHeight ?? 0
    const headerOffset = `${headerHeight}px`

    document
      .querySelector<HTMLElement>("#explore-home")
      ?.style.setProperty("--explore-header-offset", headerOffset)
    shellRef.current?.style.setProperty("--explore-header-offset", headerOffset)
  }, [])

  const currentFitPadding = useCallback(
    () => fitPadding(shellRef.current, resultsOpen),
    [resultsOpen],
  )

  useEffect(() => {
    updateViewportOffset()
    window.addEventListener("resize", updateViewportOffset)

    return () => window.removeEventListener("resize", updateViewportOffset)
  }, [updateViewportOffset])

  return { currentFitPadding, shellRef, updateViewportOffset }
}
