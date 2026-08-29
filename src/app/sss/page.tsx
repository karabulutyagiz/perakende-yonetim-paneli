import type { Metadata } from "next";
import { FaqView } from "@/components/marketing/views/faq-view";

export const metadata: Metadata = {
  title: "Sıkça Sorulan Sorular",
  description:
    "Zirve Toptan hakkında sıkça sorulan sorular: ücret, hesap oluşturma, uygulama içi satın alma, hedef kullanıcı, veri silme ve sunucu altyapısı.",
};

export default function Page() {
  return <FaqView locale="tr" />;
}
