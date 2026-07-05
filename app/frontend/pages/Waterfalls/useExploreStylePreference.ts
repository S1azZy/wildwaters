import { useCallback, useMemo, useState } from "react"

import {
  persistStylePreference,
  resolveInitialStyleId,
} from "./exploreMapUtils"
import type { ExploreMapStyle } from "./exploreTypes"

export function useExploreStylePreference(
  mapStyles: ExploreMapStyle[],
  defaultStyleId: string,
  preferenceKey: string,
) {
  const [activeStyleId, setActiveStyleId] = useState(() =>
    resolveInitialStyleId(mapStyles, defaultStyleId, preferenceKey),
  )
  const styleUrl = useMemo(
    () =>
      mapStyles.find((style) => style.id === activeStyleId)?.styleUrl ??
      mapStyles[0]?.styleUrl,
    [activeStyleId, mapStyles],
  )
  const selectStyle = useCallback(
    (styleId: string) => {
      setActiveStyleId(styleId)
      persistStylePreference(preferenceKey, styleId)
    },
    [preferenceKey],
  )

  return { activeStyleId, selectStyle, styleUrl }
}
