import Link from "next/link";
import type { Locale } from "@/lib/i18n/config";
import { pathFor } from "@/lib/i18n/config";
import { getDictionary } from "@/lib/i18n/dictionaries";
import { MarketingShell } from "@/components/marketing/marketing-shell";
import { Hero } from "@/components/marketing/hero";
import { Section, SectionHeading } from "@/components/marketing/section";
import { FeatureCards } from "@/components/marketing/feature-cards";
import { Check } from "lucide-react";

export function HomeView({ locale }: { locale: Locale }) {
  const d = getDictionary(locale);
  return (
    <MarketingShell locale={locale}>
      <Hero locale={locale} />

      <Section>
        <SectionHeading
          eyebrow={d.highlights.title}
          title={d.highlights.subtitle}
        />
        <FeatureCards items={d.highlights.items} />
      </Section>

      <Section className="border-t border-border/60 bg-card/40">
        <div className="grid items-start gap-10 md:grid-cols-[1fr_1.3fr]">
          <div>
            <SectionHeading title={d.forWho.title} description={d.forWho.body} />
          </div>
          <ul className="space-y-3 text-base">
            {d.forWho.points.map((p) => (
              <li
                key={p}
                className="flex items-start gap-3 rounded-xl border border-border bg-card p-4"
              >
                <Check className="mt-0.5 h-5 w-5 shrink-0 text-emerald-600" />
                <span>{p}</span>
              </li>
            ))}
          </ul>
        </div>
      </Section>

      <Section>
        <div className="rounded-3xl border border-border bg-gradient-to-br from-foreground to-foreground/90 px-8 py-12 text-background md:px-14 md:py-16">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-background/70">
            {d.pricing.title}
          </p>
          <h2 className="mt-3 text-balance text-3xl font-semibold md:text-4xl">
            {d.pricing.subtitle}
          </h2>
          <p className="mt-4 max-w-2xl text-pretty text-background/80">
            {d.pricing.description}
          </p>
          <div className="mt-8 flex flex-wrap gap-3">
            <Link
              href={pathFor("pricing", locale)}
              className="inline-flex h-11 items-center justify-center rounded-md bg-background px-5 text-sm font-medium text-foreground transition hover:bg-background/90"
            >
              {d.nav.pricing}
            </Link>
            <Link
              href="/#/y/giris"
              className="inline-flex h-11 items-center justify-center rounded-md border border-background/30 px-5 text-sm font-medium text-background transition hover:bg-background/10"
            >
              {d.hero.primaryCta}
            </Link>
          </div>
        </div>
      </Section>
    </MarketingShell>
  );
}
