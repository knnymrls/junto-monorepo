"use client";

import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { useConvexQuery } from "@/hooks/use-convex-query";

type CategoryData = {
  category: string;
  makers: number;
  supply: number;
  demand: number;
  gap: number;
  avgConnections: number;
};

type MatchExample = {
  needsName: string;
  needsAvatar: string | null;
  offersName: string;
  offersAvatar: string | null;
  category: string;
};

type SkillsEcosystemData = {
  categories: CategoryData[];
  gaps: CategoryData[];
  potentialMatches: number;
  matchExamples: MatchExample[];
  connectionDrivers: CategoryData[];
  topRawSkills: { skill: string; count: number }[];
  avgDiversity: number;
  totalMakers: number;
};

function cap(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

function getInitials(name: string) {
  return name.split(" ").map((n) => n[0]).join("").slice(0, 2).toUpperCase();
}

function Avatar({ url, name }: { url: string | null; name: string }) {
  if (url) {
    return (
      <img
        src={url}
        alt={name}
        className="h-6 w-6 rounded-full object-cover"
      />
    );
  }
  return (
    <div className="flex h-6 w-6 items-center justify-center rounded-full bg-primary/10 text-[10px] font-semibold text-primary">
      {getInitials(name)}
    </div>
  );
}

const CATEGORY_COLORS: Record<string, string> = {
  Technology: "bg-blue-500",
  Business: "bg-amber-500",
  Design: "bg-violet-500",
  Creative: "bg-emerald-500",
};

const CATEGORY_TEXT: Record<string, string> = {
  Technology: "text-blue-600",
  Business: "text-amber-600",
  Design: "text-violet-600",
  Creative: "text-emerald-600",
};

const CATEGORY_BG: Record<string, string> = {
  Technology: "bg-blue-500/10",
  Business: "bg-amber-500/10",
  Design: "bg-violet-500/10",
  Creative: "bg-emerald-500/10",
};

export default function SkillsPage() {
  const { data, loading } =
    useConvexQuery<SkillsEcosystemData>("dashboard:skillsEcosystem");

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <p className="text-sm text-muted-foreground">Loading...</p>
      </div>
    );
  }

  const d = data!;

  const biggestGap = d.gaps.length > 0 ? d.gaps[0] : null;
  const topDriver =
    d.connectionDrivers.length > 0 ? d.connectionDrivers[0] : null;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h2 className="text-2xl font-bold tracking-tight">
          Skills Ecosystem
        </h2>
        <p className="mt-1 text-sm text-muted-foreground">
          AI-categorized skills supply and demand across your student community
        </p>
      </div>

      {/* ── HEADLINE STATS ── */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardContent className="pt-5 pb-4">
            <p className="text-xs text-muted-foreground">Skill Diversity</p>
            <p className="mt-1 text-3xl font-bold tabular-nums">
              {d.avgDiversity}
            </p>
            <p className="mt-0.5 text-xs text-muted-foreground">
              avg categories per student
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-5 pb-4">
            <p className="text-xs text-muted-foreground">Biggest Gap</p>
            {biggestGap ? (
              <>
                <p
                  className={`mt-1 text-2xl font-bold ${CATEGORY_TEXT[biggestGap.category] ?? ""}`}
                >
                  {biggestGap.category}
                </p>
                <p className="mt-0.5 text-xs text-muted-foreground">
                  {biggestGap.demand} need it, {biggestGap.supply} offer it
                </p>
              </>
            ) : (
              <>
                <p className="mt-1 text-2xl font-bold">None</p>
                <p className="mt-0.5 text-xs text-muted-foreground">
                  Supply meets demand
                </p>
              </>
            )}
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-5 pb-4">
            <p className="text-xs text-muted-foreground">Potential Matches</p>
            <p className="mt-1 text-3xl font-bold tabular-nums">
              {d.potentialMatches}
            </p>
            <p className="mt-0.5 text-xs text-muted-foreground">
              complementary pairs not yet connected
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-5 pb-4">
            <p className="text-xs text-muted-foreground">Most Connected</p>
            {topDriver ? (
              <>
                <p
                  className={`mt-1 text-2xl font-bold ${CATEGORY_TEXT[topDriver.category] ?? ""}`}
                >
                  {topDriver.category}
                </p>
                <p className="mt-0.5 text-xs text-muted-foreground">
                  {topDriver.avgConnections} connections/student avg
                </p>
              </>
            ) : (
              <>
                <p className="mt-1 text-2xl font-bold">---</p>
                <p className="mt-0.5 text-xs text-muted-foreground">
                  No data yet
                </p>
              </>
            )}
          </CardContent>
        </Card>
      </div>

      {/* ── ECOSYSTEM MAP ── */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">
            Supply vs Demand by Category
          </CardTitle>
          <CardDescription>
            Where your ecosystem has surplus talent and where it needs more
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {d.categories.map((cat) => {
              const maxVal = Math.max(
                ...d.categories.map((c) => Math.max(c.supply, c.demand)),
                1
              );
              const supplyPct = Math.max(
                Math.round((cat.supply / maxVal) * 100),
                2
              );
              const demandPct = Math.max(
                Math.round((cat.demand / maxVal) * 100),
                2
              );
              const color = CATEGORY_COLORS[cat.category] ?? "bg-gray-500";
              const hasGap = cat.gap > 0;
              const hasSurplus = cat.gap < 0;

              return (
                <div key={cat.category} className="space-y-1.5">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-medium">
                        {cat.category}
                      </span>
                      <span className="text-xs text-muted-foreground">
                        {cat.makers} students
                      </span>
                    </div>
                    {hasGap && (
                      <Badge
                        variant="secondary"
                        className="bg-destructive/10 text-destructive text-xs"
                      >
                        Gap: {cat.gap} more needed
                      </Badge>
                    )}
                    {hasSurplus && (
                      <Badge
                        variant="secondary"
                        className="bg-emerald-500/10 text-emerald-600 text-xs"
                      >
                        Surplus
                      </Badge>
                    )}
                  </div>
                  <div className="grid grid-cols-2 gap-2">
                    <div>
                      <div className="flex items-center justify-between text-xs text-muted-foreground mb-0.5">
                        <span>Supply</span>
                        <span className="tabular-nums">{cat.supply}</span>
                      </div>
                      <div className="h-2 w-full rounded-full bg-muted">
                        <div
                          className={`h-2 rounded-full ${color}`}
                          style={{ width: `${supplyPct}%` }}
                        />
                      </div>
                    </div>
                    <div>
                      <div className="flex items-center justify-between text-xs text-muted-foreground mb-0.5">
                        <span>Demand</span>
                        <span className="tabular-nums">{cat.demand}</span>
                      </div>
                      <div className="h-2 w-full rounded-full bg-muted">
                        <div
                          className="h-2 rounded-full bg-muted-foreground/30"
                          style={{ width: `${demandPct}%` }}
                        />
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* ── GAPS → ACTIONS ── */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-base">Skill Gaps</CardTitle>
            <CardDescription>
              Where demand exceeds supply — each gap is a workshop opportunity
            </CardDescription>
          </CardHeader>
          <CardContent>
            {d.gaps.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                No gaps — supply meets demand across all categories
              </p>
            ) : (
              <div className="space-y-3">
                {d.gaps.map((gap) => {
                  const suggestions: Record<string, string> = {
                    Technology:
                      "Host a hackathon or invite dev mentors",
                    Business:
                      "Run a pitch workshop or invite business advisors",
                    Design:
                      "Host a design sprint or recruit design students",
                    Creative:
                      "Start a content workshop or invite creators",
                  };
                  return (
                    <div
                      key={gap.category}
                      className="rounded-lg border border-border p-3 space-y-1"
                    >
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <div
                            className={`h-2.5 w-2.5 rounded-full ${CATEGORY_COLORS[gap.category] ?? "bg-gray-500"}`}
                          />
                          <span className="text-sm font-medium">
                            {gap.category}
                          </span>
                        </div>
                        <span className="text-xs text-muted-foreground tabular-nums">
                          {gap.demand} need &middot; {gap.supply} offer
                        </span>
                      </div>
                      <p className="text-xs text-muted-foreground pl-[18px]">
                        {suggestions[gap.category] ??
                          "Consider hosting a workshop"}
                      </p>
                    </div>
                  );
                })}
              </div>
            )}
          </CardContent>
        </Card>

        {/* ── POTENTIAL MATCHES ── */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-base">Potential Matches</CardTitle>
            <CardDescription>
              Students with complementary skills who aren&apos;t connected yet
            </CardDescription>
          </CardHeader>
          <CardContent>
            {d.potentialMatches === 0 ? (
              <p className="text-sm text-muted-foreground">
                No unconnected complementary pairs found
              </p>
            ) : (
              <div className="space-y-3">
                <p className="text-sm text-muted-foreground">
                  <span className="font-semibold text-foreground">
                    {d.potentialMatches}
                  </span>{" "}
                  students have complementary skills and aren&apos;t connected
                  yet. The AI matching engine can surface these automatically.
                </p>
                {d.matchExamples.length > 0 && (
                  <div className="space-y-2">
                    <p className="text-[11px] font-medium uppercase tracking-wider text-muted-foreground">
                      Examples
                    </p>
                    {d.matchExamples.map((m, i) => (
                      <div
                        key={i}
                        className="flex items-center gap-2 text-sm"
                      >
                        <Avatar url={m.needsAvatar} name={m.needsName} />
                        <span className="truncate">{m.needsName}</span>
                        <span className="text-xs text-muted-foreground shrink-0">
                          needs
                        </span>
                        <Badge
                          variant="secondary"
                          className={`${CATEGORY_BG[m.category] ?? ""} ${CATEGORY_TEXT[m.category] ?? ""} text-xs shrink-0`}
                        >
                          {m.category}
                        </Badge>
                        <span className="text-xs text-muted-foreground shrink-0">
                          &larr;
                        </span>
                        <Avatar url={m.offersAvatar} name={m.offersName} />
                        <span className="truncate">{m.offersName}</span>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* ── CONNECTION DRIVERS + TOP SKILLS ── */}
      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-base">
              Skills That Drive Connections
            </CardTitle>
            <CardDescription>
              Which skill areas correlate with more connections?
            </CardDescription>
          </CardHeader>
          <CardContent>
            {d.connectionDrivers.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                Not enough data yet
              </p>
            ) : (
              <div className="space-y-2.5">
                {d.connectionDrivers.map((cat) => {
                  const maxAvg = d.connectionDrivers[0]?.avgConnections ?? 1;
                  const pct =
                    maxAvg > 0
                      ? Math.max(
                          Math.round((cat.avgConnections / maxAvg) * 100),
                          5
                        )
                      : 5;
                  return (
                    <div key={cat.category}>
                      <div className="flex items-center justify-between text-sm mb-0.5">
                        <span>{cat.category}</span>
                        <span className="text-muted-foreground tabular-nums">
                          {cat.avgConnections} avg
                        </span>
                      </div>
                      <div className="h-2 w-full rounded-full bg-muted">
                        <div
                          className={`h-2 rounded-full ${CATEGORY_COLORS[cat.category] ?? "bg-gray-500"}`}
                          style={{ width: `${pct}%` }}
                        />
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-base">Top Skills Listed</CardTitle>
            <CardDescription>
              Most common skills across all student profiles
            </CardDescription>
          </CardHeader>
          <CardContent>
            {d.topRawSkills.length === 0 ? (
              <p className="text-sm text-muted-foreground">No skills yet</p>
            ) : (
              <div className="flex flex-wrap gap-1.5">
                {d.topRawSkills.map((s) => (
                  <Badge
                    key={s.skill}
                    variant="secondary"
                    className="text-xs"
                  >
                    {cap(s.skill)}
                    {s.count > 1 && (
                      <span className="ml-1 text-muted-foreground">
                        {s.count}
                      </span>
                    )}
                  </Badge>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
