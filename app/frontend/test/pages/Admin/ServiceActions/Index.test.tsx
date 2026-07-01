import { screen, waitFor } from "@testing-library/react"
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
    placeholderTitle: "Service commands will live here",
    placeholderDescription: "Import controls are not available yet.",
  },
  navigation: {
    items: [
      {
        key: "service_actions",
        label: "Service actions",
        url: "/admin/service-actions",
        current: true,
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
      admin: "/admin/service-actions",
      dashboard: "/dashboard",
      explore: "/",
      signIn: "/session/new",
      signOut: "/session",
    },
  },
  urls: {
    serviceActions: "/admin/service-actions",
  },
}

describe("Admin/ServiceActions/Index", () => {
  it("renders the admin shell and non-actionable service actions placeholder", async () => {
    const { container } = renderInertiaPage(Index, props)

    expect(
      screen.getByRole("banner", { name: props.copy.toolbarLabel }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("navigation", { name: props.copy.toolbarLabel }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("link", { name: "Service actions" }),
    ).toHaveAttribute("aria-current", "page")
    expect(
      screen.getByRole("heading", { name: props.copy.heading, level: 1 }),
    ).toBeInTheDocument()
    expect(screen.getByText(props.copy.description)).toBeInTheDocument()
    expect(
      screen.getByRole("heading", {
        name: props.copy.placeholderTitle,
        level: 2,
      }),
    ).toBeInTheDocument()
    expect(
      screen.getByText(props.copy.placeholderDescription),
    ).toBeInTheDocument()
    expect(screen.queryByRole("button", { name: /start import/i })).toBeNull()

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
