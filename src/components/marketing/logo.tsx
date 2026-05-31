import Link from "next/link";
import Image from "next/image";
import { cn } from "@/lib/utils";
import type { Locale } from "@/lib/i18n/config";
import { pathFor } from "@/lib/i18n/config";

export function Logo({ locale, className }: { locale: Locale; className?: string }) {
  return (
    <Link
      href={pathFor("home", locale)}
      className={cn(
        "inline-flex items-center gap-2 font-semibold tracking-tight text-foreground",
        className,
      )}
      aria-label="ParaSende"
    >
      <Image
        src="/app-icon.png"
        alt=""
        width={28}
        height={28}
        priority
        className="h-7 w-7 rounded-md object-cover"
      />
      <span className="text-base">ParaSende</span>
    </Link>
  );
}
