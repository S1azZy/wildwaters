import { Controller } from "@hotwired/stimulus"
import "maplibre-gl"

const maplibregl = window.maplibregl

const DEFAULT_SELECTED_CARD_CLASS =
  "ring-2 ring-emerald-700 border-emerald-300 shadow-[0_28px_80px_rgba(5,150,105,0.18)]"
const ACTIVE_STYLE_BUTTON_CLASS =
  "border-fuchsia-700 bg-white text-slate-950 shadow-[0_16px_34px_rgba(15,23,42,0.14)]"
const INACTIVE_STYLE_BUTTON_CLASS =
  "border-transparent bg-transparent text-slate-700 hover:border-stone-200 hover:bg-stone-50"
const DEFAULT_STYLE_PREFERENCE_KEY = "wildwaters:explore-map-style"
const DEFAULT_CARD_CLASS_TEMPLATE =
  "group rounded-[1.35rem] border border-white/80 bg-white/95 p-4 shadow-[0_18px_50px_rgba(15,23,42,0.1)] transition hover:-translate-y-0.5 hover:border-emerald-300 hover:shadow-[0_28px_80px_rgba(15,23,42,0.14)] focus-within:border-emerald-300 focus-within:ring-2 focus-within:ring-emerald-200 backdrop-blur"

export default class extends Controller {
  static targets = [
    "canvas",
    "card",
    "controlsPanel",
    "empty",
    "filters",
    "list",
    "loading",
    "mapState",
    "resultCount",
    "resultsPanel",
    "resultsToggle",
    "search",
    "shell",
    "styleButton",
    "styleMenu",
    "status"
  ]

  static values = {
    defaultStyleId: String,
    detailsLabel: String,
    emptyLabel: String,
    initialLatitude: Number,
    initialLongitude: Number,
    initialZoom: Number,
    listHint: String,
    listMode: String,
    loadingLabel: String,
    locateLabel: String,
    mapDataUrl: String,
    mapStyleUrl: String,
    mapUnavailableLabel: String,
    panelOpenClass: String,
    stylePreferenceKey: String,
    visibleLabel: String
  }

  connect() {
    this.allFeatures = []
    this.enhancedMode = false
    this.featuresLoaded = false
    this.featuresByPublicId = new Map()
    this.selectedPublicId = null
    this.activeStyleId = this.resolveInitialStyleId()
    this.resultsOpen = false

    if (!this.hasCanvasTarget || typeof maplibregl.Map !== "function") {
      this.renderMapUnavailable()
      return
    }

    this.syncStyleButtons()
    this.syncResultsPanel()
    this.enhancedMode = true
    this.handleResize = () => {
      this.syncViewportOffset()
      this.resizeMap()
    }
    this.syncViewportOffset()
    this.buildMap()
    this.observeShellResize()
    window.addEventListener("resize", this.handleResize)
  }

  toggleResults(event) {
    event?.preventDefault()

    this.resultsOpen = !this.resultsOpen
    this.syncResultsPanel()
    this.resizeMap()
  }

  disconnect() {
    clearTimeout(this.filterTimer)
    this.abortController?.abort()
    this.resizeObserver?.disconnect()
    this.map?.remove()
    window.removeEventListener("resize", this.handleResize)
  }

  filtersChanged(event) {
    if (!this.enhancedMode) {
      return
    }

    event.preventDefault()

    clearTimeout(this.filterTimer)
    this.filterTimer = setTimeout(() => this.loadFeatures({ fitToResults: true }), 180)
  }

  searchChanged() {
    if (!this.featuresLoaded) {
      return
    }

    this.applyFeatureState()
  }

  focusCard(event) {
    if (!this.featuresLoaded) {
      return
    }

    const publicId = event.currentTarget.dataset.publicId

    if (!publicId) {
      return
    }

    this.selectFeature(publicId, { flyTo: true })
  }

