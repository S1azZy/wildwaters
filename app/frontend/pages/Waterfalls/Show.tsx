import AppShell from "../../components/AppShell"
import { Button } from "../../components/ui/button"
import { PageHeader, ProductCard } from "../../components/ww"
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
        <PageHeader
          description={waterfall.summary}
          eyebrow={waterfall.regionName}
          title={waterfall.name}
        />

        {waterfall.description ? (
          <ProductCard>
            <p className="leading-7 text-slate-700">{waterfall.description}</p>
          </ProductCard>
        ) : null}

        <ProductCard>
          <dl
            className="grid gap-4 sm:grid-cols-2"
            data-testid="waterfall-facts"
          >
            {waterfall.facts.map((fact) => (
              <div data-testid="waterfall-fact" key={fact.key}>
                <dt className="text-sm font-medium text-muted-foreground">
                  {fact.label}
                </dt>
                <dd className="mt-1 text-base text-foreground">{fact.value}</dd>
              </div>
            ))}
          </dl>
        </ProductCard>

        <div>
          <Button asChild variant="outline">
            <a href={urls.explore}>{copy.back}</a>
          </Button>
        </div>
      </article>
    </AppShell>
  )
}
