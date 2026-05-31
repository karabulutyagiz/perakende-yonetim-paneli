import Link from "next/link";
import { cn } from "@/lib/utils";
import type { Locale } from "@/lib/i18n/config";

export function LanguageSwitcher({
  locale,
  className,
}: {
  locale: Locale;
  className?: string;
}) {
  // Switching always goes to the home page of the other locale.
  // (We avoid mapping every page slug; the home is the safest landing.)
  const otherHref = locale === "tr" ? "/en" : "/";
  const otherLabel = locale === "tr" ? "EN" : "TR";
  const currentLabel = locale === "tr" ? "TR" : "EN";

  return (
    <div
      className={cn(
        "inline-flex items-center rounded-full border border-border bg-card p-0.5 text-xs font-medium",
        className,
      )}
      aria-label="Dil seçimi"
    >
      <span className="rounded-full bg-foreground px-2.5 py-1 text-background">
        {currentLabel}
      </span>
      <Link
        href={otherHref}
        className="rounded-full px-2.5 py-1 text-muted-foreground transition hover:text-foreground"
      >
        {otherLabel}
      </Link>
    </div>
  );
}
