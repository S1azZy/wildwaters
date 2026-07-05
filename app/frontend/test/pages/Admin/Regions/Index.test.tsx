import { screen, waitFor, within } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import Index, {
  type AdminRegionsIndexPageProps,
} from "../../../../pages/Admin/Regions/Index"
import { checkAccessibility } from "../../../accessibility"
import { renderInertiaPage } from "../../../inertia"

const props: AdminRegionsIndexPageProps = {
  copy: {
    title: "Regions",
    heading: "Regions",
    description: "Inspect the region hierarchy used by discovery and imports.",
    toolbarLabel: "Admin workspace",
    searchLabel: "Search regions",
    searchPlaceholder: "Name, slug, or country code",
    searchSubmit: "Search",
    emptyCountryCode: "None",
    emptyParentPath: "Root",
    emptyTitle: "No regions found",
    emptyDescription: "Try another search term.",
    tableCaption: "Region hierarchy",
    levelLabel: "Level",
    childrenCount: {
      one: "1 child",
      other: "%{count} children",
      zero: "No children",
    },
    columns: {
      region: "Region",
      kind: "Kind",
      status: "Status",
      countryCode: "Country",
      parentPath: "Parent path",
      children: "Children",
      createdAt: "Created",
    },
    pagination: {
      label: "Regions pages",
      previous: "Previous",
      next: "Next",
      summary: "Showing 1-3 of 27 regions",
    },
  },
  navigation: {
    sections: [
      {
        key: "primary",
        items: [
          {
            key: "dashboard",
            icon: "dashboard",
            label: "Dashboard",
            url: "/admin",
            current: false,
          },
          {
            key: "service_actions",
            icon: "wrench",
            label: "Service actions",
            url: "/admin/service-actions",
            current: false,
          },
        ],
      },
      {
        key: "models",
        label: "Models",
        items: [
          {
            key: "users",
            icon: "users",
            label: "Users",
            url: "/admin/users",
            current: false,
          },
          {
            key: "regions",
            icon: "regions",
            label: "Regions",
            url: "/admin/regions",
            current: true,
          },
        ],
      },
    ],
  },
  pagination: {
    currentPage: 1,
    nextUrl: "/admin/regions?page=2",
    previousUrl: null,
    totalCount: 27,
    totalPages: 2,
  },
  query: {
    q: "bali",
  },
  shell: {
    authenticated: true,
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
      admin: "/admin",
      dashboard: "/dashboard",
      explore: "/",
      signIn: "/session/new",
      signOut: "/session",
    },
  },
  urls: {
    index: "/admin/regions",
  },
  regions: [
    {
      id: "region-1",
      name: "Indonesia",
      slug: "indonesia",
      regionKind: "country",
      status: "active",
      countryCode: "ID",
      parentPath: null,
      depth: 0,
      childrenCount: 1,
      createdAt: "Jul 4, 2026",
    },
    {
      id: "region-2",
      name: "Bali",
      slug: "bali",
      regionKind: "area",
      status: "active",
      countryCode: "ID",
      parentPath: "Indonesia",
      depth: 1,
      childrenCount: 1,
      createdAt: "Jul 4, 2026",
    },
    {
      id: "region-3",
      name: "Ubud",
      slug: "ubud",
      regionKind: "locality",
      status: "archived",
      countryCode: null,
      parentPath: "Indonesia / Bali",
      depth: 2,
      childrenCount: 0,
      createdAt: "Jul 5, 2026",
    },
  ],
}

describe("Admin/Regions/Index", () => {
  it("renders the searchable regions hierarchy table with pagination", async () => {
    const { container } = renderInertiaPage(Index, props)

    expect(screen.getByRole("link", { name: "Regions" })).toHaveAttribute(
      "aria-current",
      "page",
    )
    expect(
      document.querySelector('[data-admin-nav-icon="regions"]'),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("heading", { name: props.copy.heading, level: 1 }),
    ).toBeInTheDocument()

    expect(screen.getByLabelText(props.copy.searchLabel)).toHaveValue("bali")
    expect(
      screen.getByRole("button", { name: props.copy.searchSubmit }),
    ).toBeVisible()

    const table = screen.getByRole("table", { name: props.copy.tableCaption })
    expect(within(table).getAllByText("Indonesia").length).toBeGreaterThan(0)
    expect(within(table).getAllByText("Bali").length).toBeGreaterThan(0)
    expect(within(table).getByText("Ubud")).toBeVisible()
    expect(within(table).getByText("Indonesia / Bali")).toBeVisible()
    expect(within(table).getByText(props.copy.emptyCountryCode)).toBeVisible()
    expect(within(table).getAllByText("1 child")).toHaveLength(2)
    expect(within(table).getByText(props.copy.childrenCount.zero)).toBeVisible()
    expect(
      within(table).getByLabelText(`${props.copy.levelLabel} 2`),
    ).toHaveStyle({ paddingLeft: "2rem" })

    expect(
      screen.getByRole("navigation", { name: props.copy.pagination.label }),
    ).toBeInTheDocument()
    expect(screen.getByText(props.copy.pagination.summary)).toBeVisible()
    expect(
      screen.getByRole("link", { name: props.copy.pagination.next }),
    ).toHaveAttribute("href", "/admin/regions?page=2")

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

  it("renders an empty state for filtered results without regions", () => {
    renderInertiaPage(Index, { ...props, regions: [] })

    expect(
      screen.getByRole("heading", {
        name: props.copy.emptyTitle,
        level: 2,
      }),
    ).toBeVisible()
    expect(screen.getByText(props.copy.emptyDescription)).toBeVisible()
  })
})