  cardSelected(event) {
    if (!this.featuresLoaded) {
      return
    }

    if (event.target.closest("a, button")) {
      return
    }

    const publicId = event.currentTarget.dataset.publicId

    if (!publicId) {
      return
    }

    this.selectFeature(publicId, { flyTo: true })
  }

  switchStyle(event) {
    if (!this.enhancedMode || !this.map) {
      return
    }

    event.preventDefault()

    const styleId = event.currentTarget.dataset.styleId
    const styleUrl = this.styleUrlFor(styleId)

    if (!styleId || !styleUrl || styleId === this.activeStyleId) {
      return
    }

    this.activeStyleId = styleId
    this.persistStylePreference(styleId)
    this.syncStyleButtons()
    this.setLoading(true)
    this.map.setStyle(styleUrl)
    this.closeStyleMenu()
  }

  buildMap() {
    this.map = new maplibregl.Map({
      container: this.canvasTarget,
      style: this.currentStyleUrl(),
      center: [ this.initialLongitudeValue, this.initialLatitudeValue ],
      zoom: this.initialZoomValue,
      attributionControl: false
    })

    this.map.addControl(
      new maplibregl.NavigationControl({ showCompass: false }),
      "top-right"
    )
    this.map.addControl(
      new maplibregl.AttributionControl({ compact: true }),
      "bottom-right"
    )

    this.map.on("style.load", () => {
      this.resizeMap()
      this.ensureMapLayers()
      this.loadFeatures({ fitToResults: !this.featuresLoaded })
    })
    this.map.on("moveend", () => this.loadFeatures())
  }

  observeShellResize() {
    if (!this.hasShellTarget || typeof ResizeObserver === "undefined") {
      return
    }

    this.resizeObserver = new ResizeObserver((entries) => {
      if (entries.some((entry) => entry.contentRect.width > 0 && entry.contentRect.height > 0)) {
        this.syncViewportOffset()
        this.resizeMap()
      }
    })

    this.resizeObserver.observe(this.shellTarget)
    const header = this.headerElement()

    if (header) {
      this.resizeObserver.observe(header)
    }
  }

  resizeMap() {
    if (!this.map) {
      return
    }

    requestAnimationFrame(() => this.map?.resize())
  }

  syncViewportOffset() {
    if (!this.hasShellTarget) {
      return
    }

    const headerHeight = this.headerElement()?.offsetHeight || 0

    this.element.style.setProperty("--explore-header-offset", `${headerHeight}px`)
    this.shellTarget.style.setProperty("--explore-header-offset", `${headerHeight}px`)
  }

  headerElement() {
    return document.querySelector("[data-ui='site-header']")
  }

  ensureMapLayers() {
    if (this.map.getSource("waterfalls")) {
      return
    }

    this.map.addSource("waterfalls", {
      type: "geojson",
      data: { type: "FeatureCollection", features: [] },
      cluster: true,
      clusterMaxZoom: 11,
      clusterRadius: 42
    })

    this.map.addLayer({
      id: "waterfall-clusters",
      type: "circle",
      source: "waterfalls",
      filter: [ "has", "point_count" ],
      paint: {
        "circle-color": "#183028",
        "circle-stroke-color": "#efe6d5",
        "circle-stroke-width": 3,
        "circle-radius": [
          "step",
          [ "get", "point_count" ],
          20,
          8,
          24,
          16,
          30
        ]
      }
    })

    this.map.addLayer({
      id: "waterfall-cluster-count",
      type: "symbol",
      source: "waterfalls",
      filter: [ "has", "point_count" ],
      layout: {
        "text-field": [ "get", "point_count_abbreviated" ],
        "text-size": 12
      },
      paint: {
        "text-color": "#f8fafc"
      }
    })

    this.map.addLayer({
      id: "waterfall-points",
      type: "circle",
      source: "waterfalls",
      filter: [ "!", [ "has", "point_count" ] ],
      paint: {
        "circle-color": "#c2743f",
        "circle-radius": 8,
        "circle-stroke-color": "#fffbeb",
        "circle-stroke-width": 2.5
      }
    })

    this.map.on("click", "waterfall-points", (event) => {
      const publicId = event.features?.[0]?.properties?.public_id

      if (!publicId) {
        return
      }

      this.selectFeature(publicId)
    })

    this.map.on("click", "waterfall-clusters", (event) => {
      const clusterFeature = event.features?.[0]
      const clusterId = clusterFeature?.properties?.cluster_id

      if (!clusterFeature || clusterId == null) {
        return
      }

      this.map.getSource("waterfalls").getClusterExpansionZoom(clusterId, (error, zoom) => {
        if (error) {
          return
        }

        this.map.easeTo({
          center: clusterFeature.geometry.coordinates,
          zoom
        })
      })
    })

    this.map.on("mouseenter", "waterfall-points", () => {
      this.map.getCanvas().style.cursor = "pointer"
    })
    this.map.on("mouseleave", "waterfall-points", () => {
      this.map.getCanvas().style.cursor = ""
    })
  }

