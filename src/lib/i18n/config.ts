export const locales = ["tr", "en"] as const;
export type Locale = (typeof locales)[number];
export const defaultLocale: Locale = "tr";

// Path slugs per locale. Keep them aligned by route name.
export const paths = {
  home:     { tr: "/",              en: "/en" },
  features: { tr: "/ozellikler",    en: "/en/features" },
  pricing:  { tr: "/fiyatlandirma", en: "/en/pricing" },
  about:    { tr: "/hakkimizda",    en: "/en/about" },
  faq:      { tr: "/sss",           en: "/en/faq" },
  contact:  { tr: "/iletisim",      en: "/en/contact" },
} as const;

export type RouteName = keyof typeof paths;

export function pathFor(name: RouteName, locale: Locale) {
  return paths[name][locale];
}
