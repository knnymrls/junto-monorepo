"use client";

import Link from "next/link";
import { CalendarClock, Lightbulb, MessageSquare, UserPlus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { useDash } from "@/hooks/use-dash";

type Need = { key: string; title: string; desc: string; action: string };

const ICON: Record<string, React.ComponentType<{ className?: string }>> = {
  isolated: UserPlus,
  need: Lightbulb,
  silent: MessageSquare,
  event: CalendarClock,
};

// Where each action takes Amanda to act.
const HREF: Record<string, string> = {
  isolated: "/needs",
  need: "/needs",
  silent: "/needs",
  event: "/events",
};

export function NeedsAttention() {
  const needs = useDash<Need[]>("center:needs");

  return (
    <section className="flex flex-col gap-3">
      <div className="flex items-baseline justify-between">
        <h3 className="text-sm font-medium">What needs you</h3>
        <span className="text-xs tabular-nums text-muted-foreground">{needs?.length ?? ""}</span>
      </div>

      <div className="-mx-2 divide-y divide-border">
        {!needs ? (
          Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="flex items-center gap-3 px-2 py-3.5">
              <Skeleton className="size-7 rounded-full" />
              <div className="flex-1 space-y-1.5">
                <Skeleton className="h-3.5 w-3/4" />
                <Skeleton className="h-3 w-1/2" />
              </div>
            </div>
          ))
        ) : needs.length === 0 ? (
          <p className="px-2 py-8 text-sm text-muted-foreground">Nothing needs you right now.</p>
        ) : (
          needs.map((n) => {
            const Icon = ICON[n.key] ?? Lightbulb;
            return (
              <div key={n.key} className="flex items-center gap-3 px-2 py-3.5">
                <span className="flex size-8 shrink-0 items-center justify-center text-muted-foreground">
                  <Icon className="size-[18px]" />
                </span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-medium">{n.title}</p>
                  <p className="truncate text-xs text-muted-foreground">{n.desc}</p>
                </div>
                <Button
                  size="sm"
                  variant="outline"
                  className="shrink-0 rounded-full px-3.5"
                  render={<Link href={HREF[n.key] ?? "/needs"} />}
                >
                  {n.action}
                </Button>
              </div>
            );
          })
        )}
      </div>
    </section>
  );
}
