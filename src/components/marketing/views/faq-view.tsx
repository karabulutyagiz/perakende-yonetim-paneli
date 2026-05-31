import type { Locale } from "@/lib/i18n/config";
import { getDictionary } from "@/lib/i18n/dictionaries";
import { MarketingShell } from "@/components/marketing/marketing-shell";
import { Section, SectionHeading } from "@/components/marketing/section";
import { FaqList } from "@/components/marketing/faq-list";

export function FaqView({ locale }: { locale: Locale }) {
  const d = getDictionary(locale);
  return (
    <MarketingShell locale={locale}>
      <Section className="pt-16 md:pt-24">
        <SectionHeading
          eyebrow={d.nav.faq}
          title={d.faq.title}
          description={d.faq.subtitle}
        />
        <FaqList groups={d.faq.groups} />
      </Section>
    </MarketingShell>
  );
}
