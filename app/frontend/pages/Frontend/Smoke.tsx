import { useState } from "react"

import type { SharedPageProps } from "../../types/page"

export interface SmokePageProps extends SharedPageProps {
  copy: {
    action: string
    description: string
    eyebrow: string
    interaction: string
    title: string
  }
  urls: {
    home: string
  }
}

export default function Smoke({ copy, urls }: SmokePageProps) {
  const [interactionConfirmed, setInteractionConfirmed] = useState(false)

  return (
    <main className="site-shell">
      <section className="auth-shell auth-shell--session">
        <div className="auth-shell__content">
          <div className="auth-shell__intro">
            <p className="auth-shell__eyebrow">{copy.eyebrow}</p>
            <h1 className="auth-shell__title">{copy.title}</h1>
            <p className="auth-shell__description">{copy.description}</p>
            <div className="flex flex-wrap items-center justify-center gap-3">
              <button
                aria-pressed={interactionConfirmed}
                className="ui-button ui-button--primary ui-button--md"
                onClick={() => {
                  setInteractionConfirmed(true)
                }}
                type="button"
              >
                {copy.interaction}
              </button>
              <a
                className="ui-button ui-button--secondary ui-button--md"
                href={urls.home}
              >
                {copy.action}
              </a>
            </div>
            {interactionConfirmed ? (
              <p className="text-success-700 font-semibold" role="status">
                {copy.interaction}
              </p>
            ) : null}
          </div>
        </div>
      </section>
    </main>
  )
}
