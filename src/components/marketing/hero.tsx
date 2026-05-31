import Link from "next/link";
import type { Locale } from "@/lib/i18n/config";
import { pathFor } from "@/lib/i18n/config";
import { getDictionary } from "@/lib/i18n/dictionaries";
import { StoreBadges } from "./store-badges";
import { PhoneLoginMockup } from "./phone-login-mockup";

export function Hero({ locale }: { locale: Locale }) {
  const d = getDictionary(locale);
  return (
    <section className="relative overflow-hidden border-b border-border/60">
      <div
        aria-hidden
        className="absolute inset-0 -z-10 bg-[radial-gradient(60%_60%_at_50%_-10%,hsl(160_70%_92%/_.9),transparent_60%),radial-gradient(40%_40%_at_90%_30%,hsl(210_80%_94%/_.7),transparent_60%)] dark:bg-[radial-gradient(60%_60%_at_50%_-10%,hsl(160_60%_20%/_.4),transparent_60%),radial-gradient(40%_40%_at_90%_30%,hsl(210_60%_24%/_.35),transparent_60%)]"
      />
      <div className="container grid gap-12 pb-16 pt-10 md:grid-cols-[1.15fr_1fr] md:pb-20 md:pt-14">
        <div className="flex max-w-xl flex-col">
          <p className="mb-3 inline-flex w-fit items-center gap-2 rounded-full border border-border bg-card/70 px-3 py-1 text-xs font-medium text-muted-foreground">
            <span className="h-1.5 w-1.5 rounded-full bg-emerald-500" />
            {d.hero.eyebrow}
          </p>
          <h1 className="text-balance text-4xl font-semibold tracking-tight md:text-5xl">
            {d.hero.title}
          </h1>
          <p className="mt-5 text-pretty text-base text-muted-foreground md:text-lg">
            {d.hero.subtitle}
          </p>
          <div className="mt-7 flex flex-wrap items-center gap-3">
            <Link
              href="/#/y/giris"
              className="inline-flex h-11 items-center justify-center rounded-md bg-foreground px-5 text-sm font-medium text-background shadow-sm transition hover:bg-foreground/90"
            >
              {d.hero.primaryCta}
            </Link>
            <Link
              href={pathFor("features", locale)}
              className="inline-flex h-11 items-center justify-center rounded-md border border-border bg-card px-5 text-sm font-medium text-foreground transition hover:bg-accent"
            >
              {d.hero.secondaryCta}
            </Link>
          </div>
          <p className="mt-4 text-xs text-muted-foreground">{d.hero.badge}</p>
          <div className="mt-8">
            <StoreBadges
              appStoreLabel={d.storeBadges.appStore}
              playStoreLabel={d.storeBadges.playStore}
              soonLabel={d.storeBadges.soon}
            />
          </div>
        </div>

        <div className="relative flex items-start justify-center">
          <div className="relative w-full max-w-[340px]">
            <div
              aria-hidden
              className="absolute -inset-8 rounded-[3rem] bg-gradient-to-br from-emerald-500/20 via-transparent to-teal-500/15 blur-3xl"
            />
            <PhoneLoginMockup className="relative" />
          </div>
        </div>
      </div>
    </section>
  );
}
