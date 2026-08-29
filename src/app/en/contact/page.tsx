import type { Metadata } from "next";
import { ContactView } from "@/components/marketing/views/contact-view";

export const metadata: Metadata = {
  title: "Contact",
  description:
    "Reach the Zirve Toptan team for account, usage, bug, data export or deletion requests: destek@toptanpanel.com.",
};

export default function Page() {
  return <ContactView locale="en" />;
}
