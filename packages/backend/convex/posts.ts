import { v } from "convex/values";
import { query, mutation, internalQuery, internalMutation } from "./_generated/server";
import { internal } from "./_generated/api";
import { Doc } from "./_generated/dataModel";

// Helper to strip embedding from post (reduces bandwidth significantly)
function stripEmbedding(post: Doc<"posts">) {
  return {
    _id: post._id,
    _creationTime: post._creationTime,
    authorId: post.authorId,
    content: post.content,
    category: post.category,
    imageUrl: post.imageUrl,
    imageUrls: post.imageUrls,
    linkUrl: post.linkUrl,
    gifUrl: post.gifUrl,
    createdAt: post.createdAt,
    updatedAt: post.updatedAt,
  };
}

// Helper: Cosine similarity between two embedding vectors
function cosineSimilarity(a: number[], b: number[]): number {
  let dotProduct = 0;
  let normA = 0;
  let normB = 0;

  for (let i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }

  if (normA === 0 || normB === 0) return 0;
  return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
}

// Calculate feed score for sorting
// Score = TierWeight + RecencyScore + RelevanceScore
// - TierWeight: 10000 (connections) or 0 (others)
// - RecencyScore: 0-1000 (exponential decay, ~24h half-life)
// - RelevanceScore: 0-500 (cosine similarity between user & post embeddings)
function calculateFeedScore(
  post: Doc<"posts">,
  isConnection: boolean,
  userEmbedding: number[] | null,
  now: number
): number {
  // Tier: connections always rank first
  const tierWeight = isConnection ? 10000 : 0;

  // Recency: newer = higher (0-1000), exponential decay with ~24h half-life
  const ageHours = (now - post.createdAt) / (1000 * 60 * 60);
  const recencyScore = Math.max(0, 1000 * Math.exp(-ageHours / 24));

  // Relevance: similarity to user profile (0-500)
  let relevanceScore = 0;
  if (userEmbedding && post.embedding) {
    const similarity = cosineSimilarity(userEmbedding, post.embedding);
    // Map similarity (0.3-1.0) to score (0-500)
    // Similarity below 0.3 is considered noise
    relevanceScore = Math.max(0, (similarity - 0.3) * 714);
  }

  return tierWeight + recencyScore + relevanceScore;
}

// === QUERIES ===

// List posts with author info
export const list = query({
  args: {
    limit: v.optional(v.number()),
    authorId: v.optional(v.id("users")),
  },
  handler: async (ctx, args) => {
    const limit = args.limit ?? 50;

    let postsQuery = ctx.db
      .query("posts")
      .withIndex("by_created")
      .order("desc");

    const posts = await postsQuery.take(limit);

    // Filter by author if specified
    const filteredPosts = args.authorId
      ? posts.filter((p) => p.authorId === args.authorId)
      : posts;

    // Fetch author info and comment counts
    const postsWithAuthors = await Promise.all(
      filteredPosts.map(async (post) => {
        const author = await ctx.db.get(post.authorId);
        const comments = await ctx.db
          .query("comments")
          .withIndex("by_post", (q) => q.eq("postId", post._id))
          .collect();
        return {
          ...stripEmbedding(post),
          author,
          commentCount: comments.length,
        };
      })
    );

    return postsWithAuthors;
  },
});

// Get a single post with author and comment count
export const get = query({
  args: { postId: v.id("posts") },
  handler: async (ctx, args) => {
    const post = await ctx.db.get(args.postId);
    if (!post) return null;

    const author = await ctx.db.get(post.authorId);
    const comments = await ctx.db
      .query("comments")
      .withIndex("by_post", (q) => q.eq("postId", post._id))
      .collect();

    return {
      ...stripEmbedding(post),
      author,
      commentCount: comments.length,
    };
  },
});

// Get posts by a specific author
export const getByAuthor = query({
  args: {
    authorId: v.id("users"),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const limit = args.limit ?? 20;

    const posts = await ctx.db
      .query("posts")
      .withIndex("by_author", (q) => q.eq("authorId", args.authorId))
      .order("desc")
      .take(limit);

    // Fetch comment counts
    const postsWithCounts = await Promise.all(
      posts.map(async (post) => {
        const comments = await ctx.db
          .query("comments")
          .withIndex("by_post", (q) => q.eq("postId", post._id))
          .collect();
        return {
          ...stripEmbedding(post),
          commentCount: comments.length,
        };
      })
    );

    return postsWithCounts;
  },
});

