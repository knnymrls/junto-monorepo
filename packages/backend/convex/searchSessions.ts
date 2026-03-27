import { v } from "convex/values";
import { query, mutation, internalMutation } from "./_generated/server";

// Client subscribes to this for real-time session updates
export const getSession = query({
  args: { sessionId: v.id("searchSessions") },
  handler: async (ctx, args) => {
    return await ctx.db.get(args.sessionId);
  },
});

// Client calls this to create a new session, returns sessionId
export const createSession = mutation({
  args: {
    userId: v.id("users"),
    query: v.string(),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    const sessionId = await ctx.db.insert("searchSessions", {
      userId: args.userId,
      query: args.query,
      status: "pending",
      createdAt: now,
      updatedAt: now,
    });
    return sessionId;
  },
});

// Action writes partial results here (internal only)
export const updateSession = internalMutation({
  args: {
    sessionId: v.id("searchSessions"),
    status: v.optional(v.string()),
    thinkingText: v.optional(v.string()),
    results: v.optional(v.string()),
    resultCount: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const { sessionId, ...updates } = args;
    const filtered: Record<string, unknown> = { updatedAt: Date.now() };
    if (updates.status !== undefined) filtered.status = updates.status;
    if (updates.thinkingText !== undefined) filtered.thinkingText = updates.thinkingText;
    if (updates.results !== undefined) filtered.results = updates.results;
    if (updates.resultCount !== undefined) filtered.resultCount = updates.resultCount;
    await ctx.db.patch(sessionId, filtered);
  },
});

// Cleanup sessions older than 1 hour
export const cleanupOldSessions = internalMutation({
  args: {},
  handler: async (ctx) => {
    const oneHourAgo = Date.now() - 60 * 60 * 1000;
    const oldSessions = await ctx.db
      .query("searchSessions")
      .filter((q) => q.lt(q.field("createdAt"), oneHourAgo))
      .collect();

    for (const session of oldSessions) {
      await ctx.db.delete(session._id);
    }

    return { deleted: oldSessions.length };
  },
});
