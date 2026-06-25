import { Head, usePage } from "@inertiajs/react"
import type { ReactNode } from "react"

import { TooltipProvider } from "@/components/ui/tooltip"

import type { ShellProps } from "../types/page"
import Flash from "./Flash"
import SiteHeader from "./SiteHeader"

interface AppShellProps {
  children: ReactNode
  mainClassName?: string
  pageClassName?: string
  shell: ShellProps
  title: string
}

const defaultMainClassName =
  "mx-auto w-full max-w-[112rem] flex-1 px-4 py-6 sm:px-6 lg:px-8"

export default function AppShell({
  children,
  mainClassName = defaultMainClassName,
  pageClassName,
  shell,
  title,
}: AppShellProps) {
  const { flash } = usePage()

  const content = (
    <div className="site-shell">
      <SiteHeader {...shell} />
      <main className={mainClassName}>
        <Flash {...flash} />
        {children}
      </main>
    </div>
  )

  return (
    <>
      <Head title={title} />
      <TooltipProvider>
        {pageClassName ? (
          <div className={pageClassName}>{content}</div>
        ) : (
          content
        )}
      </TooltipProvider>
    </>
  )
}
