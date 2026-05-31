import type { Metadata } from "next";
import { PricingView } from "@/components/marketing/views/pricing-view";

export const metadata: Metadata = {
  title: "Pricing",
  description:
    "ParaSende is completely free. No subscriptions, no plans, no in-app purchases. We do not show ads and do not sell user data.",
};

export default function Page() {
  return <PricingView locale="en" />;
}
