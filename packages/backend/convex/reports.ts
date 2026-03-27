import { v } from "convex/values";
import { query, mutation } from "./_generated/server";

// === MUTATIONS ===

// Create a report for a post
export const create = mutation({
  args: {
    reporterId: v.id("users"),
    postId: v.id("posts"),
    reason: v.string(),
    details: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const now = Date.now();

    // Validate reason
    const validReasons = ["spam", "harassment", "inappropriate", "other"];
    if (!validReasons.includes(args.reason)) {
      throw new Error(`Invalid reason: ${args.reason}`);
    }

    // Check that the post exists
    const post = await ctx.db.get(args.postId);
    if (!post) throw new Error("Post not found");

    // Don't allow reporting your own post
    if (post.authorId === args.reporterId) {
      throw new Error("Cannot report your own post");
    }

    const reportId = await ctx.db.insert("reports", {
      reporterId: args.reporterId,
      postId: args.postId,
      reason: args.reason,
      details: args.details,
      status: "pending",
      createdAt: now,
    });

    return reportId;
  },
});

// === QUERIES ===

// List pending reports (for admin use)
export const listPending = query({
  args: {},
  handler: async (ctx) => {
    const reports = await ctx.db
      .query("reports")
      .withIndex("by_status", (q) => q.eq("status", "pending"))
      .order("desc")
      .take(100);

    // Fetch reporter and post info
    const reportsWithDetails = await Promise.all(
      reports.map(async (report) => {
        const reporter = await ctx.db.get(report.reporterId);
        const post = await ctx.db.get(report.postId);
        const postAuthor = post ? await ctx.db.get(post.authorId) : null;

        return {
          ...report,
          reporter: reporter
            ? { _id: reporter._id, name: reporter.name, avatarUrl: reporter.avatarUrl }
            : null,
          post: post
            ? {
                _id: post._id,
                content: post.content,
                authorName: postAuthor?.name ?? "Unknown",
              }
            : null,
        };
      })
    );

    return reportsWithDetails;
  },
});
