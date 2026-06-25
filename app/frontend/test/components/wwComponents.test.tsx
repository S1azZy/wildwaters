import { render, screen } from "@testing-library/react"
import { SearchIcon } from "lucide-react"
import { describe, expect, it, vi } from "vitest"

import { TooltipProvider } from "../../components/ui/tooltip"
import {
  FeedbackMessage,
  IconControlButton,
  PageHeader,
  ProductEmptyState,
  SubmitButton,
  TextField,
} from "../../components/ww"
import { checkAccessibility } from "../accessibility"

describe("Wild Waters UI wrappers", () => {
  it("renders a pending submit button with disabled and busy states", () => {
    render(
      <SubmitButton isPending pendingLabel="Saving">
        Save
      </SubmitButton>,
    )

    const button = screen.getByRole("button", { name: /saving/i })

    expect(button).toBeDisabled()
    expect(button).toHaveAttribute("aria-busy", "true")
    expect(screen.getByRole("status", { name: "Loading" })).toBeVisible()
  })

  it("renders text fields with labels, descriptions, and invalid state", () => {
    const onChange = vi.fn()

    render(
      <TextField
        description="Use your account email."
        error="Email is required."
        id="email"
        label="Email"
        name="email"
        onChange={onChange}
        value=""
      />,
    )

    const input = screen.getByLabelText("Email")

    expect(input).toHaveAccessibleDescription(
      "Use your account email. Email is required.",
    )
    expect(input).toHaveAttribute("aria-invalid", "true")
    expect(screen.getByRole("alert")).toHaveTextContent("Email is required.")
  })

  it("renders feedback with status and alert live-region semantics", async () => {
    const { container, rerender } = render(
      <FeedbackMessage message="Waterfall saved." tone="notice" />,
    )

    expect(screen.getByRole("status")).toHaveTextContent("Waterfall saved.")
    expect(screen.getByRole("status")).toHaveAttribute("aria-live", "polite")

    rerender(
      <FeedbackMessage message="Waterfall could not be saved." tone="alert" />,
    )

    expect(screen.getByRole("alert")).toHaveTextContent(
      "Waterfall could not be saved.",
    )
    expect(screen.getByRole("alert")).toHaveAttribute("aria-live", "assertive")
    expect((await checkAccessibility(container)).violations).toEqual([])
  })

  it("renders icon controls with an accessible label", async () => {
    const { container } = render(
      <TooltipProvider>
        <IconControlButton label="Search map" tooltip="Search map">
          <SearchIcon aria-hidden="true" />
        </IconControlButton>
      </TooltipProvider>,
    )

    expect(screen.getByRole("button", { name: "Search map" })).toBeVisible()
    expect((await checkAccessibility(container)).violations).toEqual([])
  })

  it("renders page and empty-state surfaces with stable headings", () => {
    render(
      <>
        <PageHeader
          description="Plan a route before heading outside."
          eyebrow="Explore"
          title="Waterfalls nearby"
        />
        <ProductEmptyState
          description="Try changing the filters."
          title="No waterfalls found"
        />
      </>,
    )

    expect(
      screen.getByRole("heading", { name: "Waterfalls nearby", level: 1 }),
    ).toBeVisible()
    expect(screen.getByText("Explore")).toBeVisible()
    expect(screen.getByText("No waterfalls found")).toBeVisible()
  })
})
