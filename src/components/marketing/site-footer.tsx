import Link from "next/link";
import type { Locale } from "@/lib/i18n/config";
import { pathFor } from "@/lib/i18n/config";
import { getDictionary } from "@/lib/i18n/dictionaries";
import { Logo } from "./logo";

export function SiteFooter({ locale }: { locale: Locale }) {
  const d = getDictionary(locale);
  const year = new Date().getFullYear();

  return (
    <footer className="mt-24 border-t border-border/60 bg-card/40">
      <div className="container grid gap-10 py-12 md:grid-cols-[1.4fr_1fr_1fr_1fr]">
        <div className="space-y-3">
          <Logo locale={locale} />
          <p className="max-w-sm text-sm text-muted-foreground">{d.meta.tagline}</p>
          <p className="text-xs text-muted-foreground">{d.footer.builtBy}</p>
        </div>

        <FooterColumn title={d.footer.product}>
          <FooterLink href={pathFor("features", locale)} label={d.nav.features} />
          <FooterLink href={pathFor("pricing", locale)} label={d.nav.pricing} />
          <FooterLink href={pathFor("faq", locale)} label={d.nav.faq} />
        </FooterColumn>

        <FooterColumn title={d.footer.company}>
          <FooterLink href={pathFor("about", locale)} label={d.nav.about} />
          <FooterLink href={pathFor("contact", locale)} label={d.nav.contact} />
          <FooterLink href="/#/y/giris" label={d.nav.signIn} />
        </FooterColumn>

        <FooterColumn title={d.footer.legal}>
          <FooterLink href="/legal/privacy.html" label={d.footer.privacy} external />
          <FooterLink href="/legal/terms.html" label={d.footer.terms} external />
          <FooterLink href="/legal/cookies.html" label={d.footer.cookies} external />
          <FooterLink href="/legal/kvkk.html" label={d.footer.kvkk} external />
          <FooterLink href="/legal/delete-account.html" label={d.footer.delete} external />
          <FooterLink
            href={locale === "tr" ? "/destek/" : "/en/support/"}
            label={d.footer.support}
          />
        </FooterColumn>
      </div>

      <div className="border-t border-border/60">
        <div className="container flex flex-col items-start justify-between gap-2 py-4 text-xs text-muted-foreground md:flex-row md:items-center">
          <p>© {year} ParaSende. {d.footer.rights}</p>
          <p>destek@toptanpanel.com</p>
        </div>
      </div>
    </footer>
  );
}

function FooterColumn({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <h3 className="mb-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
        {title}
      </h3>
      <ul className="space-y-2 text-sm">{children}</ul>
    </div>
  );
}

function FooterLink({
  href,
  label,
  external,
}: {
  href: string;
  label: string;
  external?: boolean;
}) {
  if (external) {
    return (
      <li>
        <a
          href={href}
          className="text-foreground/80 transition hover:text-foreground"
        >
          {label}
        </a>
      </li>
    );
  }
  return (
    <li>
      <Link href={href} className="text-foreground/80 transition hover:text-foreground">
        {label}
      </Link>
    </li>
  );
}
