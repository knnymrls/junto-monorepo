// Home — the "is it working?" proof page for a university.
// Scoped by university + cohort (users.programs) + timeframe (since). This is the
// data contract the dashboard Home consumes (verdict + KPI tiles + "what needs you").
//
// Campus-scale collect()s are fine here (hundreds of users); revisit with proper
// indexes/aggregations if a campus grows past a few thousand active.

import { v } from "convex/values";
import { query } from "./_generated/server";

const WEEK_MS = 7 * 24 * 60 * 60 * 1000;
const MONTH_MS = 30 * 24 * 60 * 60 * 1000;
const pct = (n: number, d: number) => (d > 0 ? Math.round((n / d) * 100) : 0);

export const homeImpact = query({
  args: {
    universityId: v.id("universities"),
    cohort: v.optional(v.string()), // a program name (e.g. "Accelerator"); undefined = all cohorts
    since: v.optional(v.number()), // timeframe start (ms); default = last 30 days
  },
  handler: async (ctx, args) => {
    const since = args.since ?? Date.now() - MONTH_MS;

    // --- the cohort population (onboarded students in this university, optionally one program) ---
    const universityUsers = await ctx.db
      .query("users")
      .withIndex("by_university", (q) => q.eq("universityId", args.universityId))
      .collect();
    const cohortUsers = universityUsers.filter(
      (u) => u.isOnboarded && (!args.cohort || (u.programs ?? []).includes(args.cohort))
    );
    const memberIds = new Set(cohortUsers.map((u) => u._id));
    const userById = new Map(cohortUsers.map((u) => [u._id, u]));
    const total = cohortUsers.length;

    // --- connections made in the timeframe that touch the cohort ---
    const connected = await ctx.db
      .query("connections")
      .withIndex("by_status", (q) => q.eq("status", "connected"))
      .collect();
    const conns = connected.filter((c) => {
      const at = c.connectedAt ?? c.createdAt;
      return at >= since && (memberIds.has(c.requesterId) || memberIds.has(c.accepterId));
    });

    // active = made/accepted a connection in the timeframe (engagement proxy)
    const activeIds = new Set<string>();
    for (const c of conns) {
      if (memberIds.has(c.requesterId)) activeIds.add(c.requesterId);
      if (memberIds.has(c.accepterId)) activeIds.add(c.accepterId);
    }
    const active = activeIds.size;

    // first-week activation: newcomers (joined in timeframe) who connected within 7 days
    const newcomers = cohortUsers.filter((u) => u.createdAt >= since);
    const activatedNewcomers = newcomers.filter((u) =>
      conns.some(
        (c) =>
          (c.requesterId === u._id || c.accepterId === u._id) &&
          (c.connectedAt ?? c.createdAt) - u.createdAt <= WEEK_MS
      )
    ).length;

    // cross-discipline: a connection whose two people have different primary majors
    let cross = 0;
    for (const c of conns) {
      const a = userById.get(c.requesterId);
      const b = userById.get(c.accepterId);
      const am = a?.majors?.[0]?.majorId;
      const bm = b?.majors?.[0]?.majorId;
      if (am && bm && am !== bm) cross++;
    }

    // "what needs you": newcomers who joined in the timeframe with zero connections
    const isolatedNewcomers = newcomers.filter(
      (u) => !conns.some((c) => c.requesterId === u._id || c.accepterId === u._id)
    ).length;

    return {
      verdict: { active, total, activePct: pct(active, total) },
      kpis: {
        activePct: pct(active, total),
        firstWeekPct: pct(activatedNewcomers, newcomers.length),
        connections: conns.length,
        crossPct: pct(cross, conns.length),
      },
      needs: {
        isolatedNewcomers,
        newcomers: newcomers.length,
      },
    };
  },
});
