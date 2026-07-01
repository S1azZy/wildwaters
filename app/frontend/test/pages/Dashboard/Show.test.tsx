import { screen, waitFor } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import Show, {
  type DashboardShowPageProps,
} from "../../../pages/Dashboard/Show"
import { checkAccessibility } from "../../accessibility"
import { renderInertiaPage } from "../../inertia"

const props: DashboardShowPageProps = {
  copy: {
    title: "Dashboard",
    heading: "Dashboard",
    signedInAs: "Signed in as user@example.com",
    signOut: "Sign out",
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
      dashboard: "/dashboard",
      explore: "/",
      signIn: "/session/new",
      signOut: "/session",
    },
  },
  urls: {
    signOut: "/session",
  },
}

describe("Dashboard/Show", () => {
  it("renders the protected placeholder contract and accessible sign-out action", async () => {
    const { container } = renderInertiaPage(Show, props)

    expect(
      screen.getByRole("heading", { name: props.copy.heading }),
    ).toBeInTheDocument()
    expect(screen.getByText(props.copy.signedInAs)).toBeInTheDocument()

    const signOut = screen.getByRole("button", { name: props.copy.signOut })
    expect(signOut).toHaveAttribute("type", "button")

    expect(
      screen.getByRole("button", { name: props.shell.labels.accountMenu }),
    ).toBeInTheDocument()
    expect(
      screen.queryByRole("link", { name: props.shell.labels.signIn }),
    ).toBeNull()

    expect(container.querySelector("[data-dashboard-page]")).toBeVisible()
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
