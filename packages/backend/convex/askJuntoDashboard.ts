// Ask Junto — university dashboard.
// "What are students asking?" Powers the PRD's Pulse + Asks views. Every Ask Junto
// turn that expresses a real need becomes a signal here, tagged to the university.

import { v } from "convex/values";
import { query, mutation } from "./_generated/server";
import { topNeeds } from "./askJuntoCore";

const WEEK_MS = 7 * 24 * 60 * 60 * 1000;

async function signalsSince(
  ctx: any,
  universityId: string,
  since: number
) {
  return await ctx.db
    .query("askJuntoSignals")
    .withIndex("by_university", (q: any) =>
      q.eq("universityId", universityId).gte("createdAt", since)
    )
    .order("desc")
    .collect();
}

// Pulse: the at-a-glance health of campus needs this week.
export const pulse = query({
  args: { universityId: v.id("universities") },
  handler: async (ctx, args) => {
    const since = Date.now() - WEEK_MS;
    const week = await signalsSince(ctx, args.universityId as string, since);

    const open = week.filter((s: any) => s.status === "open").length;
    const matched = week.filter((s: any) => s.status === "matched").length;
    const resolved = week.filter((s: any) => s.status === "resolved").length;

    return {
      totalThisWeek: week.length,
      open,
      matched,
      resolved,
      topNeeds: topNeeds(week).slice(0, 6),
    };
  },
});

// Asks: the queue. Filter by status; grouped/sorted by recency.
export const listAsks = query({
  args: {
    universityId: v.id("universities"),
    status: v.optional(
      v.union(v.literal("open"), v.literal("matched"), v.literal("resolved"))
    ),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    let rows;
    if (args.status) {
      rows = await ctx.db
        .query("askJuntoSignals")
        .withIndex("by_university_status", (q) =>
          q.eq("universityId", args.universityId).eq("status", args.status!)
        )
        .order("desc")
        .take(args.limit ?? 100);
    } else {
      rows = await ctx.db
        .query("askJuntoSignals")
        .withIndex("by_university", (q) =>
          q.eq("universityId", args.universityId)
        )
        .order("desc")
        .take(args.limit ?? 100);
    }

    // Attach the asker's display name (light enrichment for the dashboard table).
    return await Promise.all(
      rows.map(async (s) => {
        const user = await ctx.db.get(s.userId);
        return {
          _id: s._id,
          text: s.text,
          category: s.category,
          status: s.status,
          createdAt: s.createdAt,
          askerName: user?.name ?? "Unknown",
          askerId: s.userId,
        };
      })
    );
  },
});

// Admin action: move an ask through the queue.
export const updateSignalStatus = mutation({
  args: {
    signalId: v.id("askJuntoSignals"),
    status: v.union(
      v.literal("open"),
      v.literal("matched"),
      v.literal("resolved")
    ),
  },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.signalId, { status: args.status });
  },
});
