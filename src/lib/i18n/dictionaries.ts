import { tr } from "./dict/tr";
import { en } from "./dict/en";
import type { Locale } from "./config";

const map = { tr, en } as const;

export function getDictionary(locale: Locale) {
  return map[locale];
}

export type { Dictionary } from "./dict/tr";
