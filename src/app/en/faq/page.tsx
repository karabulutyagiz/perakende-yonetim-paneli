import type { Metadata } from "next";
import { FaqView } from "@/components/marketing/views/faq-view";

export const metadata: Metadata = {
  title: "FAQ",
  description:
    "Frequently asked questions about ParaSende: pricing, account creation, in-app purchases, target users, data deletion and backend stack.",
};

export default function Page() {
  return <FaqView locale="en" />;
}
