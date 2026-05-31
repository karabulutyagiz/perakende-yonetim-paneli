import Link from "next/link";
import { Check, X } from "lucide-react";

export function PricingCard({
  bigStatement,
  bigCaption,
  description,
  included,
  notIncluded,
  cta,
  footnote,
}: {
  bigStatement: string;
  bigCaption: string;
  description: string;
  included: readonly string[];
  notIncluded: readonly string[];
  cta: string;
  footnote: string;
}) {
  return (
    <div className="mx-auto mt-12 max-w-2xl">
      <div className="overflow-hidden rounded-2xl border border-border bg-card shadow-sm">
        <div className="border-b border-border bg-gradient-to-br from-emerald-50 to-teal-50 px-8 py-10 text-center dark:from-emerald-950/40 dark:to-teal-950/30">
          <p className="text-7xl font-semibold tracking-tight">{bigStatement}</p>
          <p className="mt-2 text-sm uppercase tracking-wider text-muted-foreground">
            {bigCaption}
          </p>
        </div>
        <div className="px-8 py-8">
          <p className="text-pretty text-sm text-muted-foreground">{description}</p>

          <ul className="mt-6 space-y-2 text-sm">
            {included.map((item) => (
              <li key={item} className="flex items-start gap-2">
                <Check className="mt-0.5 h-4 w-4 shrink-0 text-emerald-600" />
                <span>{item}</span>
              </li>
            ))}
          </ul>

          <ul className="mt-4 space-y-2 text-sm text-muted-foreground">
            {notIncluded.map((item) => (
              <li key={item} className="flex items-start gap-2">
                <X className="mt-0.5 h-4 w-4 shrink-0 text-muted-foreground/70" />
                <span>{item}</span>
              </li>
            ))}
          </ul>

          <Link
            href="/#/y/giris"
            className="mt-8 inline-flex h-11 w-full items-center justify-center rounded-md bg-foreground px-5 text-sm font-medium text-background shadow-sm transition hover:bg-foreground/90"
          >
            {cta}
          </Link>

          <p className="mt-6 text-xs text-muted-foreground">{footnote}</p>
        </div>
      </div>
    </div>
  );
}
