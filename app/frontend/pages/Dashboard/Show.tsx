import { Link } from "@inertiajs/react"

import { Button } from "@/components/ui/button"

import AppShell from "../../components/AppShell"
import { PageHeader, ProductCard } from "../../components/ww"
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
        <ProductCard>
          <PageHeader
            actions={
              <Button asChild variant="outline">
                <Link
                  as="button"
                  href={urls.signOut}
                  method="delete"
                  type="button"
                >
                  {copy.signOut}
                </Link>
              </Button>
            }
            description={copy.signedInAs}
            title={copy.heading}
          />
        </ProductCard>
      </div>
    </AppShell>
  )
}
