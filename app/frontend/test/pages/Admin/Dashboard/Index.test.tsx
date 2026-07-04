import { screen, waitFor } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import Index, {
  type AdminDashboardPageProps,
} from "../../../../pages/Admin/Dashboard/Index"
import { checkAccessibility } from "../../../accessibility"
import { renderInertiaPage } from "../../../inertia"

const props: AdminDashboardPageProps = {
  copy: {
    title: "Dashboard",
    heading: "Dashboard",
    description: "Admin overview will appear here as models mature.",
    toolbarLabel: "Admin workspace",
    placeholderTitle: "Dashboard is ready",
    placeholderDescription:
      "Metrics and operational snapshots will appear here later.",
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
            current: true,
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
}

describe("Admin/Dashboard/Index", () => {
  it("renders an empty dashboard in the grouped admin shell", async () => {
    const { container } = renderInertiaPage(Index, props)

    expect(
      screen.getByRole("banner", { name: props.copy.toolbarLabel }),
    ).toBeInTheDocument()
    expect(screen.getByRole("link", { name: "Dashboard" })).toHaveAttribute(
      "aria-current",
      "page",
    )
    expect(
      screen.getByRole("link", { name: "Service actions" }),
    ).toHaveAttribute("href", "/admin/service-actions")
    expect(screen.getByText("Models")).toBeVisible()
    expect(screen.getByRole("link", { name: "Users" })).toHaveAttribute(
      "href",
      "/admin/users",
    )
    expect(
      document.querySelector('[data-admin-nav-icon="dashboard"]'),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("heading", { name: props.copy.heading, level: 1 }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("heading", {
        name: props.copy.placeholderTitle,
        level: 2,
      }),
    ).toBeInTheDocument()

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
})
