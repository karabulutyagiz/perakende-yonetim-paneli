import {
  Boxes,
  Users,
  Receipt,
  Wallet,
  RefreshCw,
  BarChart3,
  ShieldCheck,
  UserPlus,
} from "lucide-react";
import { cn } from "@/lib/utils";

const ICONS = [Boxes, Users, Wallet, RefreshCw, BarChart3, ShieldCheck, Receipt, UserPlus];

export function FeatureCards({
  items,
  className,
}: {
  items: readonly { readonly title: string; readonly body: string }[];
  className?: string;
}) {
  return (
    <div
      className={cn(
        "mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-3",
        className,
      )}
    >
      {items.map((item, i) => {
        const Icon = ICONS[i % ICONS.length];
        return (
          <article
            key={item.title}
            className="group relative overflow-hidden rounded-xl border border-border bg-card p-5 transition hover:border-foreground/20 hover:shadow-sm"
          >
            <div className="mb-3 inline-flex h-9 w-9 items-center justify-center rounded-lg bg-emerald-500/10 text-emerald-700 dark:text-emerald-300">
              <Icon className="h-4.5 w-4.5" />
            </div>
            <h3 className="text-base font-semibold tracking-tight">{item.title}</h3>
            <p className="mt-1.5 text-sm text-muted-foreground">{item.body}</p>
          </article>
        );
      })}
    </div>
  );
}
