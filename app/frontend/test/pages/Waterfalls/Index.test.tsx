import { screen, waitFor, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it } from "vitest"

import Index, {
  type WaterfallIndexPageProps,
} from "../../../pages/Waterfalls/Index"
import { checkAccessibility } from "../../accessibility"
import { renderInertiaPage } from "../../inertia"

const props: WaterfallIndexPageProps = {
  assets: {
    maplibreScriptUrl: "/assets/maplibre-gl.js",
    maplibreStylesheetUrl: "/assets/maplibre-gl.css",
  },
  copy: {
    title: "Waterfalls",
    filters: {
      allRegions: "All regions",
      anyDifficulty: "Any difficulty",
      anyPlungePool: "Any plunge pool",
      approachDifficulty: "Approach",
      easy: "Easy",
      hard: "Hard",
      minHeight: "Minimum height",
      minHeightPlaceholder: "ex. 30",
      moderate: "Moderate",
      plungePool: "Plunge pool",
      plungePoolNo: "No plunge pool",
      plungePoolYes: "Plunge pool",
      region: "Region",
      reset: "Reset",
      search: "Search visible waterfalls",
      searchPlaceholder: "Search the current list",
    },
    map: {
      details: "Details",
      empty: "No waterfalls match the current map window and filters yet.",
      locate: "Locate",
      mapUnavailable:
        "The map failed to load, but the waterfall list is still available below.",
      noJavascript:
        "JavaScript is disabled, so the map is paused. The waterfall list and filters still work as a regular catalog.",
      railToggle: "Explore waterfalls",
      resultSuffix: "shown",
      styleMenu: "Maps",
      stylePanelHeading: "Map Views",
      zoomIn: "Zoom in",
      zoomOut: "Zoom out",
    },
  },
  filters: {
    approachDifficulty: null,
    minHeightMeters: null,
    plungePool: null,
    regionPublicId: null,
  },
  map: {
    defaultStyleId: "outdoors",
    initialLatitude: -8.2601,
    initialLongitude: 115.1889,
    initialZoom: 7.4,
    panelOpenClass: "is-expanded",
    stylePreferenceKey: "wildwaters:explore-map-style",
  },
  mapStyles: [
    {
      id: "outdoors",
      name: "Outdoors",
      styleUrl: "https://tiles.stadiamaps.com/styles/outdoors.json",
    },
    {
      id: "positron",
      name: "Positron",
      styleUrl: "https://tiles.openfreemap.org/styles/positron",
    },
  ],
  regions: [{ label: "North Bali", value: "north-bali-id" }],
  shell: {
    authenticated: false,
    labels: {
      brandName: "Wild Waters",
      brandTagline: "Swim the World",
      explore: "Explore",
      primaryMobileNavigation: "Primary mobile navigation",
      primaryNavigation: "Primary navigation",
      accountMenu: "Account",
      admin: "Admin",
      mainPage: "Main page",
      profile: "Profile",
      signOut: "Log out",
      signIn: "Log in",
    },
    urls: {
      dashboard: "/dashboard",
      explore: "/",
      signIn: "/session/new",
      signOut: "/session",
    },
  },
  urls: {
    explore: "/waterfalls",
    mapData: "/waterfalls/map_data",
  },
  waterfalls: {
    type: "FeatureCollection",
    features: [
      {
        type: "Feature",
        geometry: {
          type: "Point",
          coordinates: [115.1806, -8.1694],
        },
        properties: {
          approach_difficulty: "moderate",
          height_label: "80.0 m",
          name: "Sekumpul Waterfall",
          path: "/waterfalls/sekumpul",
          plunge_pool_label: "Plunge pool",
          public_id: "sekumpul-id",
          region_name: "North Bali",
          summary: "Twin cascades in North Bali.",
        },
      },
      {
        type: "Feature",
        geometry: {
          type: "Point",
          coordinates: [115.1415, -8.1883],
        },
        properties: {
          approach_difficulty: "easy",
          height_label: "35.0 m",
          name: "Gitgit Waterfall",
          path: "/waterfalls/gitgit",
          plunge_pool_label: null,
          public_id: "gitgit-id",
          region_name: "North Bali",
          summary: "Short jungle walk.",
        },
      },
    ],
  },
}

describe("Waterfalls/Index", () => {
  it("renders the migrated explore shell and remains accessible", async () => {
    const { container } = renderInertiaPage(Index, props)

    expect(screen.getByLabelText(props.copy.filters.search)).toHaveAttribute(
      "placeholder",
      props.copy.filters.searchPlaceholder,
    )
    expect(screen.getByLabelText(props.copy.filters.region)).toHaveValue("")
    expect(screen.getByLabelText(props.copy.filters.minHeight)).toHaveValue(
      null,
    )
    expect(screen.getByLabelText(props.copy.filters.plungePool)).toHaveValue("")
    expect(
      screen.getByLabelText(props.copy.filters.approachDifficulty),
    ).toHaveValue("")

    expect(
      screen.getByRole("button", { name: props.copy.map.railToggle }),
    ).toHaveAttribute("aria-expanded", "false")
    expect(
      screen.getByRole("button", { name: props.copy.map.zoomIn }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: props.copy.map.zoomOut }),
    ).toBeInTheDocument()
    expect(
      screen.getByText(props.copy.map.stylePanelHeading),
    ).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Outdoors" })).toHaveAttribute(
      "aria-pressed",
      "true",
    )

    const list = container.querySelector("[data-explore-map-target='list']")
    expect(list).toBeInTheDocument()
    expect(
      within(list as HTMLElement).getByRole("link", {
        name: "Sekumpul Waterfall",
      }),
    ).toHaveAttribute("href", "/waterfalls/sekumpul")
    expect(
      within(list as HTMLElement).getByRole("link", {
        name: "Gitgit Waterfall",
      }),
    ).toHaveAttribute("href", "/waterfalls/gitgit")
    expect(resultSummary(container)).toHaveTextContent(
      `2 ${props.copy.map.resultSuffix}`,
    )
    expect(document.head.innerHTML).toContain(
      props.assets.maplibreStylesheetUrl,
    )

    await waitFor(() => expect(document.title).toBe(props.copy.title))
    expect(
      (
        await checkAccessibility(container, {
          rules: {
            "color-contrast": { enabled: false },
          },
        })
      ).violations,
    ).toEqual([])
  })

  it("filters visible cards by the client search field", async () => {
    const user = userEvent.setup()
    const { container } = renderInertiaPage(Index, props)

    await user.type(screen.getByLabelText(props.copy.filters.search), "gitgit")

    expect(container).not.toHaveTextContent("Sekumpul Waterfall")
    expect(container).toHaveTextContent("Gitgit Waterfall")
    expect(resultSummary(container)).toHaveTextContent(
      `1 ${props.copy.map.resultSuffix}`,
    )
  })

  it("expands and collapses the results rail with the main toggle", async () => {
    const user = userEvent.setup()
    const { container } = renderInertiaPage(Index, props)
    const toggle = screen.getByRole("button", {
      name: props.copy.map.railToggle,
    })
    const panel = container.querySelector(
      "[data-explore-map-target='resultsPanel']",
    )

    expect(toggle).toHaveAttribute("aria-expanded", "false")
    expect(panel).toHaveAttribute("data-results-state", "collapsed")

    await user.click(toggle)

    expect(toggle).toHaveAttribute("aria-expanded", "true")
    expect(panel).toHaveAttribute("data-results-state", "expanded")
  })
})

function resultSummary(container: HTMLElement) {
  return container.querySelector("[data-explore-map-target='resultsHeader'] p")
}