  async loadFeatures({ fitToResults = false } = {}) {
    if (!this.map?.isStyleLoaded()) {
      return
    }

    this.setLoading(true)
    this.setStatus(this.loadingLabelValue)
    this.abortController?.abort()
    this.abortController = new AbortController()

    try {
      const response = await fetch(this.mapDataUrl(), {
        headers: { Accept: "application/json" },
        signal: this.abortController.signal
      })

      if (!response.ok) {
        this.showMapState(this.mapUnavailableLabelValue, { persistent: true })
        this.setStatus(this.mapUnavailableLabelValue)
        return
      }

      const featureCollection = await response.json()

      this.map.getSource("waterfalls").setData(featureCollection)
      this.featuresLoaded = true
      this.allFeatures = featureCollection.features
      this.featuresByPublicId = new Map(
        featureCollection.features.map((feature) => [ feature.properties.public_id, feature ])
      )
      this.applyFeatureState()

      if (fitToResults) {
        this.fitToFeatures(featureCollection.features)
      }

      this.hideMapState(true)
    } catch (error) {
      if (error.name !== "AbortError") {
        this.showMapState(this.mapUnavailableLabelValue, { persistent: true })
        this.setStatus(this.mapUnavailableLabelValue)
      }
    } finally {
      this.setLoading(false)
    }
  }

  mapDataUrl() {
    const query = new URLSearchParams(new FormData(this.filtersTarget))
    const bounds = this.map.getBounds()

    query.set("west", bounds.getWest())
    query.set("south", bounds.getSouth())
    query.set("east", bounds.getEast())
    query.set("north", bounds.getNorth())

    return `${this.mapDataUrlValue}?${query.toString()}`
  }

  fitToFeatures(features) {
    if (features.length === 0) {
      return
    }

    const bounds = new maplibregl.LngLatBounds()
    features.forEach((feature) => bounds.extend(feature.geometry.coordinates))

    this.map.fitBounds(bounds, {
      padding: this.fitPadding(),
      maxZoom: 11,
      duration: 0
    })
  }

  fitPadding() {
    const padding = { top: 72, right: 56, bottom: 56, left: 56 }

    if (!this.hasShellTarget) {
      return padding
    }

    const shellRect = this.shellTarget.getBoundingClientRect()

    if (this.hasControlsPanelTarget) {
      const controlsRect = this.controlsPanelTarget.getBoundingClientRect()
      padding.top = Math.max(padding.top, Math.ceil(controlsRect.bottom - shellRect.top) + 24)
    }

    if (this.hasResultsPanelTarget && this.resultsOpen) {
      const resultsRect = this.resultsPanelTarget.getBoundingClientRect()
      const resultsWidthRatio = resultsRect.width / Math.max(shellRect.width, 1)
      const bottomInset = Math.ceil(shellRect.bottom - resultsRect.top) + 24

      if (resultsWidthRatio > 0.55) {
        padding.bottom = Math.max(padding.bottom, bottomInset)
      } else {
        padding.left = Math.max(padding.left, Math.ceil(resultsRect.right - shellRect.left) + 24)
      }
    }

    return padding
  }

