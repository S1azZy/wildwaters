import { screen, waitFor, within } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import Index, {
  type AdminServiceActionsPageProps,
} from "../../../../pages/Admin/ServiceActions/Index"
import { checkAccessibility } from "../../../accessibility"
import { renderInertiaPage } from "../../../inertia"

const props: AdminServiceActionsPageProps = {
  copy: {
    title: "Service actions",
    heading: "Service actions",
    description: "Run and monitor operational commands.",
    toolbarLabel: "Admin workspace",
    importRegions: {
      title: "GeoNames region import",
      description: "Queue a region import from environment settings.",
      button: "Start import",
      emptyTitle: "No import runs yet",
      emptyDescription: "Start the first import when the environment is ready.",
      latestRunTitle: "Latest run",
      settingsTitle: "Settings snapshot",
      resultsTitle: "Results",
      failureTitle: "Failure",
      fields: {
        status: "Status",
        mode: "Mode",
        initiatedBy: "Initiated by",
        startedAt: "Started",
        finishedAt: "Finished",
        countries: "Countries",
        languages: "Languages",
        featureCodes: "Feature codes",
        itemCounts: "Items",
      },
      statusLabels: {
        queued: "Queued",
        running: "Running",
        succeeded: "Succeeded",
        failed: "Failed",
        partiallyFailed: "Partially failed",
        cancelled: "Cancelled",
      },
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
            current: true,
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
        ],
      },
    ],
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
    serviceActions: "/admin/service-actions",
    geonamesRegionImport: "/admin/service-actions/geonames-region-import",
  },
  geonamesImport: {
    latestRun: null,
  },
}

describe("Admin/ServiceActions/Index", () => {
  it("renders the admin shell and GeoNames import action panel", async () => {
    const { container } = renderInertiaPage(Index, props)

    expect(
      screen.getByRole("banner", { name: props.copy.toolbarLabel }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("navigation", { name: props.copy.toolbarLabel }),
    ).toBeInTheDocument()
    expect(screen.getByRole("link", { name: "Dashboard" })).toHaveAttribute(
      "href",
      "/admin",
    )
    expect(
      screen.getByRole("link", { name: "Service actions" }),
    ).toHaveAttribute("aria-current", "page")
    expect(screen.getByText("Models")).toBeVisible()
    expect(screen.getByRole("link", { name: "Users" })).toHaveAttribute(
      "href",
      "/admin/users",
    )
    expect(
      document.querySelector('[data-admin-nav-icon="wrench"]'),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("heading", { name: props.copy.heading, level: 1 }),
    ).toBeInTheDocument()
    expect(screen.getByText(props.copy.description)).toBeInTheDocument()
    expect(
      screen.getByRole("heading", {
        name: props.copy.importRegions.title,
        level: 2,
      }),
    ).toBeInTheDocument()
    expect(screen.getByText(props.copy.importRegions.description)).toBeVisible()
    expect(
      screen.getByRole("heading", {
        name: props.copy.importRegions.emptyTitle,
        level: 3,
      }),
    ).toBeInTheDocument()
    expect(
      screen.getByText(props.copy.importRegions.emptyDescription),
    ).toBeVisible()

    const form = container.querySelector(
      'form[action="/admin/service-actions/geonames-region-import"][method="post"]',
    )
    expect(form).toBeInTheDocument()
    expect(
      within(form as HTMLFormElement).getByRole("button", {
        name: props.copy.importRegions.button,
      }),
    ).toHaveAttribute("type", "submit")
    expect(screen.queryByLabelText(/countries/i)).toBeNull()
    expect(screen.queryByLabelText(/languages/i)).toBeNull()

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

  it("renders the latest GeoNames import summary and sanitized failure", () => {
    renderInertiaPage(Index, {
      ...props,
      geonamesImport: {
        latestRun: {
          id: 42,
          status: "partially_failed",
          mode: "full",
          initiatedBy: "admin/service-actions/geonames-region-import#create",
          startedAt: "2026-07-05T10:00:00Z",
          finishedAt: "2026-07-05T10:03:00Z",
          settings: {
            countries: ["AD", "FR"],
            languages: ["en", "ru"],
            featureCodes: ["PCLI", "ADM1"],
            downloadAlternateNames: true,
            downloadDir: "tmp/imports/geonames",
          },
          stats: {
            processedCount: 12,
            createdRegionCount: 3,
            missingUpstreamCount: 1,
          },
          itemCounts: {
            succeeded: 1,
            failed: 1,
          },
          failure: {
            className: "Imports::GeoNames::DownloadError",
            message: "Unable to download GeoNames dump",
            itemMessages: ["FR: HTTP 500"],
          },
        },
      },
    })

    expect(
      screen.getByRole("heading", {
        name: props.copy.importRegions.latestRunTitle,
        level: 3,
      }),
    ).toBeVisible()
    expect(screen.getAllByText("Partially failed").length).toBeGreaterThan(0)
    expect(screen.getByText("AD, FR")).toBeVisible()
    expect(screen.getByText("en, ru")).toBeVisible()
    expect(screen.getByText("PCLI, ADM1")).toBeVisible()
    expect(screen.getByText("processedCount: 12")).toBeVisible()
    expect(screen.getByText("createdRegionCount: 3")).toBeVisible()
    expect(screen.getByText("missingUpstreamCount: 1")).toBeVisible()
    expect(screen.getByText("FR: HTTP 500")).toBeVisible()
    expect(screen.queryByText(/token/i)).toBeNull()
    expect(screen.queryByText(/password/i)).toBeNull()
  })
})
