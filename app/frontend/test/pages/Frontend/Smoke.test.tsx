import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it } from "vitest"

import { checkAccessibility } from "../../accessibility"
import Smoke, { type SmokePageProps } from "../../../pages/Frontend/Smoke"

const props: SmokePageProps = {
  copy: {
    action: "Return to waterfalls",
    description: "The new frontend runtime is connected to Rails.",
    eyebrow: "Frontend foundation",
    interaction: "React state is working.",
    title: "Inertia is running",
  },
  csrfToken: "test-csrf-token",
  urls: {
    home: "/",
  },
}

describe("Frontend/Smoke", () => {
  it("renders typed copy and an accessible interaction using shared styles", async () => {
    const user = userEvent.setup()
    const { container } = render(<Smoke {...props} />)

    expect(
      screen.getByRole("heading", { name: props.copy.title }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("link", { name: props.copy.action }),
    ).toHaveAttribute("href", props.urls.home)
    expect(container.firstElementChild).toHaveClass("site-shell")

    const interactionButton = screen.getByRole("button", {
      name: props.copy.interaction,
    })

    await user.tab()
    expect(interactionButton).toHaveFocus()
    await user.keyboard("{Enter}")

    expect(screen.getByRole("status")).toHaveTextContent(props.copy.interaction)
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
