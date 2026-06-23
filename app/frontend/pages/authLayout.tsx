import type { ReactNode } from "react"

import AppShell from "../components/AppShell"
import AuthShell, { type AuthShellProps } from "../components/AuthShell"
import type { ShellProps } from "../types/page"

interface AuthLayoutProps {
  auth: AuthShellProps
  children: ReactNode
  page: string
  shell: ShellProps
}

export default function AuthLayout({
  auth,
  children,
  page,
  shell,
}: AuthLayoutProps) {
  return (
    <AppShell
      mainClassName="auth-main"
      pageClassName="auth-page"
      shell={shell}
      title={auth.title}
    >
      <div className="flex w-full" data-auth-page={page}>
        <AuthShell auth={auth}>{children}</AuthShell>
      </div>
    </AppShell>
  )
}
