"use client";

import { useState } from "react";
import { ChevronDown } from "lucide-react";
import { cn } from "@/lib/utils";

type Item = { readonly q: string; readonly a: string };
type Group = { readonly title: string; readonly items: readonly Item[] };

export function FaqList({ groups }: { groups: readonly Group[] }) {
  const [open, setOpen] = useState<string | null>("0:0");
  return (
    <div className="mt-12 space-y-10">
      {groups.map((group, gi) => (
        <section key={group.title}>
          <h3 className="mb-4 text-xs font-semibold uppercase tracking-[0.18em] text-emerald-700 dark:text-emerald-400">
            {group.title}
          </h3>
          <div className="divide-y divide-border rounded-2xl border border-border bg-card">
            {group.items.map((item, ii) => {
              const key = `${gi}:${ii}`;
              const isOpen = open === key;
              return (
                <div key={item.q}>
                  <button
                    type="button"
                    aria-expanded={isOpen}
                    onClick={() => setOpen(isOpen ? null : key)}
                    className="flex w-full items-center justify-between gap-4 px-6 py-5 text-left"
                  >
                    <span className="text-base font-medium">{item.q}</span>
                    <ChevronDown
                      aria-hidden
                      className={cn(
                        "h-4 w-4 shrink-0 text-muted-foreground transition-transform",
                        isOpen && "rotate-180",
                      )}
                    />
                  </button>
                  <div
                    className={cn(
                      "grid overflow-hidden px-6 transition-all",
                      isOpen ? "grid-rows-[1fr] pb-5" : "grid-rows-[0fr]",
                    )}
                  >
                    <div className="min-h-0">
                      <p className="text-pretty text-sm leading-relaxed text-muted-foreground">
                        {item.a}
                      </p>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </section>
      ))}
    </div>
  );
}
