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

type IntelligenceData = {
  funnel: {
    totalSignups: number;
    onboarded: number;
    hasPosted: number;
    hasConnected: number;
    deeplyEngaged: number;
  };
  searchDemand: {
    totalSearches: number;
    unmatchedCount: number;
    unmatchedRate: number;
    unmatchedQueries: { query: string; count: number }[];
    topSearches: { query: string; count: number; avgResults: number }[];
  };
  eventImpact: {
    totalEvents: number;
    totalAttendees: number;
    totalPostEventConnections: number;
    totalPostEventDMs: number;
    bestEvent: {
      title: string;
      connectionRate: number;
      connections: number;
    } | null;
    wantToConnectFulfillment: number;
    totalWants: number;
    fulfilledWants: number;
  };
  network: {
    totalConnections: number;
    crossClusterCount: number;
    crossClusterRate: number;
    crossClusterPairs: { pair: string; count: number }[];
    bridgeNodes: {
      name: string;
      avatar: string | null;
      clustersConnected: string[];
      connectionCount: number;
    }[];
  };
  projects: {
    activeProjectCount: number;
    portfolioItemCount: number;
    portfolioByType: { type: string; count: number }[];
  };
  content: {
    total: number;
    asking: number;
    sharing: number;
    lookingFor: number;
    totalComments: number;
    avgCommentsPerPost: number;
  };
};

function getInitials(name: string) {
  return name.split(" ").map((n) => n[0]).join("").slice(0, 2).toUpperCase();
}

function Avatar({ url, name }: { url: string | null; name: string }) {
  if (url) {
    return (
      <img
        src={url}
        alt={name}
        className="h-7 w-7 rounded-full object-cover"
      />
    );
  }
  return (
    <div className="flex h-7 w-7 items-center justify-center rounded-full bg-primary/10 text-[10px] font-semibold text-primary">
      {getInitials(name)}
    </div>
  );
}

