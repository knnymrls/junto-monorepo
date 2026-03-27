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

type ConnectionStats = {
  total: number;
  newThisWeek: number;
  avgConnectionsPerMember: number;
  percentWithConnection: number;
  recentConnections: {
    id: string;
    requesterName: string;
    requesterAvatar: string | null;
    accepterName: string;
    accepterAvatar: string | null;
    connectedAt: number;
  }[];
};

function timeAgo(ts: number): string {
  const diff = Date.now() - ts;
  const mins = Math.floor(diff / 60000);
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}

function getInitials(name: string) {
  return name
    .split(" ")
    .map((n) => n[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();
}

function Avatar({ url, name }: { url: string | null; name: string }) {
  if (url) {
    return (
      <img
        src={url}
        alt={name}
        className="h-8 w-8 rounded-full object-cover"
      />
    );
  }
  return (
    <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary/10 text-xs font-semibold text-primary">
      {getInitials(name)}
    </div>
  );
}

export default function ConnectionsPage() {
  const { data, loading } =
    useConvexQuery<ConnectionStats>("dashboard:connectionStats");

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <p className="text-sm text-muted-foreground">Loading...</p>
      </div>
    );
  }

  const stats = data!;

  const densityLabel =
    stats.percentWithConnection >= 80
      ? "Strong"
      : stats.percentWithConnection >= 50
        ? "Growing"
        : "Early";

  return (
    <div className="space-y-8">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">Connections</h2>
        <p className="mt-1 text-sm text-muted-foreground">
          Network density and relationship formation — proof that makers are
          finding each other
        </p>
      </div>

      {/* Metrics */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Total Connections</CardDescription>
          </CardHeader>
          <CardContent>
            <span className="text-3xl font-bold tabular-nums">
              {stats.total}
            </span>
            <p className="mt-1 text-xs text-muted-foreground">
              Maker-to-maker links
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>New This Week</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex items-baseline gap-2">
              <span className="text-3xl font-bold tabular-nums">
                {stats.newThisWeek}
              </span>
              {stats.newThisWeek > 0 && (
                <Badge
                  variant="secondary"
                  className="bg-emerald-500/10 text-emerald-600 hover:bg-emerald-500/10"
                >
                  +{stats.newThisWeek}
                </Badge>
              )}
            </div>
            <p className="mt-1 text-xs text-muted-foreground">
              New relationships formed
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Avg per Maker</CardDescription>
          </CardHeader>
          <CardContent>
            <span className="text-3xl font-bold tabular-nums">
              {stats.avgConnectionsPerMember}
            </span>
            <p className="mt-1 text-xs text-muted-foreground">
              Connections per member
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Connection Rate</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex items-baseline gap-2">
              <span className="text-3xl font-bold tabular-nums">
                {stats.percentWithConnection}%
              </span>
              <Badge
                variant="secondary"
                className={
                  stats.percentWithConnection >= 80
                    ? "bg-emerald-500/10 text-emerald-600 hover:bg-emerald-500/10"
                    : stats.percentWithConnection >= 50
                      ? "bg-amber-500/10 text-amber-600 hover:bg-amber-500/10"
                      : "bg-red-500/10 text-red-600 hover:bg-red-500/10"
                }
              >
                {densityLabel}
              </Badge>
            </div>
            <p className="mt-1 text-xs text-muted-foreground">
              Members with 1+ connection
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Network Health */}
      <Card>
        <CardHeader>
          <CardTitle>Network Health</CardTitle>
          <CardDescription>
            How well the community is connecting
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            <div className="flex items-center justify-between text-sm">
              <span>Connection coverage</span>
              <span className="font-semibold tabular-nums">
                {stats.percentWithConnection}%
              </span>
            </div>
            <div className="h-3 w-full rounded-full bg-muted">
              <div
                className={`h-3 rounded-full transition-all ${
                  stats.percentWithConnection >= 80
                    ? "bg-emerald-500"
                    : stats.percentWithConnection >= 50
                      ? "bg-amber-500"
                      : "bg-red-400"
                }`}
                style={{
                  width: `${Math.min(stats.percentWithConnection, 100)}%`,
                }}
              />
            </div>
            <p className="text-xs text-muted-foreground">
              {stats.percentWithConnection >= 80
                ? "Excellent — most makers have found someone to connect with."
                : stats.percentWithConnection >= 50
                  ? "Growing — over half are connected. Events and prompts can push this higher."
                  : "Early stage — most members haven't connected yet. Consider ice-breaker events or suggested matches."}
            </p>
          </div>
        </CardContent>
      </Card>

      {/* Recent connections */}
      <Card>
        <CardHeader>
          <CardTitle>Recent Connections</CardTitle>
          <CardDescription>
            Latest relationships formed in the community
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {stats.recentConnections.map((conn) => (
              <div
                key={conn.id}
                className="flex items-center justify-between py-2 border-b border-border last:border-0"
              >
                <div className="flex items-center gap-3">
                  <Avatar
                    url={conn.requesterAvatar}
                    name={conn.requesterName}
                  />
                  <span className="text-sm font-medium">
                    {conn.requesterName}
                  </span>
                  <span className="text-xs text-muted-foreground">
                    connected with
                  </span>
                  <Avatar
                    url={conn.accepterAvatar}
                    name={conn.accepterName}
                  />
                  <span className="text-sm font-medium">
                    {conn.accepterName}
                  </span>
                </div>
                <span className="text-xs text-muted-foreground shrink-0">
                  {timeAgo(conn.connectedAt)}
                </span>
              </div>
            ))}
            {stats.recentConnections.length === 0 && (
              <p className="text-sm text-muted-foreground">
                No connections yet
              </p>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
