import type { Metadata } from "next";
import { PricingView } from "@/components/marketing/views/pricing-view";

export const metadata: Metadata = {
  title: "Fiyatlandırma",
  description:
    "Zirve Toptan tamamen ücretsizdir. Aylık abonelik, paket veya uygulama içi satın alma yoktur. Reklam göstermiyoruz, kullanıcı verisi satmıyoruz.",
};

export default function Page() {
  return <PricingView locale="tr" />;
}
