import { Mail, ShieldCheck, LifeBuoy, Trash2 } from "lucide-react";
import type { Locale } from "@/lib/i18n/config";
import { getDictionary } from "@/lib/i18n/dictionaries";
import { MarketingShell } from "@/components/marketing/marketing-shell";
import { Section, SectionHeading } from "@/components/marketing/section";

export function ContactView({ locale }: { locale: Locale }) {
  const d = getDictionary(locale);
  return (
    <MarketingShell locale={locale}>
      <Section className="pt-16 md:pt-24">
        <SectionHeading
          eyebrow={d.nav.contact}
          title={d.contact.title}
          description={d.contact.lead}
        />

        <div className="mt-10 grid gap-5 md:grid-cols-2">
          <ContactCard
            icon={<Mail className="h-5 w-5" />}
            label={d.contact.emailLabel}
            value={
              <a
                href={`mailto:${d.contact.email}`}
                className="text-base font-medium underline-offset-4 hover:underline"
              >
                {d.contact.email}
              </a>
            }
          />
          <ContactCard
            icon={<ShieldCheck className="h-5 w-5" />}
            label={d.contact.privacyLabel}
            value={
              <a
                href={`mailto:${d.contact.email}`}
                className="text-base font-medium underline-offset-4 hover:underline"
              >
                {d.contact.email}
              </a>
            }
          />
          <ContactCard
            icon={<LifeBuoy className="h-5 w-5" />}
            label={d.contact.legal.support}
            value={
              <a
                href="/legal/support.html"
                className="text-base font-medium underline-offset-4 hover:underline"
              >
                /legal/support.html
              </a>
            }
          />
          <ContactCard
            icon={<Trash2 className="h-5 w-5" />}
            label={d.contact.legal.delete}
            value={
              <a
                href="/legal/delete-account.html"
                className="text-base font-medium underline-offset-4 hover:underline"
              >
                /legal/delete-account.html
              </a>
            }
          />
        </div>

        <p className="mt-8 text-sm text-muted-foreground">{d.contact.responseTime}</p>
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
      <div className="flex items-start gap-4">
        <span className="inline-flex h-10 w-10 items-center justify-center rounded-lg bg-emerald-500/10 text-emerald-700 dark:text-emerald-300">
          {icon}
        </span>
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            {label}
          </p>
          <div className="mt-1">{value}</div>
        </div>
      </div>
    </div>
  );
}