  renderList(features) {
    this.listTarget.replaceChildren()

    if (features.length === 0) {
      this.emptyTarget.classList.remove("hidden")
      this.emptyTarget.textContent = this.emptyLabelValue
      return
    }

    this.emptyTarget.classList.add("hidden")

    features.forEach((feature) => {
      this.listTarget.append(this.buildCard(feature))
    })

    if (this.selectedPublicId) {
      this.highlightSelectedCard(this.selectedPublicId)
    }
  }

  syncResultsPanel() {
    if (this.hasResultsPanelTarget) {
      this.resultsPanelTarget.dataset.resultsState = this.resultsOpen ? "expanded" : "collapsed"
      this.resultsPanelTarget.classList.toggle("is-collapsed", !this.resultsOpen)
      this.resultsPanelTarget.classList.toggle(this.panelOpenClass, this.resultsOpen)
    }

    if (this.hasResultsToggleTarget) {
      this.resultsToggleTarget.dataset.resultsState = this.resultsOpen ? "expanded" : "collapsed"
      this.resultsToggleTarget.setAttribute("aria-expanded", String(this.resultsOpen))
    }
  }

  buildCard(feature) {
    const article = document.createElement("article")
    article.className = this.cardClassTemplate()
    article.dataset.action = "click->explore-map#cardSelected"
    article.dataset.exploreMapTarget = "card"
    article.dataset.publicId = feature.properties.public_id
    article.dataset.searchText = this.searchableText(feature)
    article.dataset.longitude = feature.geometry.coordinates[0]
    article.dataset.latitude = feature.geometry.coordinates[1]

    const header = document.createElement("div")
    header.className = "flex items-start justify-between gap-4"

    const content = document.createElement("div")
    content.className = "min-w-0 flex-1 space-y-3"

    const meta = document.createElement("div")
    meta.className = "flex flex-wrap items-center gap-2"

    meta.append(this.buildChip(feature.properties.region_name, "bg-stone-100 text-emerald-900/65"))

    if (feature.properties.approach_difficulty) {
      meta.append(
        this.buildChip(
          this.humanize(feature.properties.approach_difficulty),
          "bg-emerald-50 text-emerald-900"
        )
      )
    }

    const title = document.createElement("a")
    title.className = "block font-serif text-2xl leading-tight text-slate-950 transition group-hover:text-emerald-900"
    title.href = feature.properties.path
    title.textContent = feature.properties.name

    content.append(meta, title)

    if (feature.properties.summary) {
      const summary = document.createElement("p")
      summary.className = "line-clamp-2 text-sm leading-6 text-slate-600"
      summary.textContent = feature.properties.summary
      content.append(summary)
    }

    header.append(content)

    if (feature.properties.height_label) {
      header.append(this.buildChip(feature.properties.height_label, "shrink-0 bg-emerald-950 text-emerald-50"))
    }

    const chips = document.createElement("div")
    chips.className = "mt-4 flex flex-wrap gap-2 text-xs font-medium text-slate-600"

    if (feature.properties.plunge_pool_label) {
      chips.append(this.buildChip(feature.properties.plunge_pool_label, "bg-sky-50 text-sky-800"))
    }

    const footer = document.createElement("div")
    footer.className = "mt-5 flex items-center justify-between gap-3 border-t border-stone-200/80 pt-4"

    const mode = document.createElement("span")
    mode.className = "text-[0.68rem] font-semibold uppercase tracking-[0.24em] text-slate-400"
    mode.textContent = this.listModeValue

    const actions = document.createElement("div")
    actions.className = "flex items-center gap-2"

    const locate = document.createElement("button")
    locate.type = "button"
    locate.className =
      "inline-flex items-center gap-2 rounded-full border border-emerald-200 bg-emerald-50 px-3 py-2 text-[0.68rem] font-semibold uppercase tracking-[0.16em] text-emerald-900 transition hover:border-emerald-300 hover:bg-emerald-100"
    locate.dataset.action = "explore-map#focusCard"
    locate.dataset.publicId = feature.properties.public_id
    locate.textContent = this.locateLabelValue

    const details = document.createElement("a")
    details.className =
      "inline-flex items-center gap-2 rounded-full px-3 py-2 text-[0.68rem] font-semibold uppercase tracking-[0.16em] text-slate-600 transition hover:bg-stone-100 hover:text-slate-950"
    details.href = feature.properties.path
    details.textContent = this.detailsLabelValue

    actions.append(locate, details)
    footer.append(mode, actions)

    article.append(header)

    if (chips.childElementCount > 0) {
      article.append(chips)
    }

    article.append(footer)

    return article
  }

