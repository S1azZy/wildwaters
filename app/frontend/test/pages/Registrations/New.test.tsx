import { screen, waitFor } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import New, {
  type RegistrationNewPageProps,
} from "../../../pages/Registrations/New"
import { checkAccessibility } from "../../accessibility"
import { renderInertiaPage } from "../../inertia"
import { guestShell, registrationAuth } from "../authPageProps"

const props: RegistrationNewPageProps = {
  auth: registrationAuth,
  copy: {
    cardHeading: "Shape a calm starting point",
    cardSupporting: "Keep your saved waterfalls in one place.",
    localeHint: "Choose the language you want first.",
    submit: "Create account",
  },
  fields: {
    email: { label: "Email", placeholder: "name@example.com" },
    locale: { label: "Language" },
    password: { label: "Password", placeholder: "password" },
    passwordConfirmation: {
      label: "Confirm password",
      placeholder: "password",
    },
  },
  formError: null,
  localeOptions: [
    { label: "English", value: "en" },
    { label: "Russian", value: "ru" },
  ],
  shell: guestShell,
  urls: {
    submit: "/registration",
  },
  values: {
    email: null,
    locale: "en",
  },
}

describe("Registrations/New", () => {
  it("renders the migrated registration form accessibly", async () => {
    const { container } = renderInertiaPage(New, props)

    expect(
      screen.getByRole("heading", { name: props.copy.cardHeading }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("combobox", { name: /Language/ }),
    ).toHaveDisplayValue("English")
    expect(
      screen.getByRole("button", { name: props.copy.submit }),
    ).toBeInTheDocument()
    expect(screen.getByText(props.copy.localeHint)).toBeInTheDocument()
    expect(
      container.querySelector("[data-auth-page='registration']"),
    ).toBeVisible()
    await waitFor(() => expect(document.title).toBe(props.auth.title))
    expect((await checkAccessibility(container)).violations).toEqual([])
  })
})
