import type { Locale } from "@/lib/i18n/config";
import { getDictionary } from "@/lib/i18n/dictionaries";
import { MarketingShell } from "@/components/marketing/marketing-shell";
import { Section, SectionHeading } from "@/components/marketing/section";
import { FeatureDetailList } from "@/components/marketing/feature-detail-list";

export function FeaturesView({ locale }: { locale: Locale }) {
  const d = getDictionary(locale);
  return (
    <MarketingShell locale={locale}>
      <Section className="pt-16 md:pt-24">
        <SectionHeading
          eyebrow={d.nav.features}
          title={d.features.title}
          description={d.features.subtitle}
        />
        <FeatureDetailList sections={d.features.sections} />
      </Section>
    </MarketingShell>
  );
}
