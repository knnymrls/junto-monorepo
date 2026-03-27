"use client";

import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  ComposedChart,
  Area,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { useConvexQuery } from "@/hooks/use-convex-query";

type OverviewData = {
  totalMembers: { value: number; change: number };
  activeUsers: { value: number; change: number };
  totalConnections: { value: number; change: number };
  postsThisWeek: { value: number; change: number };
};

type GrowthData = { week: string; count: number; cumulative: number }[];

type CommunityData = {
  postsPerWeek: { thisWeek: number; lastWeek: number; change: number };
  averageCommentsPerPost: number;
  messagesThisWeek: number;
  pendingReports: number;
  totalMakers: number;
  onboardedCount: number;
};

type ActivityItem = {
  timestamp: number;
  type: "new_member" | "new_connection" | "new_post" | "new_rsvp";
  description: string;
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

const activityDots: Record<string, string> = {
  new_member: "bg-emerald-500",
  new_connection: "bg-blue-500",
  new_post: "bg-primary",
  new_rsvp: "bg-amber-500",
};

function ChangeBadge({ change }: { change: number }) {
  return (
    <Badge
      variant="secondary"
      className={
        change >= 0
          ? "bg-emerald-500/10 text-emerald-600 hover:bg-emerald-500/10"
          : "bg-red-500/10 text-red-600 hover:bg-red-500/10"
      }
    >
      {change >= 0 ? "+" : ""}
      {change}%
    </Badge>
  );
}

export default function OverviewPage() {
  const { data: overview, loading: l1 } =
    useConvexQuery<OverviewData>("dashboard:overview");
  const { data: growth, loading: l2 } =
    useConvexQuery<GrowthData>("dashboard:growth");
  const { data: community, loading: l3 } =
    useConvexQuery<CommunityData>("dashboard:communityHealth");
  const { data: activity, loading: l4 } =
    useConvexQuery<ActivityItem[]>("dashboard:recentActivity");

  if (l1 || l2 || l3 || l4) {
    return (
      <div className="flex items-center justify-center h-64">
        <p className="text-sm text-muted-foreground">Loading...</p>
      </div>
    );
  }

  const metrics = overview
    ? [
        {
          title: "Total Makers",
          value: overview.totalMembers.value,
          change: overview.totalMembers.change,
          desc: "Onboarded members",
        },
        {
          title: "Active This Week",
          value: overview.activeUsers.value,
          change: overview.activeUsers.change,
          desc: "Posted, connected, or messaged",
        },
        {
          title: "Connections",
          value: overview.totalConnections.value,
          change: overview.totalConnections.change,
          desc: "Maker-to-maker links",
        },
        {
          title: "Posts This Week",
          value: overview.postsThisWeek.value,
          change: overview.postsThisWeek.change,
          desc: "Feed activity",
        },
      ]
    : [];

  const chartData = (growth ?? []).map((g) => ({
    week: g.week.slice(5),
    signups: g.count,
    total: g.cumulative,
  }));

  const engagementRate =
    community && community.onboardedCount > 0
      ? Math.round(
          (overview!.activeUsers.value / community.onboardedCount) * 100
        )
      : 0;

  const onboardingRate =
    community && community.totalMakers > 0
      ? Math.round((community.onboardedCount / community.totalMakers) * 100)
      : 0;

  const avgWeekly =
    chartData.length > 0
      ? Math.round((overview!.totalMembers.value / chartData.length) * 10) / 10
      : 0;

  return (
    <div className="space-y-8">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">Overview</h2>
        <p className="mt-1 text-sm text-muted-foreground">
          mkrs.world at UNL — community health at a glance
        </p>
      </div>

      {/* KPI Cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {metrics.map((m) => (
          <Card key={m.title}>
            <CardHeader className="pb-2">
              <CardDescription>{m.title}</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex items-baseline gap-2">
                <span className="text-3xl font-bold tabular-nums">
                  {m.value}
                </span>
                <ChangeBadge change={m.change} />
              </div>
              <p className="mt-1 text-xs text-muted-foreground">{m.desc}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Growth Chart */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Growth Trajectory</CardTitle>
              <CardDescription>
                Weekly signups (bars) and total makers (line)
              </CardDescription>
            </div>
            <div className="text-right">
              <p className="text-2xl font-bold tabular-nums">
                {overview?.totalMembers.value}
              </p>
              <p className="text-xs text-muted-foreground">
                {avgWeekly} avg/week
              </p>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <ComposedChart data={chartData}>
                <defs>
                  <linearGradient
                    id="fillGrowth"
                    x1="0"
                    y1="0"
                    x2="0"
                    y2="1"
                  >
                    <stop
                      offset="5%"
                      stopColor="#18181b"
                      stopOpacity={0.08}
                    />
                    <stop
                      offset="95%"
                      stopColor="#18181b"
                      stopOpacity={0}
                    />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#e4e4e7" />
                <XAxis
                  dataKey="week"
                  tick={{ fontSize: 11, fill: "#a1a1aa" }}
                  axisLine={false}
                  tickLine={false}
                />
                <YAxis
                  tick={{ fontSize: 11, fill: "#a1a1aa" }}
                  axisLine={false}
                  tickLine={false}
                />
                <Tooltip
                  contentStyle={{
                    borderRadius: 8,
                    border: "1px solid #e4e4e7",
                    boxShadow: "0 4px 6px -1px rgb(0 0 0 / 0.1)",
                    fontSize: 13,
                  }}
                />
                <Bar
                  dataKey="signups"
                  name="Signups"
                  fill="#18181b"
                  radius={[3, 3, 0, 0]}
                  opacity={0.15}
                />
                <Area
                  type="monotone"
                  dataKey="total"
                  name="Total Makers"
                  stroke="#18181b"
                  strokeWidth={2}
                  fill="url(#fillGrowth)"
                />
              </ComposedChart>
            </ResponsiveContainer>
          </div>
        </CardContent>
      </Card>

      <div className="grid gap-6 lg:grid-cols-5">
        {/* Community Vitals */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Community Vitals</CardTitle>
            <CardDescription>Key health indicators</CardDescription>
          </CardHeader>
          <CardContent className="space-y-1">
            <VitalRow
              label="Onboarding"
              value={`${community?.onboardedCount ?? 0} / ${community?.totalMakers ?? 0}`}
              sub={`${onboardingRate}% complete their profile`}
            />
            <VitalRow
              label="Engagement"
              value={`${engagementRate}%`}
              sub="Active this week / onboarded"
              good={engagementRate >= 40}
            />
            <VitalRow
              label="Comments/Post"
              value={`${community?.averageCommentsPerPost ?? 0}`}
              sub="Avg conversation depth"
            />
            <VitalRow
              label="DMs This Week"
              value={`${community?.messagesThisWeek ?? 0}`}
              sub="Direct messages sent"
            />
            {(community?.pendingReports ?? 0) > 0 && (
              <VitalRow
                label="Reports"
                value={`${community!.pendingReports}`}
                sub="Need review"
                warning
              />
            )}
          </CardContent>
        </Card>

        {/* Activity Feed */}
        <Card className="lg:col-span-3">
          <CardHeader>
            <CardTitle>Live Activity</CardTitle>
            <CardDescription>Real-time community actions</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {(activity ?? []).slice(0, 8).map((item, i) => (
                <div key={i} className="flex items-start gap-3">
                  <div
                    className={`mt-1.5 h-2 w-2 rounded-full shrink-0 ${activityDots[item.type] ?? "bg-primary"}`}
                  />
                  <div className="min-w-0 flex-1">
                    <p className="text-sm">{item.description}</p>
                    <p className="text-xs text-muted-foreground">
                      {timeAgo(item.timestamp)}
                    </p>
                  </div>
                </div>
              ))}
              {(!activity || activity.length === 0) && (
                <p className="text-sm text-muted-foreground">
                  No recent activity
                </p>
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

function VitalRow({
  label,
  value,
  sub,
  good,
  warning,
}: {
  label: string;
  value: string;
  sub: string;
  good?: boolean;
  warning?: boolean;
}) {
  return (
    <div className="flex items-center justify-between py-2.5 border-b border-border last:border-0">
      <div>
        <p className="text-sm">{label}</p>
        <p className="text-xs text-muted-foreground">{sub}</p>
      </div>
      <span
        className={`text-sm font-semibold tabular-nums ${warning ? "text-amber-600" : good ? "text-emerald-600" : ""}`}
      >
        {value}
      </span>
    </div>
  );
}