export default function IntelligencePage() {
  const { data, loading } =
    useConvexQuery<IntelligenceData>("dashboard:intelligenceHub");

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <p className="text-sm text-muted-foreground">
          Loading intelligence...
        </p>
      </div>
    );
  }

  const d = data!;

  const funnelSteps = [
    { label: "Signed Up", value: d.funnel.totalSignups, base: 0 },
    { label: "Onboarded", value: d.funnel.onboarded, base: d.funnel.totalSignups },
    { label: "First Post", value: d.funnel.hasPosted, base: d.funnel.onboarded },
    { label: "First Connection", value: d.funnel.hasConnected, base: d.funnel.onboarded },
    { label: "3+ Connections", value: d.funnel.deeplyEngaged, base: d.funnel.onboarded },
  ];

  const hasSearchData =
    d.searchDemand.unmatchedQueries.length > 0 ||
    d.searchDemand.topSearches.length > 0;
  const hasEventData =
    d.eventImpact.totalPostEventConnections > 0 ||
    d.eventImpact.totalPostEventDMs > 0 ||
    (d.eventImpact.bestEvent !== null && d.eventImpact.bestEvent.connections > 0);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <div className="flex items-center gap-2">
          <h2 className="text-2xl font-bold tracking-tight">Intelligence</h2>
          <Badge className="bg-violet-500/10 text-violet-600 hover:bg-violet-500/10 border-0">
            Live
          </Badge>
        </div>
        <p className="mt-1 text-sm text-muted-foreground">
          Real-time behavioral data from student activity on the platform
        </p>
      </div>

      {/* ── HEADLINE STATS ── */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardContent className="pt-5 pb-4">
            <p className="text-xs text-muted-foreground">
              Cross-Area Connections
            </p>
            <p className="mt-1 text-3xl font-bold tabular-nums">
              {d.network.crossClusterCount}
            </p>
            <p className="mt-0.5 text-xs text-muted-foreground">
              {d.network.crossClusterRate}% of all connections
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-5 pb-4">
            <p className="text-xs text-muted-foreground">
              Post-Event Connections
            </p>
            <p className="mt-1 text-3xl font-bold tabular-nums">
              {d.eventImpact.totalPostEventConnections}
            </p>
            <p className="mt-0.5 text-xs text-muted-foreground">
              Within 48h of an event
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-5 pb-4">
            <p className="text-xs text-muted-foreground">Active Projects</p>
            <p className="mt-1 text-3xl font-bold tabular-nums">
              {d.projects.activeProjectCount}
            </p>
            <p className="mt-0.5 text-xs text-muted-foreground">
              Students building right now
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-5 pb-4">
            <p className="text-xs text-muted-foreground">Community Posts</p>
            <p className="mt-1 text-3xl font-bold tabular-nums">
              {d.content.total}
            </p>
            <p className="mt-0.5 text-xs text-muted-foreground">
              {d.content.avgCommentsPerPost} comments/post avg
            </p>
          </CardContent>
        </Card>
      </div>

      {/* ── INNOVATION FUNNEL ── */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Innovation Funnel</CardTitle>
          <CardDescription>
            Signup to deeply engaged builder
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-2.5">
            {funnelSteps.map((step, i) => {
              const widthPct =
                d.funnel.totalSignups > 0
                  ? Math.max(
                      Math.round(
                        (step.value / d.funnel.totalSignups) * 100
                      ),
                      3
                    )
                  : 3;
              const colors = [
                "bg-violet-500",
                "bg-violet-400",
                "bg-blue-500",
                "bg-blue-400",
                "bg-emerald-500",
              ];
              const convRate =
                i > 0 && step.base > 0
                  ? Math.round((step.value / step.base) * 100)
                  : null;
              return (
                <div key={step.label}>
                  <div className="flex items-center justify-between text-sm mb-1">
                    <span>{step.label}</span>
                    <span className="tabular-nums font-medium">
                      {step.value}
                      {convRate !== null && (
                        <span className="ml-1.5 text-xs text-muted-foreground font-normal">
                          {convRate}%
                        </span>
                      )}
                    </span>
                  </div>
                  <div className="h-2.5 w-full rounded-full bg-muted">
                    <div
                      className={`h-2.5 rounded-full ${colors[i]}`}
                      style={{ width: `${widthPct}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>

      {/* ── EVENT IMPACT + CROSS-AREA (side by side) ── */}
      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-base">Event Impact</CardTitle>
            <CardDescription>
              Post-event outcomes within 48 hours
            </CardDescription>
          </CardHeader>
          <CardContent>
            {hasEventData ? (
              <div className="space-y-4">
                <div className="grid grid-cols-3 gap-4">
                  <div>
                    <p className="text-2xl font-bold tabular-nums">
                      {d.eventImpact.totalPostEventConnections}
                    </p>
                    <p className="text-xs text-muted-foreground">Connections</p>
                  </div>
                  <div>
                    <p className="text-2xl font-bold tabular-nums">
                      {d.eventImpact.totalPostEventDMs}
                    </p>
                    <p className="text-xs text-muted-foreground">DMs started</p>
                  </div>
                  <div>
                    <p className="text-2xl font-bold tabular-nums">
                      {d.eventImpact.wantToConnectFulfillment}%
                    </p>
                    <p className="text-xs text-muted-foreground">
                      Intent fulfilled
                    </p>
                  </div>
                </div>
                {d.eventImpact.bestEvent &&
                  d.eventImpact.bestEvent.connections > 0 && (
                    <div className="rounded-lg bg-muted/50 px-3 py-2">
                      <p className="text-xs text-muted-foreground">
                        Top event
                      </p>
                      <p className="text-sm font-medium truncate">
                        {d.eventImpact.bestEvent.title}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {d.eventImpact.bestEvent.connectionRate}% connection
                        rate
                      </p>
                    </div>
                  )}
              </div>
            ) : (
              <div className="space-y-2">
                <p className="text-sm text-muted-foreground">
                  {d.eventImpact.totalEvents > 0
                    ? `${d.eventImpact.totalEvents} event${d.eventImpact.totalEvents !== 1 ? "s" : ""} hosted — post-event connection data will build over time`
                    : "Event impact data will appear after your first event"}
                </p>
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-base">Cross-Area Connections</CardTitle>
            <CardDescription>
              Connections spanning different skill areas
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              <div className="flex items-baseline gap-2">
                <span className="text-3xl font-bold tabular-nums">
                  {d.network.crossClusterCount}
                </span>
                <span className="text-sm text-muted-foreground">
                  of {d.network.totalConnections} ({d.network.crossClusterRate}%)
                </span>
              </div>
              {d.network.crossClusterPairs.length > 0 && (
                <div className="space-y-1.5">
                  {d.network.crossClusterPairs.map((p, i) => (
                    <div
                      key={i}
                      className="flex items-center justify-between text-sm"
                    >
                      <span className="text-muted-foreground">{p.pair}</span>
                      <span className="font-medium tabular-nums">{p.count}</span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* ── BRIDGE MAKERS + DEMAND SIGNALS (side by side) ── */}
      <div className="grid gap-6 lg:grid-cols-2">
        {/* Bridge Makers */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-base">Bridge Makers</CardTitle>
            <CardDescription>
              Students connecting different skill communities
            </CardDescription>
          </CardHeader>
          <CardContent>
            {d.network.bridgeNodes.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                No bridge makers identified yet
              </p>
            ) : (
              <div className="space-y-2">
                {d.network.bridgeNodes.slice(0, 3).map((node, i) => (
                  <div key={i} className="flex items-center gap-2.5">
                    <Avatar url={node.avatar} name={node.name} />
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-medium leading-tight">
                        {node.name}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {node.connectionCount} connections &middot;{" "}
                        {node.clustersConnected.join(", ")}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Demand Signals */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-base">Demand Signals</CardTitle>
            <CardDescription>
              What students are searching for via AI
            </CardDescription>
          </CardHeader>
          <CardContent>
            {!hasSearchData ? (
              <p className="text-sm text-muted-foreground">
                Signals appear as students use AI search
              </p>
            ) : (
              <div className="space-y-3">
                {d.searchDemand.unmatchedQueries.length > 0 && (
                  <div className="space-y-1.5">
                    <p className="text-[11px] font-medium uppercase tracking-wider text-muted-foreground">
                      Unmet Needs
                    </p>
                    {d.searchDemand.unmatchedQueries
                      .slice(0, 3)
                      .map((q, i) => (
                        <div
                          key={i}
                          className="flex items-center justify-between rounded bg-destructive/5 px-2.5 py-1.5 text-sm"
                        >
                          <span className="truncate">
                            &ldquo;{q.query}&rdquo;
                          </span>
                          <span className="text-xs text-muted-foreground shrink-0 ml-2">
                            {q.count}x
                          </span>
                        </div>
                      ))}
                  </div>
                )}
                {d.searchDemand.topSearches.length > 0 && (
                  <div className="space-y-1.5">
                    <p className="text-[11px] font-medium uppercase tracking-wider text-muted-foreground">
                      Top Searches
                    </p>
                    {d.searchDemand.topSearches.slice(0, 3).map((q, i) => (
                      <div
                        key={i}
                        className="flex items-center justify-between text-sm"
                      >
                        <span className="truncate text-muted-foreground">
                          &ldquo;{q.query}&rdquo;
                        </span>
                        <span className="text-xs text-muted-foreground shrink-0 ml-2">
                          {q.avgResults} results
                        </span>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* ── BOTTOM: Content breakdown ── */}
      <Card>
        <CardContent className="pt-5 pb-4">
          <p className="text-[11px] font-medium uppercase tracking-wider text-muted-foreground mb-3">
            Post Breakdown
          </p>
          <div className="grid grid-cols-3 gap-4">
            <div>
              <p className="text-2xl font-bold tabular-nums text-blue-600">
                {d.content.asking}
              </p>
              <p className="text-xs text-muted-foreground">Asking for Help</p>
            </div>
            <div>
              <p className="text-2xl font-bold tabular-nums text-emerald-600">
                {d.content.sharing}
              </p>
              <p className="text-xs text-muted-foreground">Sharing Work</p>
            </div>
            <div>
              <p className="text-2xl font-bold tabular-nums text-amber-600">
                {d.content.lookingFor}
              </p>
              <p className="text-xs text-muted-foreground">Looking For</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
