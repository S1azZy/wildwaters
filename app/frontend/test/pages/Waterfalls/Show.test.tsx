import { screen, waitFor, within } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import Show, {
  type WaterfallShowPageProps,
} from "../../../pages/Waterfalls/Show"
import { checkAccessibility } from "../../accessibility"
import { renderInertiaPage } from "../../inertia"

const props: WaterfallShowPageProps = {
  copy: {
    back: "Back to all waterfalls",
  },
  shell: {
    authenticated: false,
    labels: {
      brandName: "Wild Waters",
      brandTagline: "Swim the World",
      explore: "Explore",
      primaryMobileNavigation: "Primary mobile navigation",
      primaryNavigation: "Primary navigation",
      profile: "Profile",
      signIn: "Log in",
    },
    urls: {
      dashboard: "/dashboard",
      explore: "/",
      signIn: "/session/new",
    },
  },
  urls: {
    explore: "/waterfalls",
  },
  waterfall: {
    publicId: "waterfall-public-id",
    name: "Sekumpul Waterfall",
    regionName: "North Bali",
    summary: "Twin cascades in North Bali.",
    description: "A dramatic jungle waterfall.",
    facts: [
      { key: "height", label: "Height", value: "80.0 m" },
      {
        key: "flowSeasonality",
        label: "Flow seasonality",
        value: "Year round",
      },
      {
        key: "approachDifficulty",
        label: "Approach",
        value: "Moderate",
      },
      { key: "plungePool", label: "Plunge pool", value: "Yes" },
    ],
  },
}

describe("Waterfalls/Show", () => {
  it("renders the public detail contract in order and remains accessible", async () => {
    const { container } = renderInertiaPage(Show, props)

    expect(
      screen.getByRole("heading", { name: props.waterfall.name }),
    ).toBeInTheDocument()
    expect(screen.getByText(props.waterfall.regionName)).toBeInTheDocument()
    expect(screen.getByText(props.waterfall.summary!)).toBeInTheDocument()
    expect(screen.getByText(props.waterfall.description!)).toBeInTheDocument()

    const facts = within(screen.getByTestId("waterfall-facts")).getAllByTestId(
      "waterfall-fact",
    )
    expect(
      facts.map((fact) => within(fact).getByRole("term").textContent),
    ).toEqual(props.waterfall.facts.map(({ label }) => label))

    const explore = screen.getByRole("link", { name: props.copy.back })
    expect(explore).toHaveAttribute("href", props.urls.explore)
    expect(explore).toBeInstanceOf(HTMLAnchorElement)
    explore.focus()
    expect(explore).toHaveFocus()

    expect(container.querySelector("[data-waterfall-detail]")).toBeVisible()
    await waitFor(() => expect(document.title).toBe(props.waterfall.name))
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

  it("omits empty optional content and absent facts", () => {
    renderInertiaPage(Show, {
      ...props,
      waterfall: {
        ...props.waterfall,
        summary: null,
        description: null,
        facts: props.waterfall.facts.slice(-1),
      },
    })

    expect(screen.queryByText("Twin cascades in North Bali.")).toBeNull()
    expect(screen.queryByText("A dramatic jungle waterfall.")).toBeNull()
    expect(screen.queryByText("Height")).toBeNull()
    expect(screen.getByText("Plunge pool")).toBeInTheDocument()
  })
})
