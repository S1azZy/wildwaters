import { screen, waitFor } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it } from "vitest"

import AppShell from "../../components/AppShell"
import type { ShellProps } from "../../types/page"
import { checkAccessibility } from "../accessibility"
import { renderInertiaPage } from "../inertia"

const labels = {
  brandName: "Wild Waters",
  brandTagline: "Swim the World",
  explore: "Explore",
  profile: "Profile",
  signIn: "Log in",
}

const urls = {
  dashboard: "/dashboard",
  explore: "/",
  signIn: "/session/new",
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

  it("renders only the authenticated profile action", () => {
    const shell: ShellProps = {
      authenticated: true,
      labels,
      urls,
    }

    renderInertiaPage(TestPage, { shell })

    expect(screen.getByRole("link", { name: labels.profile })).toHaveAttribute(
      "href",
      urls.dashboard,
    )
    expect(screen.queryByRole("link", { name: labels.signIn })).toBeNull()
  })

  it("renders allowed flash messages with status and alert semantics", () => {
    const shell: ShellProps = {
      authenticated: false,
      labels,
      urls,
    }

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
    expect(screen.getByRole("alert")).toHaveAttribute("aria-live", "assertive")
  })
})
