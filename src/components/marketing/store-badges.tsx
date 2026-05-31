import { Apple, Play } from "lucide-react";
import { cn } from "@/lib/utils";

export function StoreBadges({
  appStoreLabel,
  playStoreLabel,
  soonLabel,
  appStoreHref,
  playStoreHref,
  className,
}: {
  appStoreLabel: string;
  playStoreLabel: string;
  soonLabel: string;
  appStoreHref?: string;
  playStoreHref?: string;
  className?: string;
}) {
  return (
    <div className={cn("flex flex-wrap gap-3", className)}>
      <Badge
        href={appStoreHref}
        icon={<Apple className="h-5 w-5" />}
        title={appStoreLabel}
        soonLabel={soonLabel}
      />
      <Badge
        href={playStoreHref}
        icon={<Play className="h-5 w-5" />}
        title={playStoreLabel}
        soonLabel={soonLabel}
      />
    </div>
  );
}

function Badge({
  href,
  icon,
  title,
  soonLabel,
}: {
  href?: string;
  icon: React.ReactNode;
  title: string;
  soonLabel: string;
}) {
  const inner = (
    <span className="inline-flex items-center gap-3 rounded-xl border border-border bg-foreground px-4 py-2.5 text-background shadow-sm transition hover:bg-foreground/90">
      <span aria-hidden>{icon}</span>
      <span className="flex flex-col text-left leading-tight">
        <span className="text-[10px] uppercase tracking-wider opacity-80">
          {href ? "" : soonLabel}
        </span>
        <span className="text-sm font-semibold">{title}</span>
      </span>
    </span>
  );

  if (!href) {
    return (
      <span aria-disabled className="opacity-80">
        {inner}
      </span>
    );
  }
  return (
    <a href={href} target="_blank" rel="noreferrer">
      {inner}
    </a>
  );
}
