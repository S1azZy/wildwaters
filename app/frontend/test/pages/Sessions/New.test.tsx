import { screen, waitFor } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import New, { type SessionNewPageProps } from "../../../pages/Sessions/New"
import { checkAccessibility } from "../../accessibility"
import { renderInertiaPage } from "../../inertia"
import { guestShell, sessionAuth } from "../authPageProps"

const props: SessionNewPageProps = {
  auth: sessionAuth,
  copy: {
    cardHeading: "Return to your saved map",
    cardSupporting: "Pick up your planning flow.",
    forgotPassword: "Forgot your password?",
    submit: "Sign in",
  },
  fields: {
    email: { label: "Email", placeholder: "name@example.com" },
    password: { label: "Password", placeholder: "password" },
  },
  formError: null,
  shell: guestShell,
  urls: {
    forgotPassword: "/password-reset/new",
    submit: "/session",
  },
  values: {
    email: null,
  },
}

describe("Sessions/New", () => {
  it("renders the migrated sign-in form accessibly", async () => {
    const { container } = renderInertiaPage(New, props)

    expect(
      screen.getByRole("heading", { name: props.copy.cardHeading }),
    ).toBeInTheDocument()
    expect(screen.getByLabelText(props.fields.email.label)).toHaveAttribute(
      "autocomplete",
      "email",
    )
    expect(screen.getByLabelText(props.fields.password.label)).toHaveAttribute(
      "type",
      "password",
    )
    expect(
      screen.getByRole("button", { name: props.copy.submit }),
    ).toHaveAttribute("type", "submit")
    expect(
      screen.getByRole("link", { name: props.copy.forgotPassword }),
    ).toHaveAttribute("href", props.urls.forgotPassword)
    expect(container.querySelector("[data-auth-page='session']")).toBeVisible()
    await waitFor(() => expect(document.title).toBe(props.auth.title))
    expect((await checkAccessibility(container)).violations).toEqual([])
  })

  it("renders a safe generic form error without password values", () => {
    renderInertiaPage(New, {
      ...props,
      formError: "Invalid email or password.",
      values: { email: "user@example.com" },
    })

    expect(screen.getByRole("alert")).toHaveTextContent(
      "Invalid email or password.",
    )
    expect(screen.queryByDisplayValue("wrong-password")).toBeNull()
  })
})
