// Ask Junto — Convex-runtime data layer.
// Render rows (what the client subscribes to), the SDK Session item store, and
// the university signal feed. The "use node" action in askJunto.ts calls these.

import { v } from "convex/values";
import {
  query,
  mutation,
  internalQuery,
  internalMutation,
} from "./_generated/server";

function titleFrom(text: string): string {
  const t = text.trim().replace(/\s+/g, " ");
  return t.length > 48 ? t.slice(0, 45) + "..." : t || "New conversation";
}

// === Threads ===
export const createThread = mutation({
  args: { userId: v.id("users"), firstMessage: v.string() },
  handler: async (ctx, args) => {
    const now = Date.now();
    return await ctx.db.insert("askJuntoThreads", {
      userId: args.userId,
      title: titleFrom(args.firstMessage),
      lastMessageAt: now,
      lastMessagePreview: titleFrom(args.firstMessage),
      createdAt: now,
    });
  },
});

export const listThreads = query({
  args: { userId: v.id("users"), limit: v.optional(v.number()) },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("askJuntoThreads")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .order("desc")
      .take(args.limit ?? 30);
  },
});

// Client subscribes to this for live updates as the assistant message fills in.
export const getMessages = query({
  args: { threadId: v.id("askJuntoThreads") },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("askJuntoMessages")
      .withIndex("by_thread", (q) => q.eq("threadId", args.threadId))
      .order("asc")
      .collect();
  },
});

// === Render rows (written by the action) ===
export const appendUserMessage = internalMutation({
  args: { threadId: v.id("askJuntoThreads"), text: v.string() },
  handler: async (ctx, args) => {
    const now = Date.now();
    const id = await ctx.db.insert("askJuntoMessages", {
      threadId: args.threadId,
      role: "user",
      text: args.text,
      createdAt: now,
    });
    await ctx.db.patch(args.threadId, {
      lastMessageAt: now,
      lastMessagePreview: titleFrom(args.text),
    });
    return id;
  },
});

export const insertAssistantPlaceholder = internalMutation({
  args: { threadId: v.id("askJuntoThreads") },
  handler: async (ctx, args) => {
    return await ctx.db.insert("askJuntoMessages", {
      threadId: args.threadId,
      role: "assistant",
      status: "pending",
      createdAt: Date.now(),
    });
  },
});

// Live progress label written as the agent calls each tool — the client shows
// it on the input field while the message is pending.
export const setAssistantStep = internalMutation({
  args: { messageId: v.id("askJuntoMessages"), step: v.string() },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.messageId, { step: args.step });
  },
});

// Partial `say` text written token-by-token while the message is still pending,
// so the client can type the reply out live. Status stays "pending".
export const streamAssistantText = internalMutation({
  args: { messageId: v.id("askJuntoMessages"), text: v.string() },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.messageId, { text: args.text });
  },
});

export const finalizeAssistantMessage = internalMutation({
  args: {
    messageId: v.id("askJuntoMessages"),
    blocks: v.string(),
    text: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.messageId, {
      status: "complete",
      blocks: args.blocks,
      text: args.text,
    });
  },
});

export const failAssistantMessage = internalMutation({
  args: { messageId: v.id("askJuntoMessages"), text: v.optional(v.string()) },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.messageId, {
      status: "error",
      text: args.text ?? "Something went wrong. Try again.",
    });
  },
});

// === SDK Session item store (raw AgentInputItem[] as JSON strings) ===
export const itemsList = internalQuery({
  args: { threadId: v.id("askJuntoThreads") },
  handler: async (ctx, args) => {
    const rows = await ctx.db
      .query("askJuntoItems")
      .withIndex("by_thread", (q) => q.eq("threadId", args.threadId))
      .order("asc")
      .collect();
    return rows.map((r) => r.item); // JSON strings, in order
  },
});

