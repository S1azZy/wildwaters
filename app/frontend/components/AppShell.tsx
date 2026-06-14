import { Head, usePage } from "@inertiajs/react"
import type { ReactNode } from "react"

import type { ShellProps } from "../types/page"
import Flash from "./Flash"
import SiteHeader from "./SiteHeader"

interface AppShellProps {
  children: ReactNode
  shell: ShellProps
  title: string
}

export default function AppShell({ children, shell, title }: AppShellProps) {
  const { flash } = usePage()

  return (
    <>
      <Head title={title} />
      <div className="site-shell">
        <SiteHeader {...shell} />
        <main className="mx-auto w-full max-w-[112rem] flex-1 px-4 py-6 sm:px-6 lg:px-8">
          <Flash {...flash} />
          {children}
        </main>
      </div>
    </>
  )
}
