"use client";

import Link from "next/link";
import { ChevronRight } from "lucide-react";
import { Avatar, AvatarFallback, AvatarGroup, AvatarImage } from "@/components/ui/avatar";
import { Skeleton } from "@/components/ui/skeleton";
import { useDash } from "@/hooks/use-dash";

type Feed =
  | { kind: "connection"; ts: number; source: string; aName: string; aAvatar: string | null; bName: string; bAvatar: string | null }
  | { kind: "join" | "post" | "rsvp"; ts: number; source: string; title: string; aName: string; aAvatar: string | null };

function initials(name: string) {
  return name.split(" ").map((w) => w[0]).slice(0, 2).join("").toUpperCase();
}

function ago(ts: number) {
  const s = (Date.now() - ts) / 1000;
  if (s < 60) return "now";
  const m = s / 60;
  if (m < 60) return `${Math.floor(m)}m`;
  const h = m / 60;
  if (h < 24) return `${Math.floor(h)}h`;
  const d = h / 24;
  if (d < 7) return `${Math.floor(d)}d`;
  const w = d / 7;
  if (w < 5) return `${Math.floor(w)}w`;
  return `${Math.floor(d / 30)}mo`;
}

const rowClass =
  "group flex w-full items-center gap-3 px-2 py-3.5 text-left transition-colors hover:bg-muted/50";

// Drill to the surface that holds the source of each event.
function hrefFor(ev: Feed) {
  if (ev.kind === "post") return "/needs";
  if (ev.kind === "rsvp") return "/events";
  return "/map"; // connection / join — see it in the graph
}

export function ActivityFeed() {
  const items = useDash<Feed[]>("center:activity");

  return (
    <section className="flex flex-col gap-3">
      <div className="flex items-baseline justify-between">
        <h3 className="text-sm font-medium">What happened</h3>
        <span className="text-xs text-muted-foreground">live</span>
      </div>

      <div className="-mx-2 divide-y divide-border">
        {!items ? (
          Array.from({ length: 5 }).map((_, i) => (
            <div key={i} className="flex items-center gap-3 px-2 py-3.5">
              <Skeleton className="size-7 rounded-full" />
              <div className="flex-1 space-y-1.5">
                <Skeleton className="h-3.5 w-2/3" />
                <Skeleton className="h-3 w-1/3" />
              </div>
            </div>
          ))
        ) : items.length === 0 ? (
          <p className="px-2 py-8 text-sm text-muted-foreground">
            No activity yet. It shows up here as students connect, post, and RSVP.
          </p>
        ) : (
          items.map((ev, i) =>
            ev.kind === "connection" ? (
              <Link key={i} href={hrefFor(ev)} className={rowClass}>
                <AvatarGroup data-size="sm">
                  <Avatar size="sm">
                    {ev.aAvatar && <AvatarImage src={ev.aAvatar} />}
                    <AvatarFallback>{initials(ev.aName)}</AvatarFallback>
                  </Avatar>
                  <Avatar size="sm">
                    {ev.bAvatar && <AvatarImage src={ev.bAvatar} />}
                    <AvatarFallback>{initials(ev.bName)}</AvatarFallback>
                  </Avatar>
                </AvatarGroup>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-medium">
                    {ev.aName} {"↔"} {ev.bName}
                  </p>
                  <p className="truncate text-xs text-muted-foreground">
                    {ev.source} · {ago(ev.ts)}
                  </p>
                </div>
                <ChevronRight className="size-4 shrink-0 text-muted-foreground/40 transition-colors group-hover:text-muted-foreground" />
              </Link>
            ) : (
              <Link key={i} href={hrefFor(ev)} className={rowClass}>
                <Avatar size="sm">
                  {ev.aAvatar && <AvatarImage src={ev.aAvatar} />}
                  <AvatarFallback>{initials(ev.aName)}</AvatarFallback>
                </Avatar>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-medium">{ev.title}</p>
                  <p className="truncate text-xs text-muted-foreground">
                    {ev.source} · {ago(ev.ts)}
                  </p>
                </div>
                <ChevronRight className="size-4 shrink-0 text-muted-foreground/40 transition-colors group-hover:text-muted-foreground" />
              </Link>
            )
          )
        )}
      </div>
    </section>
  );
}
