import { LayoutDashboardIcon } from "lucide-react"

import { ProductEmptyState } from "@/components/ww"

import type { SharedPageProps } from "../../../types/page"
import AdminLayout, { type AdminNavigationSection } from "../AdminLayout"

export interface AdminDashboardPageProps extends SharedPageProps {
  copy: {
    title: string
    heading: string
    description: string
    toolbarLabel: string
    placeholderTitle: string
    placeholderDescription: string
  }
  navigation: {
    sections: AdminNavigationSection[]
  }
}

export default function Index({
  copy,
  navigation,
  shell,
}: AdminDashboardPageProps) {
  return (
    <AdminLayout
      description={copy.description}
      heading={copy.heading}
      navigation={navigation}
      shell={shell}
      title={copy.title}
      toolbarLabel={copy.toolbarLabel}
    >
      <div className="grid auto-rows-min gap-4 md:grid-cols-3">
        <div className="aspect-video rounded-lg border bg-muted/50" />
        <div className="aspect-video rounded-lg border bg-muted/50" />
        <div className="aspect-video rounded-lg border bg-muted/50" />
      </div>

      <ProductEmptyState
        className="min-h-96 border bg-background"
        description={copy.placeholderDescription}
        icon={<LayoutDashboardIcon />}
        title={<h2>{copy.placeholderTitle}</h2>}
      />
    </AdminLayout>
  )
}