  selectFeature(publicId, { flyTo = false } = {}) {
    const feature = this.featuresByPublicId.get(publicId)

    if (!feature) {
      return
    }

    this.selectedPublicId = publicId

    if (this.hasSearchTarget && this.searchTarget.value && !this.featureMatchesSearch(feature)) {
      this.searchTarget.value = ""
      this.applyFeatureState()
    }

    this.highlightSelectedCard(publicId)

    const selectedCard = this.cardTargets.find((card) => card.dataset.publicId === publicId)
    selectedCard?.scrollIntoView({ block: "nearest", behavior: "smooth" })

    if (flyTo) {
      this.map.easeTo({
        center: feature.geometry.coordinates,
        padding: this.fitPadding(),
        zoom: Math.max(this.map.getZoom(), 10.5),
        duration: 700
      })
    }
  }

  updateResultCount(count) {
    if (this.hasResultCountTarget) {
      this.resultCountTarget.textContent = count
    }

    if (this.hasHeroResultCountTarget) {
      this.heroResultCountTarget.textContent = count
    }
  }

  renderMapUnavailable() {
    this.setLoading(false)
    this.showMapState(this.mapUnavailableLabelValue, { persistent: true })
    this.setStatus(this.mapUnavailableLabelValue)
  }

  resolveInitialStyleId() {
    const availableStyleIds = this.availableStyleIds()

    if (availableStyleIds.length === 0) {
      return null
    }

    const savedStyleId = this.readStylePreference()

    if (savedStyleId && availableStyleIds.includes(savedStyleId)) {
      return savedStyleId
    }

    if (this.hasDefaultStyleIdValue && availableStyleIds.includes(this.defaultStyleIdValue)) {
      return this.defaultStyleIdValue
    }

    return availableStyleIds[0]
  }

  availableStyleIds() {
    return this.hasStyleButtonTarget ? this.styleButtonTargets.map((button) => button.dataset.styleId) : []
  }

  currentStyleUrl() {
    return this.styleUrlFor(this.activeStyleId) || this.mapStyleUrlValue
  }

  styleUrlFor(styleId) {
    if (!styleId || !this.hasStyleButtonTarget) {
      return null
    }

    return this.styleButtonTargets.find((button) => button.dataset.styleId === styleId)?.dataset.styleUrl || null
  }

  syncStyleButtons() {
    if (!this.hasStyleButtonTarget) {
      return
    }

    this.styleButtonTargets.forEach((button) => {
      const isActive = button.dataset.styleId === this.activeStyleId

      button.setAttribute("aria-pressed", isActive ? "true" : "false")
      button.classList.remove(...ACTIVE_STYLE_BUTTON_CLASS.split(" "), ...INACTIVE_STYLE_BUTTON_CLASS.split(" "))
      button.classList.add(...(isActive ? ACTIVE_STYLE_BUTTON_CLASS : INACTIVE_STYLE_BUTTON_CLASS).split(" "))
    })
  }

  closeStyleMenu() {
    if (!this.hasStyleMenuTarget) {
      return
    }

    this.styleMenuTarget.removeAttribute("open")
  }

  readStylePreference() {
    if (typeof window === "undefined" || !window.localStorage) {
      return null
    }

    try {
      return window.localStorage.getItem(this.stylePreferenceKey())
    } catch {
      return null
    }
  }

