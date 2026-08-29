import type { Metadata } from "next";
import { AboutView } from "@/components/marketing/views/about-view";

export const metadata: Metadata = {
  title: "About",
  description:
    "Zirve Toptan is a small, focused project built by a single developer for small/medium wholesale and retail businesses in Turkey.",
};

export default function Page() {
  return <AboutView locale="en" />;
}
