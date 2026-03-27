import { v } from "convex/values";
import { query, mutation } from "./_generated/server";

// List all portfolio items for a user, sorted by order
export const list = query({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    const items = await ctx.db
      .query("portfolioItems")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .collect();

    return items.sort((a, b) => a.order - b.order);
  },
});

// Get a single portfolio item
export const get = query({
  args: { id: v.id("portfolioItems") },
  handler: async (ctx, args) => {
    return await ctx.db.get(args.id);
  },
});

// Create a new portfolio item
export const create = mutation({
  args: {
    userId: v.id("users"),
    type: v.union(
      v.literal("github"),
      v.literal("gallery"),
      v.literal("link"),
      v.literal("experience")
    ),
    title: v.optional(v.string()),
    url: v.optional(v.string()),
    description: v.optional(v.string()),
    imageUrls: v.optional(v.array(v.string())),
    organization: v.optional(v.string()),
    startDate: v.optional(v.string()),
    endDate: v.optional(v.string()),
    size: v.optional(v.union(v.literal("small"), v.literal("medium"), v.literal("large"))),
  },
  handler: async (ctx, args) => {
    const now = Date.now();

    // Get max order for this user
    const existing = await ctx.db
      .query("portfolioItems")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .collect();

    const maxOrder = existing.length > 0
      ? Math.max(...existing.map((i) => i.order))
      : -1;

    return await ctx.db.insert("portfolioItems", {
      ...args,
      order: maxOrder + 1,
      createdAt: now,
      updatedAt: now,
    });
  },
});

// Update a portfolio item
export const update = mutation({
  args: {
    id: v.id("portfolioItems"),
    title: v.optional(v.string()),
    url: v.optional(v.string()),
    description: v.optional(v.string()),
    imageUrls: v.optional(v.array(v.string())),
    organization: v.optional(v.string()),
    startDate: v.optional(v.string()),
    endDate: v.optional(v.string()),
    size: v.optional(v.union(v.literal("small"), v.literal("medium"), v.literal("large"))),
    order: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const { id, ...fields } = args;
    const item = await ctx.db.get(id);
    if (!item) throw new Error("Portfolio item not found");

    // Only update fields that were provided
    const updates: Record<string, unknown> = { updatedAt: Date.now() };
    for (const [key, value] of Object.entries(fields)) {
      if (value !== undefined) {
        updates[key] = value;
      }
    }

    await ctx.db.patch(id, updates);
    return id;
  },
});

// Delete a portfolio item
export const remove = mutation({
  args: { id: v.id("portfolioItems") },
  handler: async (ctx, args) => {
    const item = await ctx.db.get(args.id);
    if (!item) throw new Error("Portfolio item not found");
    await ctx.db.delete(args.id);
    return args.id;
  },
});

// Batch reorder portfolio items
export const reorder = mutation({
  args: {
    items: v.array(v.object({
      id: v.id("portfolioItems"),
      order: v.number(),
      size: v.optional(v.union(v.literal("small"), v.literal("medium"), v.literal("large"))),
    })),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    for (const item of args.items) {
      const updates: Record<string, unknown> = { order: item.order, updatedAt: now };
      if (item.size !== undefined) {
        updates.size = item.size;
      }
      await ctx.db.patch(item.id, updates);
    }
  },
});
