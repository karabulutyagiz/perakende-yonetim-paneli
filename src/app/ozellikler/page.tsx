import type { Metadata } from "next";
import { FeaturesView } from "@/components/marketing/views/features-view";

export const metadata: Metadata = {
  title: "Özellikler",
  description:
    "Stok, müşteri, fatura, vadeli borç takibi, canlı senkronizasyon, raporlar ve güvenli giriş — ParaSende'nin sunduğu tüm özellikler.",
};

export default function Page() {
  return <FeaturesView locale="tr" />;
}
