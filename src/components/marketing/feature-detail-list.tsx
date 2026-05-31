import { Check } from "lucide-react";

export function FeatureDetailList({
  sections,
}: {
  sections: readonly {
    readonly title: string;
    readonly body: string;
    readonly bullets: readonly string[];
  }[];
}) {
  return (
    <div className="mt-12 grid gap-6 md:grid-cols-2">
      {sections.map((section) => (
        <article
          key={section.title}
          className="rounded-2xl border border-border bg-card p-6"
        >
          <h3 className="text-lg font-semibold tracking-tight">{section.title}</h3>
          <p className="mt-2 text-sm text-muted-foreground">{section.body}</p>
          <ul className="mt-4 space-y-1.5 text-sm">
            {section.bullets.map((b) => (
              <li key={b} className="flex items-start gap-2">
                <Check className="mt-0.5 h-4 w-4 shrink-0 text-emerald-600" />
                <span>{b}</span>
              </li>
            ))}
          </ul>
        </article>
      ))}
    </div>
  );
}
