import { v } from "convex/values";
import { query } from "./_generated/server";

// List vouches received by a user (with hydrated fromUser data)
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
