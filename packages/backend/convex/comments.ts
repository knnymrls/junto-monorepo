import { v } from "convex/values";
import { query, mutation } from "./_generated/server";
import { internal } from "./_generated/api";

// === QUERIES ===

// List comments for a post with author info
export const listByPost = query({
  args: {
    postId: v.id("posts"),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const limit = args.limit ?? 100;

    const comments = await ctx.db
      .query("comments")
      .withIndex("by_post", (q) => q.eq("postId", args.postId))
      .order("asc") // Oldest first for conversation flow
      .take(limit);

    // Fetch author info for each comment
    const commentsWithAuthors = await Promise.all(
      comments.map(async (comment) => {
        const author = await ctx.db.get(comment.authorId);

        // Also fetch mentioned users if any
        let mentionedUsers = null;
        if (comment.mentions && comment.mentions.length > 0) {
          mentionedUsers = await Promise.all(
            comment.mentions.map((id) => ctx.db.get(id))
          );
        }

        return {
          ...comment,
          author,
          mentionedUsers: mentionedUsers?.filter(Boolean),
        };
      })
    );

    return commentsWithAuthors;
  },
});

// Count comments for a post
export const countByPost = query({
  args: { postId: v.id("posts") },
  handler: async (ctx, args) => {
    const comments = await ctx.db
      .query("comments")
      .withIndex("by_post", (q) => q.eq("postId", args.postId))
      .collect();

    return comments.length;
  },
});

// === MUTATIONS ===

// Create a new comment
export const create = mutation({
  args: {
    postId: v.id("posts"),
    authorId: v.id("users"),
    content: v.string(),
    mentions: v.optional(v.array(v.id("users"))),
    imageUrl: v.optional(v.string()),
    linkUrl: v.optional(v.string()),
    gifUrl: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    // Verify post exists
    const post = await ctx.db.get(args.postId);
    if (!post) throw new Error("Post not found");

    const commentId = await ctx.db.insert("comments", {
      postId: args.postId,
      authorId: args.authorId,
      content: args.content,
      mentions: args.mentions,
      imageUrl: args.imageUrl,
      linkUrl: args.linkUrl,
      gifUrl: args.gifUrl,
      createdAt: Date.now(),
    });

    // Get commenter's name for notification
    const commenter = await ctx.db.get(args.authorId);
    const commenterName = commenter?.name || "Someone";

    // Notify post author about the comment (if not commenting on own post)
    if (post.authorId !== args.authorId) {
      await ctx.scheduler.runAfter(0, internal.notifications.notifyUser, {
        recipientId: post.authorId,
        senderId: args.authorId,
        type: "comment",
        title: `${commenterName} commented on your post`,
        body: args.content.slice(0, 100) + (args.content.length > 100 ? "..." : ""),
        data: {
          postId: args.postId,
          commentId: commentId,
        },
      });
    }

    // Notify mentioned users
    if (args.mentions && args.mentions.length > 0) {
      for (const mentionedId of args.mentions) {
        // Don't notify the commenter if they mentioned themselves
        // Don't notify the post author twice if they were mentioned
        if (mentionedId !== args.authorId && mentionedId !== post.authorId) {
          await ctx.scheduler.runAfter(0, internal.notifications.notifyUser, {
            recipientId: mentionedId,
            senderId: args.authorId,
            type: "mention",
            title: `${commenterName} mentioned you in a comment`,
            body: args.content.slice(0, 100) + (args.content.length > 100 ? "..." : ""),
            data: {
              postId: args.postId,
              commentId: commentId,
            },
          });
        }
      }
    }

    return commentId;
  },
});

// Update a comment
export const update = mutation({
  args: {
    commentId: v.id("comments"),
    content: v.string(),
  },
  handler: async (ctx, args) => {
    const comment = await ctx.db.get(args.commentId);
    if (!comment) throw new Error("Comment not found");

    await ctx.db.patch(args.commentId, {
      content: args.content,
    });

    return args.commentId;
  },
});

// Delete a comment
export const remove = mutation({
  args: { commentId: v.id("comments") },
  handler: async (ctx, args) => {
    const comment = await ctx.db.get(args.commentId);
    if (!comment) throw new Error("Comment not found");

    await ctx.db.delete(args.commentId);

    return args.commentId;
  },
});
