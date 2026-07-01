import { Head } from "@inertiajs/react"
import { WrenchIcon } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"
import { ProductEmptyState } from "@/components/ww"

import AppShell from "../../../components/AppShell"
import type { SharedPageProps } from "../../../types/page"

export interface AdminNavigationItem {
  key: string
  label: string
  url: string
  current: boolean
}

export interface AdminServiceActionsPageProps extends SharedPageProps {
  copy: {
    title: string
    heading: string
    description: string
    toolbarLabel: string
    placeholderTitle: string
    placeholderDescription: string
  }
  navigation: {
    items: AdminNavigationItem[]
  }
  urls: {
    serviceActions: string
  }
}

export default function Index({
  copy,
  navigation,
  shell,
}: AdminServiceActionsPageProps) {
  return (
    <AppShell
      mainClassName="flex w-full flex-1 p-0"
      shell={shell}
      title={copy.title}
    >
      <Head title={copy.title} />
      <section className="flex min-h-[calc(100svh-3.25rem)] w-full bg-background">
        <aside className="hidden w-64 shrink-0 border-r bg-muted/30 p-4 md:block">
          <nav aria-label={copy.toolbarLabel} className="flex flex-col gap-2">
            {navigation.items.map((item) => (
              <Button
                asChild
                className="justify-start"
                key={item.key}
                variant={item.current ? "secondary" : "ghost"}
              >
                <a
                  aria-current={item.current ? "page" : undefined}
                  href={item.url}
                >
                  {item.label}
                </a>
              </Button>
            ))}
          </nav>
        </aside>

        <div className="flex min-w-0 flex-1 flex-col">
          <header
            aria-label={copy.toolbarLabel}
            className="flex min-h-16 items-center justify-between gap-3 border-b bg-background px-4 py-3 sm:px-6"
          >
            <div className="flex min-w-0 flex-col gap-1">
              <Badge className="w-fit" variant="secondary">
                {copy.toolbarLabel}
              </Badge>
              <h1 className="text-xl font-semibold tracking-normal">
                {copy.heading}
              </h1>
            </div>
          </header>

          <div className="flex flex-1 flex-col gap-5 p-4 sm:p-6">
            <div className="flex flex-col gap-2">
              <p className="max-w-3xl text-sm leading-6 text-muted-foreground">
                {copy.description}
              </p>
              <Separator />
            </div>

            <ProductEmptyState
              className="min-h-80 border"
              description={copy.placeholderDescription}
              icon={<WrenchIcon />}
              title={<h2>{copy.placeholderTitle}</h2>}
            />
          </div>
        </div>
      </section>
    </AppShell>
  )
}
