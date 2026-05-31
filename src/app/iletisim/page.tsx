import type { Metadata } from "next";
import { ContactView } from "@/components/marketing/views/contact-view";

export const metadata: Metadata = {
  title: "İletişim",
  description:
    "Hesap, kullanım, hata, veri dışa aktarma veya silme talepleri için ParaSende destek ekibi: destek@toptanpanel.com.",
};

export default function Page() {
  return <ContactView locale="tr" />;
}
