"use client";

import { useEffect } from "react";

/**
 * Preserves the legacy admin entry point: toptanperakende.online/#/y/giris
 *
 * The Flutter web admin uses hash-based routing. When the marketing site is
 * served at the root, any visit with a hash starting with #/y/ (e.g. login,
 * password reset, deep links saved by users) is forwarded to the Flutter
 * admin shell mounted under /y/.
 */
export function HashRedirect() {
  useEffect(() => {
    const hash = typeof window !== "undefined" ? window.location.hash : "";
    if (hash && hash.startsWith("#/y/")) {
      window.location.replace(`/y/${hash}`);
    }
  }, []);

  return null;
}
