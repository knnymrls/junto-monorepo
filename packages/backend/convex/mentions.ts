import { v } from "convex/values";
import { query, action } from "./_generated/server";

// Get suggested mentions based on search text (simple text matching)
// Note: Vector search for smarter suggestions requires an action, not a query
export const getSuggestions = query({
  args: {
    searchText: v.string(),
  },
  handler: async (ctx, args) => {
    // Get all users
    const users = await ctx.db.query("users").take(50);

    // Filter by search text (name/headline matching)
    let filteredUsers = users;
    if (args.searchText) {
      const search = args.searchText.toLowerCase();
      filteredUsers = users.filter(
        (m) =>
          m.name?.toLowerCase().includes(search) ||
          m.headline?.toLowerCase().includes(search)
      );
    }

    // Return top 10 with limited fields
    return filteredUsers.slice(0, 10).map((m) => ({
      _id: m._id,
      name: m.name,
      headline: m.headline,
      avatarUrl: m.avatarUrl,
    }));
  },
});

// Smart mention suggestions using vector search (for relevance to post content)
export const getSmartSuggestions = action({
  args: {
    postId: v.id("posts"),
    searchText: v.string(),
  },
  handler: async (ctx, args) => {
    // Get the post embedding
    const post = await ctx.runQuery(
      // @ts-expect-error - internal query
      "posts:getPost",
      { postId: args.postId }
    );

    if (!post?.embedding) {
      // Fallback to simple search if no embedding
      return await ctx.runQuery(
        // @ts-expect-error - internal query
        "mentions:getSuggestions",
        { searchText: args.searchText }
      );
    }

    // Vector search against user embeddings
    const results = await ctx.vectorSearch("users", "by_profile_embedding", {
      vector: post.embedding,
      limit: 20,
    });

    // Get full user docs
    const userIds = results.map((r) => r._id);
    const users = await Promise.all(
      userIds.map((id) =>
        ctx.runQuery(
          // @ts-expect-error - internal query
          "users:get",
          { id }
        )
      )
    );

    // Filter by search text
    let filteredUsers = users.filter(Boolean);
    if (args.searchText) {
      const search = args.searchText.toLowerCase();
      filteredUsers = filteredUsers.filter(
        (m: any) =>
          m?.name?.toLowerCase().includes(search) ||
          m?.headline?.toLowerCase().includes(search)
      );
    }

    // Return top 10 with limited fields
    return filteredUsers.slice(0, 10).map((m: any) => ({
      _id: m._id,
      name: m.name,
      headline: m.headline,
      avatarUrl: m.avatarUrl,
    }));
  },
});

// Get users by IDs (for rendering mentions in comments)
export const getByIds = query({
  args: {
    userIds: v.array(v.id("users")),
  },
  handler: async (ctx, args) => {
    const users = await Promise.all(
      args.userIds.map((id) => ctx.db.get(id))
    );

    return users.filter(Boolean).map((m) => ({
      _id: m!._id,
      name: m!.name,
      headline: m!.headline,
      avatarUrl: m!.avatarUrl,
    }));
  },
});
