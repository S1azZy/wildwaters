import AppShell from "../../components/AppShell"
import type { SharedPageProps } from "../../types/page"

type WaterfallFactKey =
  | "height"
  | "flowSeasonality"
  | "approachDifficulty"
  | "plungePool"

interface WaterfallFact {
  key: WaterfallFactKey
  label: string
  value: string
}

export interface WaterfallShowPageProps extends SharedPageProps {
  copy: {
    back: string
  }
  urls: {
    explore: string
  }
  waterfall: {
    publicId: string
    name: string
    regionName: string
    summary: string | null
    description: string | null
    facts: WaterfallFact[]
  }
}

export default function Show({
  copy,
  shell,
  urls,
  waterfall,
}: WaterfallShowPageProps) {
  return (
    <AppShell shell={shell} title={waterfall.name}>
      <article
        className="mx-auto flex w-full max-w-3xl flex-col gap-6"
        data-waterfall-detail={waterfall.publicId}
      >
        <header className="space-y-3">
          <p className="text-xs font-medium uppercase tracking-[0.16em] text-slate-500">
            {waterfall.regionName}
          </p>
          <h1 className="text-3xl font-semibold text-slate-900">
            {waterfall.name}
          </h1>
          {waterfall.summary ? (
            <p className="text-lg text-slate-700">{waterfall.summary}</p>
          ) : null}
        </header>

        {waterfall.description ? (
          <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <p className="leading-7 text-slate-700">{waterfall.description}</p>
          </section>
        ) : null}

        <dl
          className="grid gap-4 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:grid-cols-2"
          data-testid="waterfall-facts"
        >
          {waterfall.facts.map((fact) => (
            <div data-testid="waterfall-fact" key={fact.key}>
              <dt className="text-sm font-medium text-slate-500">
                {fact.label}
              </dt>
              <dd className="mt-1 text-base text-slate-900">{fact.value}</dd>
            </div>
          ))}
        </dl>

        <div>
          <a
            className="text-sm font-medium text-sky-700 hover:text-sky-800"
            href={urls.explore}
          >
            {copy.back}
          </a>
        </div>
      </article>
    </AppShell>
  )
}
