import { screen, waitFor } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import Edit, {
  type PasswordResetEditPageProps,
} from "../../../pages/PasswordResets/Edit"
import { checkAccessibility } from "../../accessibility"
import { renderInertiaPage } from "../../inertia"
import { guestShell, recoveryAuth } from "../authPageProps"

const props: PasswordResetEditPageProps = {
  auth: {
    ...recoveryAuth,
    title: "Choose a new password",
  },
  copy: {
    cardHeading: "Lock in the next route",
    cardSupporting: "Choose a fresh password.",
    submit: "Update password",
  },
  fields: {
    password: { label: "Password", placeholder: "password" },
    passwordConfirmation: {
      label: "Confirm password",
      placeholder: "password",
    },
  },
  formError: null,
  shell: guestShell,
  urls: {
    submit: "/password-reset/reset-token",
  },
}

describe("PasswordResets/Edit", () => {
  it("renders the migrated reset edit form accessibly", async () => {
    const { container } = renderInertiaPage(Edit, props)

    expect(
      screen.getByRole("heading", { name: props.copy.cardHeading }),
    ).toBeInTheDocument()
    expect(screen.getByLabelText(props.fields.password.label)).toHaveAttribute(
      "autocomplete",
      "new-password",
    )
    expect(
      screen.getByLabelText(props.fields.passwordConfirmation.label),
    ).toHaveAttribute("autocomplete", "new-password")
    expect(
      screen.getByRole("button", { name: props.copy.submit }),
    ).toBeInTheDocument()
    expect(
      container.querySelector("[data-auth-page='password-reset-edit']"),
    ).toBeVisible()
    await waitFor(() => expect(document.title).toBe(props.auth.title))
    expect((await checkAccessibility(container)).violations).toEqual([])
  })
})