  persistStylePreference(styleId) {
    if (!styleId || typeof window === "undefined" || !window.localStorage) {
      return
    }

    try {
      window.localStorage.setItem(this.stylePreferenceKey(), styleId)
    } catch {
      // Ignore storage failures and keep the in-memory selection.
    }
  }

  stylePreferenceKey() {
    return this.hasStylePreferenceKeyValue ? this.stylePreferenceKeyValue : DEFAULT_STYLE_PREFERENCE_KEY
  }

  buildChip(text, classes) {
    const chip = document.createElement("span")
    chip.className = `rounded-full px-3 py-1 text-[0.68rem] font-semibold uppercase tracking-[0.24em] ${classes}`
    chip.textContent = text

    return chip
  }

  humanize(value) {
    return value.replaceAll("_", " ").replace(/\b\w/g, (match) => match.toUpperCase())
  }

  setStatus(message) {
    if (!this.hasStatusTarget) {
      return
    }

    this.statusTarget.textContent = message
  }

  setLoading(isLoading) {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.toggle("hidden", !isLoading)
    }

    if (this.hasListTarget) {
      this.listTarget.classList.toggle("opacity-60", isLoading)
    }

    this.element.ariaBusy = isLoading ? "true" : "false"

    if (isLoading) {
      this.showMapState(this.loadingLabelValue)
    } else {
      this.hideMapState()
    }
  }

  showMapState(message, { persistent = false } = {}) {
    if (!this.hasMapStateTarget) {
      return
    }

    this.mapStateTarget.dataset.persistent = persistent ? "true" : "false"
    this.mapStateTarget.classList.remove("hidden")
    this.mapStateTarget.classList.add("flex")

    if (this.mapStateTarget.firstElementChild) {
      this.mapStateTarget.firstElementChild.textContent = message
    }
  }

  hideMapState(force = false) {
    if (!this.hasMapStateTarget) {
      return
    }

    if (!force && this.mapStateTarget.dataset.persistent === "true") {
      return
    }

    this.mapStateTarget.dataset.persistent = "false"
    this.mapStateTarget.classList.add("hidden")
    this.mapStateTarget.classList.remove("flex")
  }

  applyFeatureState() {
    const visibleFeatures = this.filteredFeatures()

    this.renderList(visibleFeatures)
    this.updateResultCount(visibleFeatures.length)
    this.setStatus(this.statusMessage(visibleFeatures.length))
  }

  filteredFeatures() {
    if (!this.hasSearchTarget) {
      return this.allFeatures
    }

    const query = this.searchTarget.value.trim().toLowerCase()

    if (query.length === 0) {
      return this.allFeatures
    }

    return this.allFeatures.filter((feature) => this.searchableText(feature).includes(query))
  }

  featureMatchesSearch(feature) {
    if (!this.hasSearchTarget) {
      return true
    }

    const query = this.searchTarget.value.trim().toLowerCase()

    if (query.length === 0) {
      return true
    }

    return this.searchableText(feature).includes(query)
  }

  searchableText(feature) {
    return [
      feature.properties.name,
      feature.properties.summary,
      feature.properties.region_name,
      feature.properties.approach_difficulty,
      feature.properties.flow_seasonality
    ].filter(Boolean).join(" ").toLowerCase()
  }

  highlightSelectedCard(publicId) {
    this.cardTargets.forEach((card) => {
      if (card.dataset.publicId === publicId) {
        card.classList.add(...DEFAULT_SELECTED_CARD_CLASS.split(" "))
      } else {
        card.classList.remove(...DEFAULT_SELECTED_CARD_CLASS.split(" "))
      }
    })
  }

  statusMessage(visibleCount) {
    const totalCount = this.allFeatures.length

    if (this.hasSearchTarget && this.searchTarget.value.trim().length > 0) {
      return `${visibleCount} / ${totalCount} ${this.visibleLabelValue}`
    }

    return this.listHintValue
  }

  cardClassTemplate() {
    return this.listTarget.dataset.cardClassTemplate || DEFAULT_CARD_CLASS_TEMPLATE
  }
}
