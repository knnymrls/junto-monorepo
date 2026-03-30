import { v } from "convex/values";
import { query, mutation } from "./_generated/server";
import { internal } from "./_generated/api";

// Create a vouch for someone (connections only, one per person, reason required)
export const create = mutation({
  args: {
    fromUserId: v.id("users"),
    toUserId: v.id("users"),
    reason: v.string(),
  },
  handler: async (ctx, args) => {
    // Can't vouch for yourself
    if (args.fromUserId === args.toUserId) {
      throw new Error("You can't vouch for yourself");
    }

    // Reason must be at least 10 characters
    const trimmedReason = args.reason.trim();
    if (trimmedReason.length < 10) {
      throw new Error("Vouch reason must be at least 10 characters");
    }

    // Must be connected (check both directions)
    const conn1 = await ctx.db
      .query("connections")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.fromUserId))
      .filter((q) =>
        q.and(
          q.eq(q.field("accepterId"), args.toUserId),
          q.eq(q.field("status"), "connected")
        )
      )
      .first();

    if (!conn1) {
      const conn2 = await ctx.db
        .query("connections")
        .withIndex("by_requester", (q) => q.eq("requesterId", args.toUserId))
        .filter((q) =>
          q.and(
            q.eq(q.field("accepterId"), args.fromUserId),
            q.eq(q.field("status"), "connected")
          )
        )
        .first();

      if (!conn2) {
        throw new Error("You can only vouch for people you're connected with");
      }
    }

    // One vouch per person
    const existing = await ctx.db
      .query("vouches")
      .withIndex("by_from_user", (q) => q.eq("fromUserId", args.fromUserId))
      .filter((q) => q.eq(q.field("toUserId"), args.toUserId))
      .first();

    if (existing) {
      throw new Error("You've already vouched for this person");
    }

    // Create the vouch
    const vouchId = await ctx.db.insert("vouches", {
      fromUserId: args.fromUserId,
      toUserId: args.toUserId,
      reason: trimmedReason,
      createdAt: Date.now(),
    });

    // Send notification to recipient
    const fromUser = await ctx.db.get(args.fromUserId);
    const fromName = fromUser?.name || "Someone";

    await ctx.scheduler.runAfter(0, internal.notifications.notifyUser, {
      recipientId: args.toUserId,
      senderId: args.fromUserId,
      type: "vouch",
      title: `${fromName} vouched for you: ${trimmedReason}`,
      data: {
        vouchId,
      },
    });

    return vouchId;
  },
});

// Get all vouches for a user (with voucher info) — used by iOS profile
export const listForUser = query({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    const vouches = await ctx.db
      .query("vouches")
      .withIndex("by_to_user", (q) => q.eq("toUserId", args.userId))
      .order("desc")
      .collect();

    const vouchesWithUsers = await Promise.all(
      vouches.map(async (vouch) => {
        const fromUser = await ctx.db.get(vouch.fromUserId);
        return {
          ...vouch,
          fromUser: fromUser
            ? {
                _id: fromUser._id,
                name: fromUser.name,
                avatarUrl: fromUser.avatarUrl,
                headline: fromUser.headline,
              }
            : null,
        };
      })
    );

    return vouchesWithUsers;
  },
});

// Alias for listForUser — used by iOS subscribeVouches
export const listByUser = query({
  args: {
    toUserId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const vouches = await ctx.db
      .query("vouches")
      .withIndex("by_to_user", (q) => q.eq("toUserId", args.toUserId))
      .order("desc")
      .collect();

    const results = await Promise.all(
      vouches.map(async (vouch) => {
        const fromUser = await ctx.db.get(vouch.fromUserId);
        return {
          _id: vouch._id,
          fromUserId: vouch.fromUserId,
          fromUserName: fromUser?.name ?? "Unknown",
          fromUserAvatarUrl: fromUser?.avatarUrl ?? null,
          reason: vouch.reason,
          createdAt: vouch.createdAt,
        };
      })
    );

    return results;
  },
});

// Check if current user has already vouched for someone
export const hasVouched = query({
  args: {
    fromUserId: v.id("users"),
    toUserId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const existing = await ctx.db
      .query("vouches")
      .withIndex("by_from_user", (q) => q.eq("fromUserId", args.fromUserId))
      .filter((q) => q.eq(q.field("toUserId"), args.toUserId))
      .first();

    return existing !== null;
  },
});
