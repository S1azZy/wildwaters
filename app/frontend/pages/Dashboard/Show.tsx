import { Link } from "@inertiajs/react"

import AppShell from "../../components/AppShell"
import type { SharedPageProps } from "../../types/page"

export interface DashboardShowPageProps extends SharedPageProps {
  copy: {
    title: string
    heading: string
    signedInAs: string
    signOut: string
  }
  urls: {
    signOut: string
  }
}

export default function Show({ copy, shell, urls }: DashboardShowPageProps) {
  return (
    <AppShell shell={shell} title={copy.title}>
      <div className="mx-auto w-full max-w-2xl" data-dashboard-page>
        <div className="flex items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-semibold">{copy.heading}</h1>
            <p className="mt-2 text-sm text-slate-600">{copy.signedInAs}</p>
          </div>

          <Link
            as="button"
            className="rounded border px-4 py-2 text-sm font-medium"
            href={urls.signOut}
            method="delete"
            type="button"
          >
            {copy.signOut}
          </Link>
        </div>
      </div>
    </AppShell>
  )
}
