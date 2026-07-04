import { screen, waitFor, within } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import Index, {
  type AdminUsersIndexPageProps,
} from "../../../../pages/Admin/Users/Index"
import { checkAccessibility } from "../../../accessibility"
import { renderInertiaPage } from "../../../inertia"

const props: AdminUsersIndexPageProps = {
  copy: {
    title: "Users",
    heading: "Users",
    description: "Search and manage application users.",
    toolbarLabel: "Admin workspace",
    searchLabel: "Search users",
    searchPlaceholder: "Email or display name",
    searchSubmit: "Search",
    emptyDisplayName: "Not set",
    emptyTitle: "No users found",
    emptyDescription: "Try another search term.",
    tableCaption: "Application users",
    columns: {
      displayName: "Display name",
      email: "Email",
      role: "Role",
      status: "Status",
      locale: "Locale",
      createdAt: "Created",
      actions: "Actions",
    },
    actions: {
      edit: "Edit",
      suspend: "Suspend",
      reactivate: "Reactivate",
    },
    pagination: {
      label: "Users pages",
      previous: "Previous",
      next: "Next",
      summary: "Showing 1-2 of 27 users",
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
  pagination: {
    currentPage: 1,
    nextUrl: "/admin/users?page=2",
    previousUrl: null,
    totalCount: 27,
    totalPages: 2,
  },
  query: {
    q: "river",
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
  },
  users: [
    {
      id: "user-1",
      displayName: "River Guide",
      email: "guide@example.com",
      role: "member",
      status: "active",
      locale: "en",
      createdAt: "Jul 4, 2026",
      editUrl: "/admin/users/user-1/edit",
      statusUrl: "/admin/users/user-1/status",
      nextStatus: "suspended",
    },
    {
      id: "user-2",
      displayName: null,
      email: "admin@example.com",
      role: "admin",
      status: "suspended",
      locale: "ru",
      createdAt: "Jul 3, 2026",
      editUrl: "/admin/users/user-2/edit",
      statusUrl: "/admin/users/user-2/status",
      nextStatus: "active",
    },
  ],
}

describe("Admin/Users/Index", () => {
  it("renders the searchable users table with pagination and row actions", async () => {
    const { container } = renderInertiaPage(Index, props)

    expect(
      screen.getByRole("navigation", { name: props.copy.toolbarLabel }),
    ).toBeInTheDocument()
    expect(screen.getByRole("link", { name: "Users" })).toHaveAttribute(
      "aria-current",
      "page",
    )
    expect(screen.getByRole("link", { name: "Dashboard" })).toHaveAttribute(
      "href",
      "/admin",
    )
    expect(screen.getByText("Models")).toBeVisible()
    expect(
      document.querySelector('[data-admin-nav-icon="users"]'),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("heading", { name: props.copy.heading, level: 1 }),
    ).toBeInTheDocument()

    expect(screen.getByLabelText(props.copy.searchLabel)).toHaveValue("river")
    expect(
      screen.getByRole("button", { name: props.copy.searchSubmit }),
    ).toBeVisible()

    const table = screen.getByRole("table", { name: props.copy.tableCaption })
    expect(within(table).getByText("River Guide")).toBeVisible()
    expect(within(table).getByText("guide@example.com")).toBeVisible()
    expect(within(table).getByText("admin@example.com")).toBeVisible()
    expect(
      within(table).getByRole("link", { name: "Edit River Guide" }),
    ).toHaveAttribute("href", "/admin/users/user-1/edit")
    expect(
      within(table).getByRole("button", { name: "Suspend River Guide" }),
    ).toBeVisible()
    expect(
      within(table).getByRole("button", {
        name: "Reactivate admin@example.com",
      }),
    ).toBeVisible()

    expect(
      screen.getByRole("navigation", { name: props.copy.pagination.label }),
    ).toBeInTheDocument()
    expect(screen.getByText(props.copy.pagination.summary)).toBeVisible()
    expect(
      screen.getByRole("link", { name: props.copy.pagination.next }),
    ).toHaveAttribute("href", "/admin/users?page=2")
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

  it("renders an empty state for filtered results without users", () => {
    renderInertiaPage(Index, { ...props, users: [] })

    expect(
      screen.getByRole("heading", {
        name: props.copy.emptyTitle,
        level: 2,
      }),
    ).toBeVisible()
    expect(screen.getByText(props.copy.emptyDescription)).toBeVisible()
  })
})
