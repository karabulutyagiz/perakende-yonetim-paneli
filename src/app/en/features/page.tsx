import type { Metadata } from "next";
import { FeaturesView } from "@/components/marketing/views/features-view";

export const metadata: Metadata = {
  title: "Features",
  description:
    "Inventory, customers, invoicing, credit-sales debt tracking, live sync, reports and secure sign-in — every Zirve Toptan feature explained.",
};

export default function Page() {
  return <FeaturesView locale="en" />;
}
