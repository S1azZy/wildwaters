import { act, screen, waitFor } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import AppShell from "../../components/AppShell"
import type { ShellProps } from "../../types/page"
import { checkAccessibility } from "../accessibility"
import { renderInertiaPage } from "../inertia"

const labels = {
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
}

const urls = {
  dashboard: "/dashboard",
  explore: "/",
  signIn: "/session/new",
  signOut: "/session",
}

function TestPage({ shell }: { shell: ShellProps }) {
  return (
    <AppShell shell={shell} title="Sekumpul Waterfall">
      <h1>Sekumpul Waterfall</h1>
    </AppShell>
  )
}

describe("AppShell", () => {
  it("renders guest navigation as keyboard-accessible full-document links", async () => {
    const user = userEvent.setup()
    const shell: ShellProps = {
      authenticated: false,
      labels,
      urls,
    }
    const { container } = renderInertiaPage(TestPage, { shell })

    const brand = screen.getByRole("link", { name: /Wild Waters/i })
    const exploreLinks = screen.getAllByRole("link", { name: labels.explore })
    const signIn = screen.getByRole("link", { name: labels.signIn })

    expect(brand).toHaveAttribute("href", urls.explore)
    expect(exploreLinks).toHaveLength(2)
    expect(exploreLinks[0]).toHaveAttribute("href", urls.explore)
    expect(signIn).toHaveAttribute("href", urls.signIn)
    expect(screen.queryByRole("link", { name: labels.profile })).toBeNull()

    for (const link of [brand, ...exploreLinks, signIn]) {
      expect(link).toBeInstanceOf(HTMLAnchorElement)
    }

    await user.tab()
    expect(brand).toHaveFocus()
    await waitFor(() => expect(document.title).toBe("Sekumpul Waterfall"))
    expect((await checkAccessibility(container)).violations).toEqual([])
  })

  it("renders the authenticated account menu trigger instead of sign in", () => {
    const shell: ShellProps = {
      authenticated: true,
      labels,
      urls,
    }

    renderInertiaPage(TestPage, { shell })

    expect(
      screen.getByRole("button", { name: labels.accountMenu }),
    ).toHaveTextContent(labels.accountMenu)
    expect(screen.queryByRole("link", { name: labels.signIn })).toBeNull()
  })

  it("renders authenticated account actions for members", async () => {
    const user = userEvent.setup()
    const shell: ShellProps = {
      authenticated: true,
      labels,
      urls,
    }

    renderInertiaPage(TestPage, { shell })

    await user.click(screen.getByRole("button", { name: labels.accountMenu }))

    expect(
      screen.getByRole("menuitem", { name: labels.profile }),
    ).toHaveAttribute("aria-disabled", "true")
    expect(screen.queryByRole("menuitem", { name: labels.admin })).toBeNull()
    expect(
      screen.getByRole("menuitem", { name: labels.signOut }),
    ).toHaveTextContent(labels.signOut)
  })

  it("renders the admin account action only when Rails provides its URL", async () => {
    const user = userEvent.setup()
    const shell: ShellProps = {
      authenticated: true,
      labels,
      urls: {
        ...urls,
        admin: "/admin/service-actions",
      },
    }

    renderInertiaPage(TestPage, { shell })

    await user.click(screen.getByRole("button", { name: labels.accountMenu }))

    expect(
      screen.getByRole("menuitem", { name: labels.admin }),
    ).toHaveAttribute("href", "/admin/service-actions")
    expect(screen.queryByRole("menuitem", { name: labels.mainPage })).toBeNull()
  })

  it("replaces the admin account action with main page inside admin", async () => {
    const user = userEvent.setup()
    const shell: ShellProps = {
      authenticated: true,
      labels,
      urls: {
        ...urls,
        admin: "/admin/service-actions",
      },
    }

    renderInertiaPage(TestPage, { shell }, {}, "/admin/service-actions")

    await user.click(screen.getByRole("button", { name: labels.accountMenu }))

    expect(screen.queryByRole("menuitem", { name: labels.admin })).toBeNull()
    expect(
      screen.getByRole("menuitem", { name: labels.mainPage }),
    ).toHaveAttribute("href", urls.explore)
  })

  it("renders allowed flash messages in a compact overlay and dismisses them", () => {
    vi.useFakeTimers()
    const shell: ShellProps = {
      authenticated: false,
      labels,
      urls,
    }

    try {
      renderInertiaPage(
        TestPage,
        { shell },
        {
          notice: "Waterfall saved.",
          alert: "Waterfall could not be loaded.",
        },
      )

      expect(screen.getByRole("status")).toHaveTextContent("Waterfall saved.")
      expect(screen.getByRole("status")).toHaveAttribute("aria-live", "polite")
      expect(screen.getByRole("alert")).toHaveTextContent(
        "Waterfall could not be loaded.",
      )
      expect(screen.getByRole("alert")).toHaveAttribute(
        "aria-live",
        "assertive",
      )
      expect(screen.getByTestId("flash-stack")).toHaveClass("ui-flash-stack")

      act(() => {
        vi.advanceTimersByTime(5_000)
      })

      expect(screen.queryByRole("status")).toBeNull()
      expect(screen.queryByRole("alert")).toBeNull()
    } finally {
      vi.useRealTimers()
    }
  })
})
