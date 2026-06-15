"use client";

import { Download } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { useDash } from "@/hooks/use-dash";

type Data = {
  members: number;
  connections: number;
  pctConnected: number;
  deeplyEngaged: number;
  crossDiscipline: number;
  crossPct: number;
  disciplines: { name: string; count: number }[];
  programs: { name: string; count: number }[];
  events: number;
  attendance: number;
};

function Stat({ value, label }: { value: string; label: string }) {
  return (
    <div className="flex flex-col gap-1">
      <span className="text-3xl font-semibold tabular-nums tracking-tight sm:text-4xl">{value}</span>
      <span className="text-sm text-muted-foreground">{label}</span>
    </div>
  );
}

function BarRow({ name, count, max }: { name: string; count: number; max: number }) {
  return (
    <div className="flex items-center gap-3 text-sm">
      <span className="w-28 shrink-0 truncate capitalize">{name}</span>
      <span className="h-2 flex-1 overflow-hidden rounded-full bg-muted">
        <span className="block h-full rounded-full bg-foreground/80" style={{ width: `${Math.max(6, (count / max) * 100)}%` }} />
      </span>
      <span className="w-6 shrink-0 text-right tabular-nums text-muted-foreground">{count}</span>
    </div>
  );
}

export default function ReportPage() {
  const d = useDash<Data>("center:report");

  if (!d) {
    return (
      <div className="mx-auto w-full max-w-3xl space-y-6">
        <Skeleton className="h-8 w-80" />
        <div className="grid grid-cols-2 gap-6 sm:grid-cols-4">
          {Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-16" />)}
        </div>
        <Skeleton className="h-40 w-full rounded-2xl" />
      </div>
    );
  }

  const maxDisc = Math.max(1, ...d.disciplines.map((x) => x.count));
  const maxProg = Math.max(1, ...d.programs.map((x) => x.count));

  return (
    <div className="mx-auto w-full max-w-3xl">
      <div className="mb-8 flex items-start justify-between gap-4">
        <div>
          <p className="text-sm text-muted-foreground">Center for Entrepreneurship · University of Nebraska–Lincoln</p>
          <h1 className="mt-1 text-2xl font-semibold tracking-tight">Impact summary, Spring 2026</h1>
        </div>
        <Button variant="outline" className="shrink-0 gap-2 rounded-full" onClick={() => window.print()}>
          <Download className="size-4" /> Export
        </Button>
      </div>

      <p className="mb-8 max-w-2xl text-balance text-lg leading-relaxed">
        {d.members} students built {d.connections} connections this term, and{" "}
        <span className="font-semibold">{d.crossPct}% of them bridge different disciplines</span>. {d.pctConnected}% of
        students have connected with at least one other, and {d.deeplyEngaged} have built a lasting network of three or more.
      </p>

      <div className="mb-10 grid grid-cols-2 gap-6 border-y border-border py-6 sm:grid-cols-4">
        <Stat value={String(d.members)} label="students engaged" />
        <Stat value={String(d.connections)} label="connections made" />
        <Stat value={`${d.crossPct}%`} label="cross-discipline" />
        <Stat value={String(d.events)} label="events held" />
      </div>

      <div className="grid gap-10 sm:grid-cols-2">
        <section className="flex flex-col gap-3">
          <h2 className="text-sm font-medium">Students by discipline</h2>
          <div className="flex flex-col gap-2.5">
            {d.disciplines.slice(0, 8).map((x) => (
              <BarRow key={x.name} name={x.name} count={x.count} max={maxDisc} />
            ))}
          </div>
        </section>

        <section className="flex flex-col gap-3">
          <h2 className="text-sm font-medium">By program</h2>
          {d.programs.length > 0 ? (
            <div className="flex flex-col gap-2.5">
              {d.programs.map((x) => (
                <BarRow key={x.name} name={x.name} count={x.count} max={maxProg} />
              ))}
            </div>
          ) : (
            <p className="text-sm text-muted-foreground">No program tags yet.</p>
          )}
          <div className="mt-2 flex flex-col gap-1 border-t border-border pt-3 text-sm">
            <span className="text-muted-foreground">
              <span className="font-medium text-foreground tabular-nums">{d.attendance}</span> total event check-ins
            </span>
          </div>
        </section>
      </div>

      <p className="mt-10 border-t border-border pt-4 text-xs text-muted-foreground">
        Built live from Junto. Every number traces to its source. Updated automatically, no manual entry.
      </p>
    </div>
  );
}
