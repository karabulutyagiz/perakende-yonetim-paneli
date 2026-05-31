import type { Metadata } from "next";
import { HomeView } from "@/components/marketing/views/home-view";

export const metadata: Metadata = {
  title: "ParaSende — Wholesale & retail management panel",
  description:
    "ParaSende is a free, mobile + web management panel for small and medium wholesale/retail businesses. Inventory, invoicing, credit-sales debt tracking and reports — in one place.",
};

export default function Page() {
  return <HomeView locale="en" />;
}