// Get personalized feed - connections first, then relevance + recent
export const getFeed = query({
  args: {
    userId: v.id("users"),
    limit: v.optional(v.number()),
    offset: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const limit = args.limit ?? 50;
    const offset = args.offset ?? 0;
    const now = Date.now();

    // Get current user's embedding for relevance scoring
    const currentUser = await ctx.db.get(args.userId);
    const userEmbedding = currentUser?.profileEmbedding ?? null;

    // Get user's connections
    const asRequester = await ctx.db
      .query("connections")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.userId))
      .filter((q) => q.eq(q.field("status"), "connected"))
      .collect();

    const asAccepter = await ctx.db
      .query("connections")
      .withIndex("by_accepter", (q) => q.eq("accepterId", args.userId))
      .filter((q) => q.eq(q.field("status"), "connected"))
      .collect();

    const connectionIds = new Set([
      ...asRequester.map((c) => c.accepterId),
      ...asAccepter.map((c) => c.requesterId),
    ]);

    // Get all recent posts (fetch enough to cover offset + limit after scoring)
    const allPosts = await ctx.db
      .query("posts")
      .withIndex("by_created")
      .order("desc")
      .take((offset + limit) * 2);

    // Score and sort posts by: connections (tier) + relevance + recency
    const scoredPosts = allPosts.map((post) => ({
      post,
      score: calculateFeedScore(
        post,
        connectionIds.has(post.authorId),
        userEmbedding,
        now
      ),
    }));

    // Sort by score descending
    scoredPosts.sort((a, b) => b.score - a.score);

    // Apply pagination
    const paginatedPosts = scoredPosts
      .slice(offset, offset + limit)
      .map((sp) => sp.post);

    // Fetch author info, comment counts, and recent commenters
    const postsWithAuthors = await Promise.all(
      paginatedPosts.map(async (post) => {
        const author = await ctx.db.get(post.authorId);
        const comments = await ctx.db
          .query("comments")
          .withIndex("by_post", (q) => q.eq("postId", post._id))
          .order("desc")
          .collect();

        // Get up to 3 unique recent commenters
        const seenAuthorIds = new Set<string>();
        const recentCommenters: { _id: string; name: string; avatarUrl: string | undefined }[] = [];

        for (const comment of comments) {
          if (!seenAuthorIds.has(comment.authorId) && recentCommenters.length < 3) {
            seenAuthorIds.add(comment.authorId);
            const commenter = await ctx.db.get(comment.authorId);
            if (commenter) {
              recentCommenters.push({
                _id: commenter._id,
                name: commenter.name,
                avatarUrl: commenter.avatarUrl,
              });
            }
          }
        }

        return {
          ...stripEmbedding(post),
          author,
          commentCount: comments.length,
          recentCommenters,
        };
      })
    );

    return postsWithAuthors;
  },
});

// === MUTATIONS ===

// Create a new post
export const create = mutation({
  args: {
    authorId: v.id("users"),
    content: v.string(),
    category: v.union(v.literal("asking"), v.literal("sharing"), v.literal("looking_for")),
    imageUrl: v.optional(v.string()),
    imageUrls: v.optional(v.array(v.string())),
    linkUrl: v.optional(v.string()),
    gifUrl: v.optional(v.string()),
    mentions: v.optional(v.array(v.id("users"))),
  },
  handler: async (ctx, args) => {
    const now = Date.now();

    const postId = await ctx.db.insert("posts", {
      authorId: args.authorId,
      content: args.content,
      category: args.category,
      imageUrl: args.imageUrl,
      imageUrls: args.imageUrls,
      linkUrl: args.linkUrl,
      gifUrl: args.gifUrl,
      createdAt: now,
      updatedAt: now,
    });

    // Schedule embedding generation
    await ctx.scheduler.runAfter(0, internal.embeddings.generatePostEmbedding, {
      postId,
    });

    // Notify mentioned users
    if (args.mentions && args.mentions.length > 0) {
      const author = await ctx.db.get(args.authorId);
      const authorName = author?.name || "Someone";

      for (const mentionedId of args.mentions) {
        if (mentionedId !== args.authorId) {
          await ctx.scheduler.runAfter(0, internal.notifications.notifyUser, {
            recipientId: mentionedId,
            senderId: args.authorId,
            type: "mention",
            title: `${authorName} mentioned you in a post`,
            body: args.content.slice(0, 100) + (args.content.length > 100 ? "..." : ""),
            data: {
              postId: postId,
            },
          });
        }
      }
    }

    return postId;
  },
});

// Update a post
export const update = mutation({
  args: {
    postId: v.id("posts"),
    content: v.optional(v.string()),
    category: v.optional(v.union(v.literal("asking"), v.literal("sharing"), v.literal("looking_for"))),
    imageUrl: v.optional(v.string()),
    imageUrls: v.optional(v.array(v.string())),
    linkUrl: v.optional(v.string()),
    gifUrl: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const { postId, ...updates } = args;

    const post = await ctx.db.get(postId);
    if (!post) throw new Error("Post not found");

    // Filter out undefined values
    const patch: Record<string, unknown> = { updatedAt: Date.now() };
    if (updates.content !== undefined) patch.content = updates.content;
    if (updates.category !== undefined) patch.category = updates.category;
    if (updates.imageUrl !== undefined) patch.imageUrl = updates.imageUrl;
    if (updates.imageUrls !== undefined) patch.imageUrls = updates.imageUrls;
    if (updates.linkUrl !== undefined) patch.linkUrl = updates.linkUrl;
    if (updates.gifUrl !== undefined) patch.gifUrl = updates.gifUrl;

    await ctx.db.patch(postId, patch);

    // Re-generate embedding if content changed
    if (updates.content !== undefined) {
      await ctx.scheduler.runAfter(0, internal.embeddings.generatePostEmbedding, {
        postId,
      });
    }

    return postId;
  },
});

// Delete a post and its comments
export const remove = mutation({
  args: { postId: v.id("posts") },
  handler: async (ctx, args) => {
    const post = await ctx.db.get(args.postId);
    if (!post) throw new Error("Post not found");

    // Delete all comments on this post
    const comments = await ctx.db
      .query("comments")
      .withIndex("by_post", (q) => q.eq("postId", args.postId))
      .collect();

    for (const comment of comments) {
      await ctx.db.delete(comment._id);
    }

    // Delete the post
    await ctx.db.delete(args.postId);

    return args.postId;
  },
});

// === INTERNAL FUNCTIONS ===

// Get post for embedding generation
export const getPost = internalQuery({
  args: { postId: v.id("posts") },
  handler: async (ctx, args) => {
    return await ctx.db.get(args.postId);
  },
});

// Update post embedding
export const updateEmbedding = internalMutation({
  args: {
    postId: v.id("posts"),
    embedding: v.array(v.float64()),
  },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.postId, {
      embedding: args.embedding,
      updatedAt: Date.now(),
    });
  },
});
