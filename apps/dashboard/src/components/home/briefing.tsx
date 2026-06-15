"use client";

import Link from "next/link";
import { FileText } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { useCohort } from "@/app/providers";
import { useDash } from "@/hooks/use-dash";

type Briefing = {
  members: number;
  connections: number;
  pctConnected: number;
  deeplyEngaged: number;
  newConnectionsThisWeek: number;
  crossDiscipline: number;
};

function verdictWord(pct: number) {
  return pct >= 70 ? "healthy" : pct >= 40 ? "taking shape" : "just getting started";
}

export function Briefing() {
  const { cohort } = useCohort();
  const where = cohort === "All" ? "the Center" : cohort;
  const d = useDash<Briefing>("center:briefing");

  const lead =
    d &&
    (d.crossDiscipline > 0
      ? `${d.crossDiscipline} of ${d.connections} connections bridge different disciplines.`
      : `${d.members} students have made ${d.connections} connections.`);

  return (
    <div className="flex flex-col gap-5 sm:flex-row sm:items-start sm:justify-between sm:gap-10">
      <div className="flex flex-col gap-2.5">
        <p className="text-sm text-muted-foreground">This week at {where}</p>

        {d ? (
          <>
            <h2 className="max-w-2xl text-balance text-2xl leading-snug font-semibold tracking-tight sm:text-[1.7rem]">
              Your ecosystem is {verdictWord(d.pctConnected)}. {lead}
            </h2>
            <p className="text-sm tabular-nums text-muted-foreground">
              {d.members} students · {d.pctConnected}% connected · {d.deeplyEngaged} with 3+ connections
              {d.newConnectionsThisWeek > 0 ? ` · ${d.newConnectionsThisWeek} new this week` : ""}
            </p>
          </>
        ) : (
          <div className="flex flex-col gap-2.5">
            <Skeleton className="h-7 w-[34rem] max-w-full" />
            <Skeleton className="h-7 w-[22rem] max-w-full" />
            <Skeleton className="h-4 w-80 max-w-full" />
          </div>
        )}

        <p className="text-sm text-muted-foreground">
          Built live from what students do. Every number traces to its source.
        </p>
      </div>

      <Button render={<Link href="/report" />} className="h-10 shrink-0 gap-2 rounded-full px-5">
        <FileText className="size-4" />
        Make report
      </Button>
    </div>
  );
}
