import type { ReactNode } from "react"

import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardFooter, CardHeader } from "@/components/ui/card"

export type AuthShellVariant = "session" | "registration" | "recovery"

export interface AuthShellProps {
  alternateLabel: string
  alternatePrompt: string
  alternateUrl: string
  description: string
  eyebrow: string
  panelLabel: string
  title: string
  variant: AuthShellVariant
}

interface AuthShellComponentProps {
  auth: AuthShellProps
  children: ReactNode
}

export default function AuthShell({ auth, children }: AuthShellComponentProps) {
  return (
    <section
      className={`auth-shell auth-shell--${auth.variant}`}
      data-ui="auth-shell"
      data-variant={auth.variant}
    >
      <div className="auth-shell__backdrop" aria-hidden="true">
        <div className="auth-shell__glow auth-shell__glow--one" />
        <div className="auth-shell__glow auth-shell__glow--two" />
        <div className="auth-shell__grid" />
      </div>

      <div className="auth-shell__content">
        <div className="auth-shell__intro">
          <p className="auth-shell__eyebrow">{auth.eyebrow}</p>
          <h1 className="auth-shell__title" data-display-text>
            {auth.title}
          </h1>
          <p className="auth-shell__description">{auth.description}</p>
        </div>

        <Card className="auth-card" data-ui="auth-card">
          <CardHeader className="auth-card__header">
            <Badge className="auth-card__label" variant="secondary">
              {auth.panelLabel}
            </Badge>
          </CardHeader>
          <CardContent className="auth-card__body">{children}</CardContent>
          <CardFooter className="auth-card__alternate">
            <span>{auth.alternatePrompt}</span>
            <a className="auth-card__alternate-link" href={auth.alternateUrl}>
              {auth.alternateLabel}
            </a>
          </CardFooter>
        </Card>
      </div>
    </section>
  )
}
