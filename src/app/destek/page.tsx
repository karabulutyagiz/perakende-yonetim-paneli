import type { Metadata } from "next";
import { SupportView } from "@/components/marketing/views/support-view";

export const metadata: Metadata = {
  title: "Destek Merkezi",
  description:
    "ParaSende destek merkezi — sık karşılaşılan sorunların çözümleri, hata bildirme şablonu, doğrudan iletişim ve operasyonel bilgiler.",
};

export default function Page() {
  return <SupportView locale="tr" />;
}
