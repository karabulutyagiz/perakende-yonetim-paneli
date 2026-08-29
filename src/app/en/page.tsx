import type { Metadata } from "next";
import { HomeView } from "@/components/marketing/views/home-view";

export const metadata: Metadata = {
  title: "Zirve Toptan — Wholesale & retail management panel",
  description:
    "Zirve Toptan is a free, mobile + web management panel for small and medium wholesale/retail businesses. Inventory, invoicing, credit-sales debt tracking and reports — in one place.",
};

export default function Page() {
  return <HomeView locale="en" />;
}
