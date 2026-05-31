import Link from "next/link";
import type { Locale } from "@/lib/i18n/config";
import { pathFor } from "@/lib/i18n/config";
import { getDictionary } from "@/lib/i18n/dictionaries";
import { Logo } from "./logo";
import { LanguageSwitcher } from "./language-switcher";

const SIGN_IN_URL = "/#/y/giris";

export function SiteHeader({ locale }: { locale: Locale }) {
  const d = getDictionary(locale);
  const nav = [
    { href: pathFor("features", locale), label: d.nav.features },
    { href: pathFor("pricing", locale), label: d.nav.pricing },
    { href: pathFor("about", locale), label: d.nav.about },
    { href: pathFor("faq", locale), label: d.nav.faq },
    { href: pathFor("contact", locale), label: d.nav.contact },
  ];

  return (
    <header className="sticky top-0 z-40 w-full border-b border-border/60 bg-background/80 backdrop-blur">
      <div className="container flex h-14 items-center justify-between gap-4">
        <Logo locale={locale} />

        <nav className="hidden items-center gap-6 text-sm text-muted-foreground md:flex">
          {nav.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="transition hover:text-foreground"
            >
              {item.label}
            </Link>
          ))}
        </nav>

        <div className="flex items-center gap-3">
          <LanguageSwitcher locale={locale} className="hidden sm:inline-flex" />
          <Link
            href={SIGN_IN_URL}
            className="inline-flex h-9 items-center justify-center rounded-md bg-foreground px-3.5 text-sm font-medium text-background shadow-sm transition hover:bg-foreground/90"
          >
            {d.nav.signIn}
          </Link>
        </div>
      </div>
      <MobileNav nav={nav} />
    </header>
  );
}

function MobileNav({ nav }: { nav: { href: string; label: string }[] }) {
  return (
    <div className="md:hidden">
      <div className="container flex gap-4 overflow-x-auto pb-2 text-sm text-muted-foreground">
        {nav.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className="whitespace-nowrap transition hover:text-foreground"
          >
            {item.label}
          </Link>
        ))}
      </div>
    </div>
  );
}
