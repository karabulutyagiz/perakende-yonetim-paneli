import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const font = Inter({ subsets: ["latin"] });

const SITE_URL = "https://toptanperakende.online";

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: "Zirve Toptan — Toptan ve perakende yönetim paneli",
    template: "%s · Zirve Toptan",
  },
  description:
    "Toptan ve perakende küçük/orta ölçekli işletmeler için ücretsiz stok, fatura, borç ve raporlama paneli. Mobil + web admin.",
  openGraph: {
    type: "website",
    siteName: "Zirve Toptan",
    url: SITE_URL,
    title: "Zirve Toptan — Toptan ve perakende yönetim paneli",
    description:
      "Tek panelden ürün, müşteri, fatura ve vadeli borç yönetimi. Mobil + web. Tamamen ücretsiz.",
  },
  twitter: {
    card: "summary_large_image",
    title: "Zirve Toptan",
    description:
      "Toptan & perakende işletmeler için ücretsiz yönetim paneli.",
  },
  icons: {
    icon: "/app-icon.png",
    apple: "/app-icon.png",
  },
  alternates: {
    canonical: SITE_URL,
    languages: {
      "tr-TR": SITE_URL,
      "en-US": `${SITE_URL}/en`,
    },
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="tr">
      <body className={font.className}>{children}</body>
    </html>
  );
}
