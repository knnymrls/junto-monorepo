import { v } from "convex/values";
import { query, mutation, internalQuery, internalMutation } from "./_generated/server";

// === QUERIES ===

// Get all device tokens for a user
export const listForUser = query({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("deviceTokens")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .collect();
  },
});

// Check if a token exists
export const getByToken = query({
  args: { token: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("deviceTokens")
      .withIndex("by_token", (q) => q.eq("token", args.token))
      .first();
  },
});

// === MUTATIONS ===

// Register a device token for push notifications
export const register = mutation({
  args: {
    userId: v.id("users"),
    token: v.string(),
    platform: v.string(),
    appVersion: v.optional(v.string()),
    deviceModel: v.optional(v.string()),
    osVersion: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const now = Date.now();

    // Check if token already exists
    const existing = await ctx.db
      .query("deviceTokens")
      .withIndex("by_token", (q) => q.eq("token", args.token))
      .first();

    if (existing) {
      // Update existing token (might be a different user now)
      await ctx.db.patch(existing._id, {
        userId: args.userId,
        platform: args.platform,
        appVersion: args.appVersion,
        deviceModel: args.deviceModel,
        osVersion: args.osVersion,
        updatedAt: now,
      });
      return existing._id;
    }

    // Create new token
    return await ctx.db.insert("deviceTokens", {
      userId: args.userId,
      token: args.token,
      platform: args.platform,
      appVersion: args.appVersion,
      deviceModel: args.deviceModel,
      osVersion: args.osVersion,
      createdAt: now,
      updatedAt: now,
    });
  },
});

// Remove a device token (on logout or token invalidation)
export const remove = mutation({
  args: { token: v.string() },
  handler: async (ctx, args) => {
    const existing = await ctx.db
      .query("deviceTokens")
      .withIndex("by_token", (q) => q.eq("token", args.token))
      .first();

    if (existing) {
      await ctx.db.delete(existing._id);
      return true;
    }
    return false;
  },
});

// Remove all tokens for a user (useful for logout from all devices)
export const removeAllForUser = mutation({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    const tokens = await ctx.db
      .query("deviceTokens")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .collect();

    for (const token of tokens) {
      await ctx.db.delete(token._id);
    }

    return tokens.length;
  },
});

// === INTERNAL (for use by actions) ===

// Internal query to get tokens for a user (used by push notification action)
export const listForUserInternal = internalQuery({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("deviceTokens")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .collect();
  },
});

// Internal mutation to remove a token (used by push notification action for cleanup)
export const removeInternal = internalMutation({
  args: { token: v.string() },
  handler: async (ctx, args) => {
    const existing = await ctx.db
      .query("deviceTokens")
      .withIndex("by_token", (q) => q.eq("token", args.token))
      .first();

    if (existing) {
      await ctx.db.delete(existing._id);
      return true;
    }
    return false;
  },
});
