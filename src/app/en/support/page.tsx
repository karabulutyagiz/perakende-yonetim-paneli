import type { Metadata } from "next";
import { SupportView } from "@/components/marketing/views/support-view";

export const metadata: Metadata = {
  title: "Support Center",
  description:
    "ParaSende support center — common issues with step-by-step fixes, bug-report template, direct contact channels and operational information.",
};

export default function Page() {
  return <SupportView locale="en" />;
}
