import { v } from "convex/values";
import { query, action, internalQuery, internalAction } from "./_generated/server";
import { internal } from "./_generated/api";
import { Doc, Id } from "./_generated/dataModel";

// === VECTOR SEARCH QUERIES ===

// Find similar users using vector search
export const findSimilarUsers = query({
  args: {
    userId: v.id("users"),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args): Promise<Doc<"users">[]> => {
    const user = await ctx.db.get(args.userId);
    if (!user?.profileEmbedding) {
      return [];
    }

    const results = await ctx.db
      .query("users")
      .withSearchIndex("search_headline", (q) => q.search("headline", ""))
      .collect();

    // For now, return all users except self (vector search will be added properly)
    // This is a placeholder until we set up proper vector search
    return results.filter((m) => m._id !== args.userId).slice(0, args.limit ?? 10);
  },
});

// Internal: Embed a query and search
export const embedAndSearch = internalAction({
  args: {
    query: v.string(),
    limit: v.number(),
  },
  handler: async (ctx, args): Promise<{ userId: Id<"users">; score: number }[]> => {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) throw new Error("OPENAI_API_KEY not set");

    // Generate embedding for query
    const response = await fetch("https://api.openai.com/v1/embeddings", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: "text-embedding-3-small",
        input: args.query,
      }),
    });

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${await response.text()}`);
    }

    const data = await response.json();
    const queryEmbedding = data.data[0].embedding as number[];

    // Get all users with embeddings and compute similarity
    const users = await ctx.runQuery(internal.matching.getAllUsersWithEmbeddings, {});

    const scored = users
      .map((user: Doc<"users">) => ({
        userId: user._id,
        score: cosineSimilarity(queryEmbedding, user.profileEmbedding!),
      }))
      .sort((a: { userId: Id<"users">; score: number }, b: { userId: Id<"users">; score: number }) => b.score - a.score)
      .slice(0, args.limit);

    return scored;
  },
});

// Get all users with embeddings (internal)
export const getAllUsersWithEmbeddings = internalQuery({
  args: {},
  handler: async (ctx): Promise<Doc<"users">[]> => {
    const users = await ctx.db.query("users").collect();
    return users.filter((m) => m.profileEmbedding && m.profileEmbedding.length > 0);
  },
});

// Search users by text query (semantic search) - internal action
export const searchByText = internalAction({
  args: {
    query: v.string(),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args): Promise<Doc<"users">[]> => {
    const scored = await ctx.runAction(internal.matching.embedAndSearch, {
      query: args.query,
      limit: args.limit ?? 10,
    });

    // Fetch full user docs
    const users: Doc<"users">[] = [];
    for (const { userId } of scored) {
      const user = await ctx.runQuery(internal.matching.getUserInternal, { id: userId });
      if (user) users.push(user);
    }

    return users;
  },
});

// === MATCHING FUNCTIONS ===

// Find users who match what someone is looking for
export const findMatchesForUser = action({
  args: {
    userId: v.id("users"),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args): Promise<Doc<"users">[]> => {
    const user = await ctx.runQuery(internal.matching.getUserInternal, { id: args.userId });
    if (!user) return [];

    // If they have a "lookingFor", search for users who can help
    if (user.lookingFor) {
      const matches = await ctx.runAction(internal.matching.searchByText, {
        query: user.lookingFor,
        limit: args.limit ?? 10,
      });

      // Filter out the requesting user
      return matches.filter((m: Doc<"users">) => m._id !== args.userId);
    }

    return [];
  },
});

// Get user (internal helper)
export const getUserInternal = internalQuery({
  args: { id: v.id("users") },
  handler: async (ctx, args): Promise<Doc<"users"> | null> => {
    return await ctx.db.get(args.id);
  },
});

// === ADMIN MATCHING TOOLS ===

// Get match score between two users
export const getMatchScore = action({
  args: {
    user1Id: v.id("users"),
    user2Id: v.id("users"),
  },
  handler: async (ctx, args): Promise<{
    score: number;
    reasons: string[];
    user1: { name: string; lookingFor?: string };
    user2: { name: string; lookingFor?: string };
  }> => {
    const user1 = await ctx.runQuery(internal.matching.getUserInternal, { id: args.user1Id });
    const user2 = await ctx.runQuery(internal.matching.getUserInternal, { id: args.user2Id });

    if (!user1 || !user2) {
      return {
        score: 0,
        reasons: ["One or both users not found"],
        user1: { name: "Unknown" },
        user2: { name: "Unknown" },
      };
    }

    const reasons: string[] = [];
    let score = 0;

    // Check if embeddings exist for cosine similarity
    if (user1.profileEmbedding && user2.profileEmbedding) {
      const similarity = cosineSimilarity(user1.profileEmbedding, user2.profileEmbedding);
      score += similarity * 50; // Base similarity contributes up to 50 points
      if (similarity > 0.8) {
        reasons.push("Very similar profiles");
      } else if (similarity > 0.6) {
        reasons.push("Similar interests/background");
      }
    }

    // Check lookingFor <-> canHelpWith match
    if (user1.lookingFor && user2.canHelpWith) {
      const overlap = findKeywordOverlap(user1.lookingFor, user2.canHelpWith);
      if (overlap.length > 0) {
        score += 25;
        reasons.push(`${user1.name} is looking for: ${overlap.join(", ")} - ${user2.name} can help`);
      }
    }

    if (user2.lookingFor && user1.canHelpWith) {
      const overlap = findKeywordOverlap(user2.lookingFor, user1.canHelpWith);
      if (overlap.length > 0) {
        score += 25;
        reasons.push(`${user2.name} is looking for: ${overlap.join(", ")} - ${user1.name} can help`);
      }
    }

    // Skill overlap (skills are now ID references, compare by ID)
    if (user1.skills && user2.skills) {
      const overlap = user1.skills.filter((s) =>
        user2.skills!.some((s2) => s === s2)
      );
      if (overlap.length > 0) {
        score += overlap.length * 5;
        reasons.push(`${overlap.length} shared skill(s)`);
      }
    }

    // Same university
    if (user1.universityId && user2.universityId && user1.universityId === user2.universityId) {
      score += 10;
      reasons.push("Same university");
    }

    return {
      score: Math.min(100, Math.round(score)),
      reasons,
      user1: { name: user1.name, lookingFor: user1.lookingFor },
      user2: { name: user2.name, lookingFor: user2.lookingFor },
    };
  },
});

// Helper: Cosine similarity
function cosineSimilarity(a: number[], b: number[]): number {
  let dotProduct = 0;
  let normA = 0;
  let normB = 0;

  for (let i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }

  return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
}

// Helper: Find keyword overlap between two strings
function findKeywordOverlap(text1: string, text2: string): string[] {
  const keywords1 = extractKeywords(text1);
  const keywords2 = extractKeywords(text2);

  return keywords1.filter((k) => keywords2.includes(k));
}

function extractKeywords(text: string): string[] {
  const stopWords = new Set([
    "a", "an", "the", "and", "or", "but", "in", "on", "at", "to", "for",
    "of", "with", "by", "from", "is", "are", "was", "were", "be", "been",
    "being", "have", "has", "had", "do", "does", "did", "will", "would",
    "could", "should", "may", "might", "must", "i", "me", "my", "we", "our",
    "you", "your", "someone", "something", "looking", "help", "need", "want"
  ]);

  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, "")
    .split(/\s+/)
    .filter((word) => word.length > 2 && !stopWords.has(word));
}
