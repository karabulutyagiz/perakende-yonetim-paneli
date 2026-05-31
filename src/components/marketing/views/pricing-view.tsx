import type { Locale } from "@/lib/i18n/config";
import { getDictionary } from "@/lib/i18n/dictionaries";
import { MarketingShell } from "@/components/marketing/marketing-shell";
import { Section, SectionHeading } from "@/components/marketing/section";
import { PricingCard } from "@/components/marketing/pricing-card";

export function PricingView({ locale }: { locale: Locale }) {
  const d = getDictionary(locale);
  return (
    <MarketingShell locale={locale}>
      <Section className="pt-16 md:pt-24">
        <SectionHeading
          eyebrow={d.nav.pricing}
          title={d.pricing.title}
          description={d.pricing.subtitle}
          align="center"
        />
        <PricingCard
          bigStatement={d.pricing.bigStatement}
          bigCaption={d.pricing.bigCaption}
          description={d.pricing.description}
          included={d.pricing.included}
          notIncluded={d.pricing.notIncluded}
          cta={d.pricing.cta}
          footnote={d.pricing.footnote}
        />
      </Section>
    </MarketingShell>
  );
}
