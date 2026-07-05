import type { ReactNode } from "react"
import {
  LayoutDashboardIcon,
  MapPinnedIcon,
  UsersRoundIcon,
  WrenchIcon,
  type LucideIcon,
} from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"

import AppShell from "../../components/AppShell"
import type { SharedPageProps } from "../../types/page"

type AdminNavigationIcon = "dashboard" | "regions" | "users" | "wrench"

export interface AdminNavigationItem {
  icon: AdminNavigationIcon
  key: string
  label: string
  url: string
  current: boolean
}

export interface AdminNavigationSection {
  items: AdminNavigationItem[]
  key: string
  label?: string
}

interface AdminLayoutProps extends Pick<SharedPageProps, "shell"> {
  children: ReactNode
  description?: string
  heading: string
  navigation: {
    sections: AdminNavigationSection[]
  }
  title: string
  toolbarLabel: string
}

const NAVIGATION_ICONS = {
  dashboard: LayoutDashboardIcon,
  regions: MapPinnedIcon,
  users: UsersRoundIcon,
  wrench: WrenchIcon,
} satisfies Record<AdminNavigationIcon, LucideIcon>

export default function AdminLayout({
  children,
  description,
  heading,
  navigation,
  shell,
  title,
  toolbarLabel,
}: AdminLayoutProps) {
  return (
    <AppShell
      mainClassName="flex w-full flex-1 p-0"
      shell={shell}
      title={title}
    >
      <section className="flex min-h-[calc(100svh-3.25rem)] w-full bg-muted/40">
        <aside className="hidden w-72 shrink-0 border-r bg-background md:block">
          <div className="flex h-full flex-col p-2">
            <div className="flex h-12 items-center gap-2 px-2">
              <span className="flex size-8 items-center justify-center rounded-lg bg-primary text-primary-foreground">
                <LayoutDashboardIcon aria-hidden="true" />
              </span>
              <span className="text-sm font-semibold">{toolbarLabel}</span>
            </div>

            <Separator className="my-2" />

            <nav aria-label={toolbarLabel} className="flex flex-col gap-1">
              {navigation.sections.map((section, sectionIndex) => (
                <div
                  className={
                    sectionIndex > 0
                      ? "mt-6 flex flex-col gap-1"
                      : "flex flex-col gap-1"
                  }
                  key={section.key}
                >
                  {section.label ? (
                    <div className="px-2 pb-1 text-xs font-medium uppercase text-muted-foreground">
                      {section.label}
                    </div>
                  ) : null}
                  {section.items.map((item) => (
                    <NavigationLink item={item} key={item.key} />
                  ))}
                </div>
              ))}
            </nav>
          </div>
        </aside>

        <div className="flex min-w-0 flex-1 flex-col">
          <header
            aria-label={toolbarLabel}
            className="flex min-h-16 items-center justify-between gap-3 border-b bg-background px-4 py-3 sm:px-6"
          >
            <div className="flex min-w-0 flex-col gap-1">
              <Badge className="w-fit" variant="secondary">
                {toolbarLabel}
              </Badge>
              <h1 className="text-xl font-semibold tracking-normal">
                {heading}
              </h1>
              {description ? (
                <p className="max-w-3xl text-sm leading-6 text-muted-foreground">
                  {description}
                </p>
              ) : null}
            </div>
          </header>

          <div className="flex flex-1 flex-col gap-5 p-4 sm:p-6 lg:p-8">
            {children}
          </div>
        </div>
      </section>
    </AppShell>
  )
}

function NavigationLink({ item }: { item: AdminNavigationItem }) {
  const Icon = NAVIGATION_ICONS[item.icon]

  return (
    <Button
      asChild
      className="h-9 justify-start gap-2 px-2"
      variant={item.current ? "secondary" : "ghost"}
    >
      <a aria-current={item.current ? "page" : undefined} href={item.url}>
        <Icon
          aria-hidden="true"
          data-admin-nav-icon={item.icon}
          data-icon="inline-start"
        />
        <span className="truncate">{item.label}</span>
      </a>
    </Button>
  )
}
