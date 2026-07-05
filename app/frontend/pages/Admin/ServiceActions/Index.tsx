import type { FormEvent } from "react"
import { useForm } from "@inertiajs/react"
import { DatabaseZapIcon } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"

import type { SharedPageProps } from "../../../types/page"
import AdminLayout, { type AdminNavigationSection } from "../AdminLayout"

interface GeoNamesImportRun {
  failure: {
    className: string | null
    itemMessages: string[]
    message: string | null
  } | null
  finishedAt: string | null
  id: number
  initiatedBy: string
  itemCounts: Record<string, number>
  mode: string
  settings: {
    countries: string[]
    downloadAlternateNames: boolean | null
    downloadDir: string | null
    featureCodes: string[]
    languages: string[]
  }
  startedAt: string | null
  stats: Record<string, number>
  status: string
}

export interface AdminServiceActionsPageProps extends SharedPageProps {
  copy: {
    title: string
    heading: string
    description: string
    toolbarLabel: string
    importRegions: {
      button: string
      description: string
      emptyDescription: string
      emptyTitle: string
      failureTitle: string
      fields: {
        countries: string
        featureCodes: string
        finishedAt: string
        initiatedBy: string
        itemCounts: string
        languages: string
        mode: string
        startedAt: string
        status: string
      }
      latestRunTitle: string
      resultsTitle: string
      settingsTitle: string
      statusLabels: Record<string, string>
      title: string
    }
  }
  geonamesImport: {
    latestRun: GeoNamesImportRun | null
  }
  navigation: {
    sections: AdminNavigationSection[]
  }
  urls: {
    geonamesRegionImport: string
    serviceActions: string
  }
}

export default function Index({
  copy,
  geonamesImport,
  navigation,
  shell,
  urls,
}: AdminServiceActionsPageProps) {
  return (
    <AdminLayout
      description={copy.description}
      heading={copy.heading}
      navigation={navigation}
      shell={shell}
      title={copy.title}
      toolbarLabel={copy.toolbarLabel}
    >
      <Separator />

      <GeoNamesImportPanel
        copy={copy.importRegions}
        latestRun={geonamesImport.latestRun}
        url={urls.geonamesRegionImport}
      />
    </AdminLayout>
  )
}

function GeoNamesImportPanel({
  copy,
  latestRun,
  url,
}: {
  copy: AdminServiceActionsPageProps["copy"]["importRegions"]
  latestRun: GeoNamesImportRun | null
  url: string
}) {
  const { post, processing } = useForm({})

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    post(url)
  }

  return (
    <Card>
      <CardHeader className="gap-3">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
          <div className="min-w-0 space-y-1">
            <CardTitle className="text-lg">
              <h2 className="flex items-center gap-2">
                <DatabaseZapIcon aria-hidden="true" />
                {copy.title}
              </h2>
            </CardTitle>
            <CardDescription>{copy.description}</CardDescription>
          </div>

          <form action={url} method="post" onSubmit={submit}>
            <Button disabled={processing} type="submit">
              <DatabaseZapIcon aria-hidden="true" data-icon="inline-start" />
              {copy.button}
            </Button>
          </form>
        </div>
      </CardHeader>
      <CardContent>
        {latestRun ? (
          <LatestRun copy={copy} run={latestRun} />
        ) : (
          <div className="rounded-md border border-dashed p-6">
            <h3 className="text-sm font-semibold">{copy.emptyTitle}</h3>
            <p className="mt-1 text-sm leading-6 text-muted-foreground">
              {copy.emptyDescription}
            </p>
          </div>
        )}
      </CardContent>
    </Card>
  )
}

function LatestRun({
  copy,
  run,
}: {
  copy: AdminServiceActionsPageProps["copy"]["importRegions"]
  run: GeoNamesImportRun
}) {
  return (
    <div className="grid gap-5 lg:grid-cols-[1.2fr_0.8fr]">
      <section className="space-y-3">
        <div className="flex flex-wrap items-center gap-2">
          <h3 className="text-sm font-semibold">{copy.latestRunTitle}</h3>
          <Badge variant={run.status === "succeeded" ? "default" : "secondary"}>
            {statusLabel(copy.statusLabels, run.status)}
          </Badge>
        </div>

        <DescriptionList
          items={[
            [copy.fields.status, statusLabel(copy.statusLabels, run.status)],
            [copy.fields.mode, run.mode],
            [copy.fields.initiatedBy, run.initiatedBy],
            [copy.fields.startedAt, run.startedAt ?? ""],
            [copy.fields.finishedAt, run.finishedAt ?? ""],
            [copy.fields.itemCounts, joinKeyValues(run.itemCounts)],
          ]}
        />
      </section>

      <section className="space-y-3">
        <h3 className="text-sm font-semibold">{copy.settingsTitle}</h3>
        <DescriptionList
          items={[
            [copy.fields.countries, run.settings.countries.join(", ")],
            [copy.fields.languages, run.settings.languages.join(", ")],
            [copy.fields.featureCodes, run.settings.featureCodes.join(", ")],
          ]}
        />
      </section>

      <section className="space-y-2">
        <h3 className="text-sm font-semibold">{copy.resultsTitle}</h3>
        <KeyValueLines values={run.stats} />
      </section>

      {run.failure ? (
        <section className="space-y-2 rounded-md border border-destructive/30 p-4">
          <h3 className="text-sm font-semibold">{copy.failureTitle}</h3>
          {run.failure.className ? (
            <p className="text-sm text-muted-foreground">
              {run.failure.className}
            </p>
          ) : null}
          {run.failure.message ? (
            <p className="text-sm">{run.failure.message}</p>
          ) : null}
          <KeyValueLines values={run.failure.itemMessages} />
        </section>
      ) : null}
    </div>
  )
}

function DescriptionList({ items }: { items: [string, string][] }) {
  return (
    <dl className="grid gap-2 text-sm sm:grid-cols-2">
      {items
        .filter(([, value]) => value.length > 0)
        .map(([label, value]) => (
          <div className="min-w-0" key={label}>
            <dt className="text-xs font-medium uppercase text-muted-foreground">
              {label}
            </dt>
            <dd className="break-words">{value}</dd>
          </div>
        ))}
    </dl>
  )
}

function KeyValueLines({
  values,
}: {
  values: Record<string, number> | string[]
}) {
  const lines = Array.isArray(values)
    ? values
    : Object.entries(values).map(([key, value]) => `${key}: ${value}`)

  return (
    <div className="flex flex-col gap-1 text-sm">
      {lines.map((line) => (
        <span key={line}>{line}</span>
      ))}
    </div>
  )
}

function joinKeyValues(values: Record<string, number>) {
  return Object.entries(values)
    .map(([key, value]) => `${key}: ${value}`)
    .join(", ")
}

function statusLabel(labels: Record<string, string>, status: string) {
  return (
    labels[
      status.replace(/_([a-z])/g, (_, letter: string) => letter.toUpperCase())
    ] ?? status
  )
}
