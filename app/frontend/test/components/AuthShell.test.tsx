import { screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import AuthShell from "../../components/AuthShell"
import { renderInertiaPage } from "../inertia"
import { guestShell, sessionAuth } from "../pages/authPageProps"

function TestPage() {
  return (
    <AuthShell auth={sessionAuth}>
      <form aria-label="Sign in form">
        <button type="submit">Sign in</button>
      </form>
    </AuthShell>
  )
}

describe("AuthShell", () => {
  it("renders the preserved auth card structure and alternate action", () => {
    const { container } = renderInertiaPage(TestPage, { shell: guestShell })

    expect(screen.getByText(sessionAuth.eyebrow)).toBeInTheDocument()
    expect(
      screen.getByRole("heading", { name: sessionAuth.title, level: 1 }),
    ).toBeInTheDocument()
    expect(screen.getByText(sessionAuth.panelLabel)).toBeInTheDocument()
    expect(
      screen.getByRole("link", { name: sessionAuth.alternateLabel }),
    ).toHaveAttribute("href", sessionAuth.alternateUrl)
    expect(container.querySelector("[data-ui='auth-shell']")).toHaveClass(
      "auth-shell",
      "auth-shell--session",
    )
    expect(screen.getByRole("form", { name: "Sign in form" })).toBeVisible()
  })
})
