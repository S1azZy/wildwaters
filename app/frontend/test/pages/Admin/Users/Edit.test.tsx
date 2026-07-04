import { screen, waitFor } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import Edit, {
  type AdminUsersEditPageProps,
} from "../../../../pages/Admin/Users/Edit"
import { checkAccessibility } from "../../../accessibility"
import { renderInertiaPage } from "../../../inertia"

const props: AdminUsersEditPageProps = {
  copy: {
    title: "Edit user",
    heading: "Edit user",
    description: "Change only the fields admins are allowed to manage.",
    toolbarLabel: "Admin workspace",
    back: "Back to users",
    detailsHeading: "Account details",
    formHeading: "Editable fields",
    submit: "Save changes",
    fields: {
      displayName: {
        label: "Display name",
        placeholder: "Public name",
      },
      role: {
        label: "Role",
      },
      status: {
        label: "Status",
      },
    },
    details: {
      email: "Email",
      locale: "Locale",
      createdAt: "Created",
      updatedAt: "Updated",
    },
  },
  navigation: {
    sections: [
      {
        key: "primary",
        items: [
          {
            key: "dashboard",
            icon: "dashboard",
            label: "Dashboard",
            url: "/admin",
            current: false,
          },
          {
            key: "service_actions",
            icon: "wrench",
            label: "Service actions",
            url: "/admin/service-actions",
            current: false,
          },
        ],
      },
      {
        key: "models",
        label: "Models",
        items: [
          {
            key: "users",
            icon: "users",
            label: "Users",
            url: "/admin/users",
            current: true,
          },
        ],
      },
    ],
  },
  options: {
    roles: [
      { label: "Member", value: "member" },
      { label: "Admin", value: "admin" },
    ],
    statuses: [
      { label: "Active", value: "active" },
      { label: "Suspended", value: "suspended" },
    ],
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
      admin: "/admin",
      dashboard: "/dashboard",
      explore: "/",
      signIn: "/session/new",
      signOut: "/session",
    },
  },
  urls: {
    index: "/admin/users",
    update: "/admin/users/user-1",
  },
  user: {
    id: "user-1",
    displayName: "River Guide",
    email: "guide@example.com",
    locale: "en",
    role: "member",
    status: "active",
    createdAt: "Jul 4, 2026",
    updatedAt: "Jul 5, 2026",
  },
}

describe("Admin/Users/Edit", () => {
  it("renders read-only account details and only allowed editable fields", async () => {
    const { container } = renderInertiaPage(Edit, props)

    expect(
      screen.getByRole("heading", { name: props.copy.heading, level: 1 }),
    ).toBeInTheDocument()
    expect(screen.getByRole("link", { name: "Users" })).toHaveAttribute(
      "aria-current",
      "page",
    )
    expect(screen.getByText("Models")).toBeVisible()
    expect(screen.getByRole("link", { name: props.copy.back })).toHaveAttribute(
      "href",
      "/admin/users",
    )

    expect(screen.getByText("guide@example.com")).toBeVisible()
    expect(screen.getByText("Jul 4, 2026")).toBeVisible()
    expect(screen.getByText("Jul 5, 2026")).toBeVisible()
    expect(
      screen.getByLabelText(props.copy.fields.displayName.label),
    ).toHaveValue("River Guide")
    expect(
      screen.getByRole("combobox", { name: props.copy.fields.role.label }),
    ).toBeVisible()
    expect(
      screen.getByRole("combobox", { name: props.copy.fields.status.label }),
    ).toBeVisible()
    expect(
      screen.getByRole("button", { name: props.copy.submit }),
    ).toBeVisible()

    expect(screen.queryByLabelText(/email/i)).toBeNull()
    expect(screen.queryByLabelText(/locale/i)).toBeNull()
    expect(screen.queryByLabelText(/password/i)).toBeNull()
    expect(screen.queryByText(/password/i)).toBeNull()

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
