import type { Locale } from "@/lib/i18n/config";
import { getDictionary } from "@/lib/i18n/dictionaries";
import { MarketingShell } from "@/components/marketing/marketing-shell";
import { Section, SectionHeading } from "@/components/marketing/section";

export function AboutView({ locale }: { locale: Locale }) {
  const d = getDictionary(locale);
  return (
    <MarketingShell locale={locale}>
      <Section className="pt-16 md:pt-24">
        <SectionHeading
          eyebrow={d.nav.about}
          title={d.about.title}
          description={d.about.lead}
        />

        <div className="mt-10 grid gap-10 md:grid-cols-[1.4fr_1fr]">
          <div className="space-y-5 text-pretty text-base leading-relaxed text-foreground/90">
            {d.about.paragraphs.map((p) => (
              <p key={p}>{p}</p>
            ))}
          </div>

          <aside className="h-fit rounded-2xl border border-border bg-card p-6">
            <h3 className="text-sm font-semibold uppercase tracking-wider text-muted-foreground">
              {d.about.contact.title}
            </h3>
            <p className="mt-3 text-sm">
              <a
                href={`mailto:${d.about.contact.email}`}
                className="font-medium underline-offset-4 hover:underline"
              >
                {d.about.contact.email}
              </a>
            </p>
            <h3 className="mt-6 text-sm font-semibold uppercase tracking-wider text-muted-foreground">
              {d.about.contact.legal}
            </h3>
            <ul className="mt-3 space-y-1.5 text-sm">
              <li>
                <a className="hover:underline" href="/legal/privacy.html">
                  {d.footer.privacy}
                </a>
              </li>
              <li>
                <a className="hover:underline" href="/legal/support.html">
                  {d.footer.support}
                </a>
              </li>
              <li>
                <a className="hover:underline" href="/legal/delete-account.html">
                  {d.footer.delete}
                </a>
              </li>
            </ul>
          </aside>
        </div>
      </Section>
    </MarketingShell>
  );
}