export const itemsAppend = internalMutation({
  args: { threadId: v.id("askJuntoThreads"), items: v.array(v.string()) },
  handler: async (ctx, args) => {
    const last = await ctx.db
      .query("askJuntoItems")
      .withIndex("by_thread", (q) => q.eq("threadId", args.threadId))
      .order("desc")
      .first();
    let seq = (last?.seq ?? -1) + 1;
    const now = Date.now();
    for (const item of args.items) {
      await ctx.db.insert("askJuntoItems", {
        threadId: args.threadId,
        seq,
        item,
        createdAt: now,
      });
      seq += 1;
    }
  },
});

export const itemsPopLast = internalMutation({
  args: { threadId: v.id("askJuntoThreads") },
  handler: async (ctx, args) => {
    const last = await ctx.db
      .query("askJuntoItems")
      .withIndex("by_thread", (q) => q.eq("threadId", args.threadId))
      .order("desc")
      .first();
    if (!last) return null;
    await ctx.db.delete(last._id);
    return last.item;
  },
});

export const itemsClear = internalMutation({
  args: { threadId: v.id("askJuntoThreads") },
  handler: async (ctx, args) => {
    const rows = await ctx.db
      .query("askJuntoItems")
      .withIndex("by_thread", (q) => q.eq("threadId", args.threadId))
      .collect();
    for (const r of rows) await ctx.db.delete(r._id);
  },
});

// === University signal ===
// One signal per thread. First need-turn creates it; later turns refine it in place
// so a conversation about a single need doesn't inflate the dashboard count.
export const upsertSignal = internalMutation({
  args: {
    userId: v.id("users"),
    universityId: v.optional(v.id("universities")),
    threadId: v.id("askJuntoThreads"),
    text: v.string(),
    category: v.string(),
    now: v.number(),
  },
  handler: async (ctx, args) => {
    const existing = await ctx.db
      .query("askJuntoSignals")
      .withIndex("by_thread", (q) => q.eq("threadId", args.threadId))
      .first();

    if (existing) {
      // Refine the existing ask; keep its status and original createdAt.
      await ctx.db.patch(existing._id, {
        text: args.text,
        category: args.category,
        updatedAt: args.now,
      });
      return existing._id;
    }

    return await ctx.db.insert("askJuntoSignals", {
      userId: args.userId,
      universityId: args.universityId,
      threadId: args.threadId,
      text: args.text,
      category: args.category,
      status: "open",
      createdAt: args.now,
      updatedAt: args.now,
    });
  },
});

// === Durable per-user memory (what Ask Junto knows about the student) ===

export const listMemory = internalQuery({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("askJuntoMemory")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .order("asc")
      .collect();
  },
});

const MEMORY_CAP = 50;

function normalizeFact(text: string): string {
  return text.trim().toLowerCase().replace(/\s+/g, " ");
}

// Append durable facts the agent learned this turn. Dedupes against existing
// memory (case/space-insensitive) and caps total, dropping the oldest.
export const rememberFacts = internalMutation({
  args: {
    userId: v.id("users"),
    facts: v.array(
      v.object({ text: v.string(), category: v.optional(v.string()) })
    ),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    const existing = await ctx.db
      .query("askJuntoMemory")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .order("asc")
      .collect();

    const seen = new Set(existing.map((m) => normalizeFact(m.text)));

    for (const fact of args.facts) {
      const text = fact.text.trim();
      if (!text) continue;
      const key = normalizeFact(text);
      if (seen.has(key)) continue;
      seen.add(key);
      await ctx.db.insert("askJuntoMemory", {
        userId: args.userId,
        text,
        category: fact.category,
        createdAt: now,
        updatedAt: now,
      });
    }

    // Cap: drop the oldest beyond MEMORY_CAP.
    const all = await ctx.db
      .query("askJuntoMemory")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .order("asc")
      .collect();
    if (all.length > MEMORY_CAP) {
      for (const old of all.slice(0, all.length - MEMORY_CAP)) {
        await ctx.db.delete(old._id);
      }
    }
  },
});
