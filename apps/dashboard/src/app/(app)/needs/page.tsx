"use client";

import { useState } from "react";
import { ChevronRight } from "lucide-react";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Skeleton } from "@/components/ui/skeleton";
import { useDash } from "@/hooks/use-dash";
import { ago, initials } from "@/lib/format";

type Status = "open" | "matched" | "resolved";
type Row = { id: string; text: string; category: string; status: Status; userName: string; userAvatar: string | null; createdAt: number };
type Data = { rows: Row[]; counts: Record<Status, number>; topCategories: { category: string; count: number }[] };

const FILTERS = ["all", "open", "matched", "resolved"] as const;
type Filter = (typeof FILTERS)[number];

export default function NeedsPage() {
  const data = useDash<Data>("center:needsList");
  const [filter, setFilter] = useState<Filter>("open");

  const rows = data?.rows.filter((r) => filter === "all" || r.status === filter) ?? [];

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-col gap-5">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Needs</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          What students are asking for, captured from Ask Junto. Tap one to find who can help.
        </p>
      </div>

      {data && data.topCategories.length > 0 && (
        <div className="flex flex-wrap gap-2">
          {data.topCategories.map((c) => (
            <span
              key={c.category}
              className="inline-flex items-center gap-1.5 rounded-xl border border-border px-2.5 py-1 text-xs"
            >
              <span className="capitalize">{c.category}</span>
              <span className="tabular-nums text-muted-foreground">{c.count}</span>
            </span>
          ))}
        </div>
      )}

      <Tabs value={filter} onValueChange={(v) => setFilter(v as Filter)}>
        <TabsList>
          <TabsTrigger value="all">All</TabsTrigger>
          <TabsTrigger value="open">Open {data ? data.counts.open : ""}</TabsTrigger>
          <TabsTrigger value="matched">Matched {data ? data.counts.matched : ""}</TabsTrigger>
          <TabsTrigger value="resolved">Resolved {data ? data.counts.resolved : ""}</TabsTrigger>
        </TabsList>
      </Tabs>

      <div className="-mx-2 divide-y divide-border">
        {!data ? (
          Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="flex items-center gap-3 px-2 py-3.5">
              <Skeleton className="h-5 w-14 rounded-full" />
              <div className="flex-1 space-y-1.5">
                <Skeleton className="h-3.5 w-3/4" />
                <Skeleton className="h-3 w-1/3" />
              </div>
            </div>
          ))
        ) : rows.length === 0 ? (
          <p className="px-2 py-8 text-sm text-muted-foreground">No {filter === "all" ? "" : filter} asks right now.</p>
        ) : (
          rows.map((r) => (
            <button key={r.id} className="group flex w-full items-center gap-3 px-2 py-3.5 text-left transition-colors hover:bg-muted/50">
              <Badge variant={r.status} className="shrink-0 capitalize">{r.status}</Badge>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium">{r.text}</p>
                <p className="flex items-center gap-1.5 truncate text-xs text-muted-foreground">
                  <Avatar size="sm" className="size-4">
                    {r.userAvatar && <AvatarImage src={r.userAvatar} />}
                    <AvatarFallback className="text-[8px]">{initials(r.userName)}</AvatarFallback>
                  </Avatar>
                  {r.userName} · <span className="capitalize">{r.category}</span> · {ago(r.createdAt)}
                </p>
              </div>
              <ChevronRight className="size-4 shrink-0 text-muted-foreground/40 transition-colors group-hover:text-muted-foreground" />
            </button>
          ))
        )}
      </div>
    </div>
  );
}
