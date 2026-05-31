import { Mail, Clock, MessageSquare, Languages, ShieldCheck } from "lucide-react";
import type { Locale } from "@/lib/i18n/config";
import { getDictionary } from "@/lib/i18n/dictionaries";
import { MarketingShell } from "@/components/marketing/marketing-shell";
import { Section, SectionHeading } from "@/components/marketing/section";
import { FaqList } from "@/components/marketing/faq-list";

export function SupportView({ locale }: { locale: Locale }) {
  const d = getDictionary(locale);
  const s = d.support;
  const c = s.contact;

  const faqGroup = [
    {
      title: s.issues.title,
      items: s.issues.items.map((item) => ({
        q: item.q,
        a: item.steps.map((line, i) => `${i + 1}. ${line}`).join("\n"),
      })),
    },
  ];

  return (
    <MarketingShell locale={locale}>
      <Section className="pt-16 md:pt-24">
        <SectionHeading eyebrow={d.nav.contact} title={s.title} description={s.lead} />

        {/* Direct contact */}
        <div className="mt-10 grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          <ContactCard
            icon={<Mail className="h-5 w-5" />}
            label={c.emailLabel}
            value={
              <a
                href={`mailto:${c.email}`}
                className="font-medium underline-offset-4 hover:underline"
              >
                {c.email}
              </a>
            }
          />
          <ContactCard
            icon={<Clock className="h-5 w-5" />}
            label={c.hoursLabel}
            value={<span className="text-sm">{c.hours}</span>}
          />
          <ContactCard
            icon={<MessageSquare className="h-5 w-5" />}
            label={c.slaLabel}
            value={<span className="text-sm">{c.sla}</span>}
          />
          <ContactCard
            icon={<Languages className="h-5 w-5" />}
            label={c.languagesLabel}
            value={<span className="text-sm">{c.languages}</span>}
          />
        </div>
      </Section>

      {/* Common issues */}
      <Section className="pt-0">
        <SectionHeading title={s.issues.title} description={s.issues.subtitle} />
        <FaqList groups={faqGroup} />
      </Section>

      {/* Operational info + bug template + reviewer note */}
      <Section className="pt-0">
        <div className="grid gap-6 md:grid-cols-2">
          <article className="rounded-2xl border border-border bg-card p-6">
            <h3 className="text-lg font-semibold tracking-tight">
              {s.operational.title}
            </h3>
            <dl className="mt-4 divide-y divide-border">
              {s.operational.items.map((row) => (
                <div
                  key={row.label}
                  className="grid grid-cols-[140px_1fr] gap-3 py-3 text-sm"
                >
                  <dt className="text-muted-foreground">{row.label}</dt>
                  <dd className="text-foreground">{row.value}</dd>
                </div>
              ))}
            </dl>
          </article>

          <article className="rounded-2xl border border-border bg-card p-6">
            <h3 className="text-lg font-semibold tracking-tight">
              {s.bugTemplate.title}
            </h3>
            <p className="mt-2 text-sm text-muted-foreground">
              {s.bugTemplate.subtitle}
            </p>
            <pre className="mt-4 max-h-80 overflow-auto whitespace-pre-wrap rounded-xl border border-border bg-muted/50 p-4 text-[12px] leading-relaxed text-foreground/90">
{s.bugTemplate.template}
            </pre>
          </article>
        </div>

        <article className="mt-6 rounded-2xl border border-emerald-200 bg-emerald-50 p-6 dark:border-emerald-900/60 dark:bg-emerald-950/30">
          <div className="flex items-start gap-3">
            <ShieldCheck className="mt-0.5 h-5 w-5 shrink-0 text-emerald-700 dark:text-emerald-300" />
            <div>
              <h3 className="text-base font-semibold">{s.reviewerNote.title}</h3>
              <p className="mt-1 text-sm text-foreground/80">{s.reviewerNote.body}</p>
            </div>
          </div>
        </article>

        <div className="mt-10">
          <h3 className="text-sm font-semibold uppercase tracking-wider text-muted-foreground">
            {s.quickLinks.title}
          </h3>
          <ul className="mt-3 flex flex-wrap gap-2">
            {s.quickLinks.items.map((link) => (
              <li key={link.href}>
                <a
                  href={link.href}
                  className="inline-flex h-8 items-center rounded-full border border-border bg-card px-3 text-xs text-foreground/80 transition hover:border-foreground/30 hover:text-foreground"
                >
                  {link.label}
                </a>
              </li>
            ))}
          </ul>
        </div>
      </Section>
    </MarketingShell>
  );
}

function ContactCard({
  icon,
  label,
  value,
}: {
  icon: React.ReactNode;
  label: string;
  value: React.ReactNode;
}) {
  return (
    <div className="rounded-2xl border border-border bg-card p-5">
      <span className="inline-flex h-10 w-10 items-center justify-center rounded-lg bg-emerald-500/10 text-emerald-700 dark:text-emerald-300">
        {icon}
      </span>
      <p className="mt-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
        {label}
      </p>
      <div className="mt-1.5">{value}</div>
    </div>
  );
}
