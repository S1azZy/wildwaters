import { screen, waitFor } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import New, {
  type PasswordResetNewPageProps,
} from "../../../pages/PasswordResets/New"
import { checkAccessibility } from "../../accessibility"
import { renderInertiaPage } from "../../inertia"
import { guestShell, recoveryAuth } from "../authPageProps"

const props: PasswordResetNewPageProps = {
  auth: recoveryAuth,
  copy: {
    cardHeading: "Recover your route log",
    cardSupporting: "We'll send a one-time reset link.",
    submit: "Send reset link",
  },
  fields: {
    email: { label: "Email", placeholder: "name@example.com" },
  },
  shell: guestShell,
  urls: {
    submit: "/password-reset",
  },
  values: {
    email: null,
  },
}

describe("PasswordResets/New", () => {
  it("renders the migrated reset request form accessibly", async () => {
    const { container } = renderInertiaPage(New, props)

    expect(
      screen.getByRole("heading", { name: props.copy.cardHeading }),
    ).toBeInTheDocument()
    expect(screen.getByLabelText(props.fields.email.label)).toHaveAttribute(
      "autocomplete",
      "email",
    )
    expect(
      screen.getByRole("button", { name: props.copy.submit }),
    ).toBeInTheDocument()
    expect(
      container.querySelector("[data-auth-page='password-reset-new']"),
    ).toBeVisible()
    await waitFor(() => expect(document.title).toBe(props.auth.title))
    expect((await checkAccessibility(container)).violations).toEqual([])
  })
})
