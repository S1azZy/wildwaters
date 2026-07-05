import { SearchIcon, MapPinnedIcon } from "lucide-react"

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

export interface AdminRegionRow {
  id: string
  name: string
  slug: string
  regionKind: string
  status: string
  countryCode: string | null
  parentPath: string | null
  depth: number
  childrenCount: number
  createdAt: string
}

export interface AdminRegionsIndexPageProps extends SharedPageProps {
  copy: {
    title: string
    heading: string
    description: string
    toolbarLabel: string
    searchLabel: string
    searchPlaceholder: string
    searchSubmit: string
    emptyCountryCode: string
    emptyParentPath: string
    emptyTitle: string
    emptyDescription: string
    tableCaption: string
    levelLabel: string
    childrenCount: {
      zero: string
      one: string
      other: string
    }
    columns: {
      region: string
      kind: string
      status: string
      countryCode: string
      parentPath: string
      children: string
      createdAt: string
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
  regions: AdminRegionRow[]
}

export default function Index({
  copy,
  navigation,
  pagination,
  query,
  shell,
  urls,
  regions,
}: AdminRegionsIndexPageProps) {
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
        <label className="sr-only" htmlFor="admin-regions-search">
          {copy.searchLabel}
        </label>
        <Input
          defaultValue={query.q}
          id="admin-regions-search"
          name="q"
          placeholder={copy.searchPlaceholder}
          type="search"
        />
        <Button className="shrink-0" type="submit">
          <SearchIcon data-icon="inline-start" />
          {copy.searchSubmit}
        </Button>
      </form>

      {regions.length > 0 ? (
        <div className="overflow-hidden rounded-lg border bg-background">
          <Table>
            <TableCaption>{copy.tableCaption}</TableCaption>
            <TableHeader>
              <TableRow>
                <TableHead>{copy.columns.region}</TableHead>
                <TableHead>{copy.columns.kind}</TableHead>
                <TableHead>{copy.columns.status}</TableHead>
                <TableHead>{copy.columns.countryCode}</TableHead>
                <TableHead>{copy.columns.parentPath}</TableHead>
                <TableHead>{copy.columns.children}</TableHead>
                <TableHead>{copy.columns.createdAt}</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {regions.map((region) => (
                <TableRow key={region.id}>
                  <TableCell className="min-w-60">
                    <div
                      aria-label={`${copy.levelLabel} ${region.depth}`}
                      className="flex min-w-0 flex-col gap-1"
                      style={{ paddingLeft: `${region.depth}rem` }}
                    >
                      <span className="font-medium">{region.name}</span>
                      <span className="text-xs text-muted-foreground">
                        {region.slug}
                      </span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <Badge variant="outline">{region.regionKind}</Badge>
                  </TableCell>
                  <TableCell>
                    <Badge
                      variant={
                        region.status === "archived"
                          ? "destructive"
                          : "secondary"
                      }
                    >
                      {region.status}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    {region.countryCode ?? copy.emptyCountryCode}
                  </TableCell>
                  <TableCell>
                    {region.parentPath ?? copy.emptyParentPath}
                  </TableCell>
                  <TableCell>{childrenCountLabel(copy, region)}</TableCell>
                  <TableCell>{region.createdAt}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      ) : (
        <ProductEmptyState
          className="min-h-80 border"
          description={copy.emptyDescription}
          icon={<MapPinnedIcon />}
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

function childrenCountLabel(
  copy: AdminRegionsIndexPageProps["copy"],
  region: AdminRegionRow,
) {
  if (region.childrenCount === 0) {
    return copy.childrenCount.zero
  }

  if (region.childrenCount === 1) {
    return copy.childrenCount.one
  }

  return copy.childrenCount.other.replace(
    "%{count}",
    region.childrenCount.toString(),
  )
}
