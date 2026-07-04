import { Link } from "@inertiajs/react"
import { SearchIcon, UserRoundIcon } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import {
  Pagination,
  PaginationContent,
  PaginationItem,
  PaginationLink,
  PaginationNext,
  PaginationPrevious,
} from "@/components/ui/pagination"
import {
  Table,
  TableBody,
  TableCaption,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { ProductEmptyState } from "@/components/ww"

import type { SharedPageProps } from "../../../types/page"
import AdminLayout, { type AdminNavigationSection } from "../AdminLayout"

export interface AdminUserRow {
  id: string
  displayName: string | null
  email: string
  role: string
  status: string
  locale: string
  createdAt: string
  editUrl: string
  statusUrl: string
  nextStatus: "active" | "suspended"
}

export interface AdminUsersIndexPageProps extends SharedPageProps {
  copy: {
    title: string
    heading: string
    description: string
    toolbarLabel: string
    searchLabel: string
    searchPlaceholder: string
    searchSubmit: string
    emptyDisplayName: string
    emptyTitle: string
    emptyDescription: string
    tableCaption: string
    columns: {
      displayName: string
      email: string
      role: string
      status: string
      locale: string
      createdAt: string
      actions: string
    }
    actions: {
      edit: string
      suspend: string
      reactivate: string
    }
    pagination: {
      label: string
      previous: string
      next: string
      summary: string
    }
  }
  navigation: {
    sections: AdminNavigationSection[]
  }
  pagination: {
    currentPage: number
    nextUrl: string | null
    previousUrl: string | null
    totalCount: number
    totalPages: number
  }
  query: {
    q: string
  }
  urls: {
    index: string
  }
  users: AdminUserRow[]
}

export default function Index({
  copy,
  navigation,
  pagination,
  query,
  shell,
  urls,
  users,
}: AdminUsersIndexPageProps) {
  return (
    <AdminLayout
      description={copy.description}
      heading={copy.heading}
      navigation={navigation}
      shell={shell}
      title={copy.title}
      toolbarLabel={copy.toolbarLabel}
    >
      <form
        action={urls.index}
        className="flex max-w-2xl flex-col gap-2 sm:flex-row"
        method="get"
      >
        <label className="sr-only" htmlFor="admin-users-search">
          {copy.searchLabel}
        </label>
        <Input
          defaultValue={query.q}
          id="admin-users-search"
          name="q"
          placeholder={copy.searchPlaceholder}
          type="search"
        />
        <Button className="shrink-0" type="submit">
          <SearchIcon data-icon="inline-start" />
          {copy.searchSubmit}
        </Button>
      </form>

      {users.length > 0 ? (
        <div className="overflow-hidden rounded-lg border bg-background">
          <Table>
            <TableCaption>{copy.tableCaption}</TableCaption>
            <TableHeader>
              <TableRow>
                <TableHead>{copy.columns.displayName}</TableHead>
                <TableHead>{copy.columns.email}</TableHead>
                <TableHead>{copy.columns.role}</TableHead>
                <TableHead>{copy.columns.status}</TableHead>
                <TableHead>{copy.columns.locale}</TableHead>
                <TableHead>{copy.columns.createdAt}</TableHead>
                <TableHead className="text-right">
                  {copy.columns.actions}
                </TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {users.map((user) => (
                <TableRow key={user.id}>
                  <TableCell className="font-medium">
                    {user.displayName ?? copy.emptyDisplayName}
                  </TableCell>
                  <TableCell>{user.email}</TableCell>
                  <TableCell>
                    <Badge variant="outline">{user.role}</Badge>
                  </TableCell>
                  <TableCell>
                    <Badge
                      variant={
                        user.status === "suspended"
                          ? "destructive"
                          : "secondary"
                      }
                    >
                      {user.status}
                    </Badge>
                  </TableCell>
                  <TableCell>{user.locale}</TableCell>
                  <TableCell>{user.createdAt}</TableCell>
                  <TableCell>
                    <div className="flex justify-end gap-2">
                      <Button asChild size="sm" variant="outline">
                        <a
                          aria-label={`${copy.actions.edit} ${userLabel(user)}`}
                          href={user.editUrl}
                        >
                          {copy.actions.edit}
                        </a>
                      </Button>
                      <Button asChild size="sm" variant="secondary">
                        <Link
                          aria-label={`${statusActionLabel(copy, user)} ${userLabel(user)}`}
                          as="button"
                          data={{ status: user.nextStatus }}
                          href={user.statusUrl}
                          method="patch"
                          type="button"
                        >
                          {statusActionLabel(copy, user)}
                        </Link>
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      ) : (
        <ProductEmptyState
          className="min-h-80 border"
          description={copy.emptyDescription}
          icon={<UserRoundIcon />}
          title={<h2>{copy.emptyTitle}</h2>}
        />
      )}

      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <p className="text-sm text-muted-foreground">
          {copy.pagination.summary}
        </p>
        <Pagination aria-label={copy.pagination.label} className="sm:w-auto">
          <PaginationContent>
            {pagination.previousUrl ? (
              <PaginationItem>
                <PaginationPrevious
                  aria-label={copy.pagination.previous}
                  href={pagination.previousUrl}
                  text={copy.pagination.previous}
                />
              </PaginationItem>
            ) : null}
            <PaginationItem>
              <PaginationLink href={urls.index} isActive>
                {pagination.currentPage}
              </PaginationLink>
            </PaginationItem>
            {pagination.nextUrl ? (
              <PaginationItem>
                <PaginationNext
                  aria-label={copy.pagination.next}
                  href={pagination.nextUrl}
                  text={copy.pagination.next}
                />
              </PaginationItem>
            ) : null}
          </PaginationContent>
        </Pagination>
      </div>
    </AdminLayout>
  )
}

function userLabel(user: AdminUserRow) {
  return user.displayName ?? user.email
}

function statusActionLabel(
  copy: AdminUsersIndexPageProps["copy"],
  user: AdminUserRow,
) {
  return user.nextStatus === "suspended"
    ? copy.actions.suspend
    : copy.actions.reactivate
}
