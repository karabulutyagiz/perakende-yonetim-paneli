import type { Metadata } from "next";
import { AboutView } from "@/components/marketing/views/about-view";

export const metadata: Metadata = {
  title: "Hakkımızda",
  description:
    "ParaSende bireysel bir geliştirici tarafından yürütülen, küçük/orta ölçekli toptan-perakende işletmeler için tasarlanmış ücretsiz bir yönetim panelidir.",
};

export default function Page() {
  return <AboutView locale="tr" />;
}
