export interface MapBounds {
  getEast(): number
  getNorth(): number
  getSouth(): number
  getWest(): number
}

export interface MapFeatureEvent {
  features?: Array<{
    geometry: {
      coordinates: [number, number]
    }
    properties?: {
      cluster_id?: number
      public_id?: string
    }
  }>
}

export interface MapGeoJsonSource {
  getClusterExpansionZoom(
    clusterId: number,
    callback: (error: unknown, zoom: number) => void,
  ): void
  setData(data: unknown): void
}

export interface MapInstance {
  addControl(control: unknown, position: string): void
  addLayer(layer: unknown): void
  addSource(id: string, source: unknown): void
  easeTo(options: unknown): void
  fitBounds(bounds: unknown, options: unknown): void
  getBounds(): MapBounds
  getCanvas(): HTMLElement
  getSource(id: string): MapGeoJsonSource | undefined
  getZoom(): number
  isStyleLoaded(): boolean
  on(event: string, handler: () => void): void
  on(
    event: string,
    layerId: string,
    handler: (event: MapFeatureEvent) => void,
  ): void
  remove(): void
  resize(): void
  setStyle(styleUrl: string): void
  zoomIn(): void
  zoomOut(): void
}

export interface MapLibreGlobal {
  AttributionControl: new (options: unknown) => unknown
  LngLatBounds: new () => {
    extend(coordinates: [number, number]): void
  }
  Map: new (options: unknown) => MapInstance
}

declare global {
  interface Window {
    maplibregl?: MapLibreGlobal
  }
}

let pendingLoad: Promise<MapLibreGlobal> | null = null

export function loadMapLibre(scriptUrl: string): Promise<MapLibreGlobal> {
  if (window.maplibregl) {
    return Promise.resolve(window.maplibregl)
  }

  pendingLoad ??= new Promise<MapLibreGlobal>((resolve, reject) => {
    const existingScript = document.querySelector<HTMLScriptElement>(
      `script[data-maplibre-loader][src="${scriptUrl}"]`,
    )

    if (existingScript) {
      existingScript.addEventListener("load", () =>
        resolveLoaded(resolve, reject),
      )
      existingScript.addEventListener("error", () =>
        reject(new Error("MapLibre failed to load")),
      )
      return
    }

    const script = document.createElement("script")
    script.async = true
    script.dataset.maplibreLoader = "true"
    script.src = scriptUrl
    script.addEventListener("load", () => resolveLoaded(resolve, reject))
    script.addEventListener("error", () =>
      reject(new Error("MapLibre failed to load")),
    )
    document.head.append(script)
  })

  return pendingLoad
}

function resolveLoaded(
  resolve: (maplibre: MapLibreGlobal) => void,
  reject: (error: Error) => void,
) {
  if (window.maplibregl) {
    resolve(window.maplibregl)
    return
  }

  reject(new Error("MapLibre loaded without exposing window.maplibregl"))
}
