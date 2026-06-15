"use client";

import { CalendarDays, Star, Users } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import { useDash } from "@/hooks/use-dash";
import { dateLabel } from "@/lib/format";

type Row = {
  id: string;
  title: string;
  date: number;
  location: string | null;
  type: string;
  host: string | null;
  category: string | null;
  going: number;
  interested: number;
  rating: number | null;
  feedbackCount: number;
};

function EventRow({ e }: { e: Row }) {
  return (
    <button className="group flex w-full items-center gap-4 px-2 py-4 text-left transition-colors hover:bg-muted/50">
      <div className="flex w-12 shrink-0 flex-col items-center">
        <span className="text-lg font-semibold tabular-nums leading-none">
          {new Date(e.date).toLocaleDateString("en-US", { day: "numeric" })}
        </span>
        <span className="text-[11px] uppercase tracking-wide text-muted-foreground">
          {new Date(e.date).toLocaleDateString("en-US", { month: "short" })}
        </span>
      </div>
      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-medium">{e.title}</p>
        <p className="truncate text-xs text-muted-foreground">
          {[e.host, e.location, e.category].filter(Boolean).join(" · ") || dateLabel(e.date)}
        </p>
      </div>
      <div className="flex shrink-0 items-center gap-4 text-xs text-muted-foreground tabular-nums">
        <span className="inline-flex items-center gap-1">
          <Users className="size-3.5" /> {e.going}
        </span>
        {e.rating != null && (
          <span className="inline-flex items-center gap-1">
            <Star className="size-3.5" /> {e.rating}
          </span>
        )}
      </div>
    </button>
  );
}

function Section({ label, rows }: { label: string; rows: Row[] }) {
  if (rows.length === 0) return null;
  return (
    <section className="flex flex-col gap-2">
      <div className="flex items-baseline justify-between">
        <h3 className="text-sm font-medium">{label}</h3>
        <span className="text-xs tabular-nums text-muted-foreground">{rows.length}</span>
      </div>
      <div className="-mx-2 divide-y divide-border">
        {rows.map((e) => (
          <EventRow key={e.id} e={e} />
        ))}
      </div>
    </section>
  );
}

export default function EventsPage() {
  const rows = useDash<Row[]>("center:eventsList");
  const now = Date.now();
  const upcoming = rows?.filter((e) => e.date >= now) ?? [];
  const past = rows?.filter((e) => e.date < now) ?? [];

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-col gap-6">
      <div className="flex items-end justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">Events</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            Turnout and post-event impact, captured automatically as students RSVP and show up.
          </p>
        </div>
        <span className="inline-flex shrink-0 items-center gap-1.5 text-sm text-muted-foreground">
          <CalendarDays className="size-4" /> {rows ? rows.length : "—"} events
        </span>
      </div>

      {!rows ? (
        <div className="-mx-2 divide-y divide-border">
          {Array.from({ length: 5 }).map((_, i) => (
            <div key={i} className="flex items-center gap-4 px-2 py-4">
              <Skeleton className="size-10 rounded-lg" />
              <div className="flex-1 space-y-1.5">
                <Skeleton className="h-3.5 w-2/3" />
                <Skeleton className="h-3 w-1/3" />
              </div>
            </div>
          ))}
        </div>
      ) : rows.length === 0 ? (
        <p className="text-sm text-muted-foreground">No events yet.</p>
      ) : (
        <>
          <Section label="Upcoming" rows={upcoming} />
          <Section label="Past" rows={past} />
        </>
      )}
    </div>
  );
}
