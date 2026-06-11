"use node";

import { v } from "convex/values";
import { action } from "./_generated/server";
import { api, internal } from "./_generated/api";
import { embed, generateObject, streamObject } from "ai";
import { openai } from "@ai-sdk/openai";
import { z } from "zod";

// Helper: generate embedding for a query string using AI SDK
async function embedQuery(text: string): Promise<number[]> {
  const { embedding } = await embed({
    model: openai.embedding("text-embedding-3-small"),
    value: text,
  });
  return embedding;
}

// Result type shared by all search endpoints
type SearchResult = {
  userId: string;
  explanation: string;
  relevanceScore: number;
  mutualConnectionCount: number;
  mutualConnectionNames: string[];
  connectionStatus: string;
  isAIEnhanced?: boolean;
};

// Smart auto-explanation: short human label (max ~60 chars)
function buildSmartExplanation(user: any): string {
  const truncate = (s: string) => s.length > 60 ? s.slice(0, 57) + "..." : s;
  if (user.currentProject) return truncate(user.currentProject as string);
  if (user.lookingFor) return truncate(user.lookingFor as string);
  if (user.headline) return truncate(user.headline as string);
  if (user.canHelpWith) return truncate(`Can help with ${user.canHelpWith}`);
  return user.name as string;
}

// Build searcher context for LLM prompts
function buildSearcherContext(searcher: any): string {
  if (!searcher) return "";
  const parts = [
    `About the person searching:`,
    `  Name: ${searcher.name}`,
    searcher.headline ? `  Headline: ${searcher.headline}` : null,
    searcher.skills?.length ? `  Skills: ${searcher.skills.join(", ")}` : null,
    searcher.interests?.length ? `  Interests: ${searcher.interests.join(", ")}` : null,
    searcher.currentProject ? `  Current project: ${searcher.currentProject}` : null,
    searcher.lookingFor ? `  Looking for: ${searcher.lookingFor}` : null,
    searcher.canHelpWith ? `  Can help with: ${searcher.canHelpWith}` : null,
  ].filter(Boolean);
  return parts.join("\n");
}

const LLM_SYSTEM_PROMPT = `You help students on a campus app find people they should know. Rank candidates by how well they match the searcher's query.

Rules for the "explanation" field — shown on a small card next to each person:
- MAX 60 characters. One short phrase.
- Write like a human label, NOT like AI analysis.
- Never reference profile fields by name (don't say "headline:", "lists X as interests", "their bio says").
- Never start with the person's name.
- Good: "DJ, available for events" / "Growth marketer, ex-HubSpot" / "iOS developer building a health app"
- Bad: "Lance is explicitly a DJ (headline: DJ)" / "David lists Events as an interest"

Rules for the "thinking" field — shown to the searcher as a one-liner status:
- Speak directly to the searcher in second person ("you", "your"). Never refer to "the user" or "the searcher".
- Casual, conversational, like a friend who knows the campus. No corporate or algorithmic language.
- Never use words like "query", "ranked", "evaluated", "scored", "candidates", "profiles", "matched".
- 1–2 short sentences max. Describe the *people* you found and why they fit, not the search process.
- Good: "Found a few iOS devs who'd vibe with what you're building." / "These folks already help with branding for student startups."
- Bad: "Query matched the user's own profile included, then ranked others by professional fit." / "I evaluated candidates based on skills overlap."

Consider complementary matching when the searcher's profile is provided — find people who fill gaps or share goals.`;

// Fast search: name + vector search, no LLM, no chat persistence
export const quickSearch = action({
  args: {
    query: v.string(),
    currentUserId: v.id("users"),
  },
  handler: async (ctx, args): Promise<{
    results: SearchResult[];
  }> => {
    // Name search + vector search in parallel
    const [nameMatches, queryVector] = await Promise.all([
      ctx.runQuery(internal.users.internalSearchByName, { query: args.query, limit: 10 }),
      embedQuery(args.query),
    ]);

    const vectorResults = await ctx.vectorSearch("users", "by_profile_embedding", {
      vector: queryVector,
      limit: 10,
    });

    // Combine and deduplicate
    const candidateMap = new Map<string, { score: number; source: "name" | "vector" }>();

    for (const user of nameMatches) {
      if ((user._id as string) !== (args.currentUserId as string)) {
        candidateMap.set(user._id as string, { score: 0.9, source: "name" });
      }
    }

    for (const result of vectorResults) {
      if ((result._id as string) !== (args.currentUserId as string)) {
        if (!candidateMap.has(result._id as string)) {
          candidateMap.set(result._id as string, { score: result._score, source: "vector" });
        }
      }
    }

    // Sort by score, take top 8
    const sorted = [...candidateMap.entries()]
      .sort((a, b) => b[1].score - a[1].score)
      .slice(0, 8);

    if (sorted.length === 0) {
      return { results: [] };
    }

    // Fetch profiles and build auto-explanations
    const profiles = await Promise.all(
      sorted.map(async ([userId]) => {
        const user = await ctx.runQuery(api.users.get, { id: userId as any });
        return { userId, user };
      })
    );

    const baseResults = profiles
      .filter((p) => p.user !== null)
      .map((p) => {
        const score = candidateMap.get(p.userId)?.score ?? 0.5;
        return { userId: p.userId, explanation: buildSmartExplanation(p.user!), relevanceScore: score };
      });

    // Enrich with mutual connections
    const enrichedResults = await Promise.all(
      baseResults.map(async (result) => {
        const mutual = await ctx.runQuery(internal.connections.internalGetMutualConnections, {
          userIdA: args.currentUserId,
          userIdB: result.userId as any,
        });
        return {
          ...result,
          mutualConnectionCount: mutual.count,
          mutualConnectionNames: mutual.names,
          connectionStatus: mutual.connectionStatus,
        };
      })
    );

    return { results: enrichedResults };
  },
});

// Fast vector search: retrieval + auto-explanations, no LLM
export const vectorSearch = action({
  args: {
    query: v.string(),
    currentUserId: v.id("users"),
  },
  handler: async (ctx, args): Promise<{
    results: SearchResult[];
  }> => {
    const queryVector = await embedQuery(args.query);

    const [userResults, postResults] = await Promise.all([
      ctx.vectorSearch("users", "by_profile_embedding", {
        vector: queryVector,
        limit: 30,
      }),
      ctx.vectorSearch("posts", "by_embedding", {
        vector: queryVector,
        limit: 15,
      }),
    ]);

    // Collect unique user IDs from both sources
    const candidateIds = new Map<string, number>();

    for (const result of userResults) {
      if (result._id !== args.currentUserId) {
        candidateIds.set(result._id as string, result._score);
      }
    }

    const postDocs = await Promise.all(
      postResults.map((r) => ctx.runQuery(internal.posts.getPost, { postId: r._id }))
    );

    for (let i = 0; i < postDocs.length; i++) {
      const post = postDocs[i];
      if (!post) continue;
      const authorId = post.authorId as string;
      if (authorId === (args.currentUserId as string)) continue;

      const existing = candidateIds.get(authorId);
      if (!existing || postResults[i]._score > existing) {
        candidateIds.set(authorId, postResults[i]._score);
      }
    }

    const sorted = [...candidateIds.entries()]
      .sort((a, b) => b[1] - a[1])
      .slice(0, 30);

    if (sorted.length === 0) {
      return { results: [] };
    }

    // Fetch profiles and build auto-explanations
    const profiles = await Promise.all(
      sorted.map(async ([userId]) => {
        const user = await ctx.runQuery(api.users.get, { id: userId as any });
        return { userId, user };
      })
    );

    const baseResults = profiles
      .filter((p) => p.user !== null)
      .map((p) => {
        const score = candidateIds.get(p.userId)?.valueOf() ?? 0.5;
        return { userId: p.userId, explanation: buildSmartExplanation(p.user!), relevanceScore: score, isAIEnhanced: false };
      });

    // Enrich with mutual connections
    const enrichedResults = await Promise.all(
      baseResults.map(async (result) => {
        const mutual = await ctx.runQuery(internal.connections.internalGetMutualConnections, {
          userIdA: args.currentUserId,
          userIdB: result.userId as any,
        });
        return {
          ...result,
          mutualConnectionCount: mutual.count,
          mutualConnectionNames: mutual.names,
          connectionStatus: mutual.connectionStatus,
        };
      })
    );

    return { results: enrichedResults };
  },
});

// LLM enhancement: takes user IDs from vectorSearch and adds AI reasoning
export const enhanceWithLLM = action({
  args: {
    query: v.string(),
    userIds: v.array(v.string()),
    currentUserId: v.id("users"),
  },
  handler: async (ctx, args): Promise<{
    thinking: string;
    results: SearchResult[];
  }> => {
    if (args.userIds.length === 0) {
      return { thinking: "No candidates to enhance.", results: [] };
    }

    // Fetch searcher's profile + candidate profiles in parallel
    const [searcher, ...candidateResults] = await Promise.all([
      ctx.runQuery(api.users.get, { id: args.currentUserId }),
      ...args.userIds.map(async (userId) => {
        const user = await ctx.runQuery(api.users.get, { id: userId as any });
        const posts = await ctx.runQuery(api.posts.list, {
          authorId: userId as any,
          limit: 1,
        });
        return { userId, user, recentPosts: posts };
      }),
    ]);

    const candidates = candidateResults as { userId: string; user: any; recentPosts: any[] }[];
    const validCandidates = candidates.filter((c) => c.user !== null);

    if (validCandidates.length === 0) {
      return { thinking: "No valid profiles found.", results: [] };
    }

    const searcherContext = buildSearcherContext(searcher);

    const profileSummaries = validCandidates.map((c, i) => {
      const m = c.user!;
      const parts = [
        `Candidate ${i + 1} (ID: ${m._id}):`,
        `  Name: ${m.name}`,
        m.headline ? `  Headline: ${m.headline}` : null,
        m.skills?.length ? `  Skills: ${m.skills.join(", ")}` : null,
        m.interests?.length ? `  Interests: ${m.interests.join(", ")}` : null,
        m.lookingFor ? `  Looking for: ${m.lookingFor}` : null,
        m.canHelpWith ? `  Can help with: ${m.canHelpWith}` : null,
        m.currentProject ? `  Current project: ${m.currentProject}` : null,
      ].filter(Boolean);

      if (c.recentPosts.length > 0) {
        parts.push(`  Recent posts:`);
        for (const post of c.recentPosts) {
          parts.push(`    - [${post.category}] ${post.content.slice(0, 150)}`);
        }
      }

      return parts.join("\n");
    });

    const { object } = await generateObject({
      model: openai("gpt-5-mini"),
      schema: z.object({
        results: z.array(z.object({
          userId: z.string().describe("The candidate's ID"),
          explanation: z.string().max(60).describe("Short human-readable label for why they match. Max 60 chars. No AI-speak, no field references."),
          relevanceScore: z.number().min(0).max(1).describe("How relevant this person is to the query, 0-1"),
        })).describe("Ranked list of matching candidates, best matches first. Only include candidates with relevanceScore >= 0.3"),
        thinking: z.string().describe("A short, casual note to the searcher (use 'you'/'your') describing the people you found and why they fit. 1–2 sentences. No algorithmic language."),
      }),
      system: LLM_SYSTEM_PROMPT,
      prompt: `Search query: "${args.query}"\n\n${searcherContext ? searcherContext + "\n\n" : ""}Candidate profiles:\n${profileSummaries.join("\n\n")}`,
    });

    const userIdSet = new Set(validCandidates.map((c) => c.user!._id as string));

    const baseResults = object.results
      .filter((r) => userIdSet.has(r.userId))
      .map((r) => ({
        userId: r.userId,
        explanation: r.explanation,
        relevanceScore: r.relevanceScore,
        isAIEnhanced: true,
      }));

    // Enrich with mutual connections
    const enrichedResults = await Promise.all(
      baseResults.map(async (result) => {
        const mutual = await ctx.runQuery(internal.connections.internalGetMutualConnections, {
          userIdA: args.currentUserId,
          userIdB: result.userId as any,
        });
        return {
          ...result,
          mutualConnectionCount: mutual.count,
          mutualConnectionNames: mutual.names,
          connectionStatus: mutual.connectionStatus,
        };
      })
    );

    return {
      thinking: object.thinking,
      results: enrichedResults,
    };
  },
});

// Streaming LLM enhancement: writes partial results to searchSessions table
export const streamEnhanceWithLLM = action({
  args: {
    sessionId: v.id("searchSessions"),
    query: v.string(),
    userIds: v.array(v.string()),
    currentUserId: v.id("users"),
  },
  handler: async (ctx, args) => {
    if (args.userIds.length === 0) {
      await ctx.runMutation(internal.searchSessions.updateSession, {
        sessionId: args.sessionId,
        status: "complete",
        thinkingText: "No candidates to enhance.",
        results: "[]",
        resultCount: 0,
      });
      return;
    }

    // Mark session as streaming + fetch searcher profile in parallel
    const [, searcher] = await Promise.all([
      ctx.runMutation(internal.searchSessions.updateSession, {
        sessionId: args.sessionId,
        status: "streaming",
      }),
      ctx.runQuery(api.users.get, { id: args.currentUserId }),
    ]);

    // Fetch profiles + recent posts for provided user IDs
    const candidates = await Promise.all(
      args.userIds.map(async (userId) => {
        const user = await ctx.runQuery(api.users.get, { id: userId as any });
        const posts = await ctx.runQuery(api.posts.list, {
          authorId: userId as any,
          limit: 1,
        });
        return { userId, user, recentPosts: posts };
      })
    );

    const validCandidates = candidates.filter((c) => c.user !== null);

    if (validCandidates.length === 0) {
      await ctx.runMutation(internal.searchSessions.updateSession, {
        sessionId: args.sessionId,
        status: "complete",
        thinkingText: "No valid profiles found.",
        results: "[]",
        resultCount: 0,
      });
      return;
    }

    const searcherContext = buildSearcherContext(searcher);

    const profileSummaries = validCandidates.map((c, i) => {
      const m = c.user!;
      const parts = [
        `Candidate ${i + 1} (ID: ${m._id}):`,
        `  Name: ${m.name}`,
        m.headline ? `  Headline: ${m.headline}` : null,
        m.skills?.length ? `  Skills: ${m.skills.join(", ")}` : null,
        m.interests?.length ? `  Interests: ${m.interests.join(", ")}` : null,
        m.lookingFor ? `  Looking for: ${m.lookingFor}` : null,
        m.canHelpWith ? `  Can help with: ${m.canHelpWith}` : null,
        m.currentProject ? `  Current project: ${m.currentProject}` : null,
      ].filter(Boolean);

      if (c.recentPosts.length > 0) {
        parts.push(`  Recent posts:`);
        for (const post of c.recentPosts) {
          parts.push(`    - [${post.category}] ${post.content.slice(0, 150)}`);
        }
      }

      return parts.join("\n");
    });

    const schema = z.object({
      results: z.array(z.object({
        userId: z.string().describe("The candidate's ID"),
        explanation: z.string().max(60).describe("Short human-readable label for why they match. Max 60 chars. No AI-speak, no field references."),
        relevanceScore: z.number().min(0).max(1).describe("How relevant this person is to the query, 0-1"),
      })).describe("Ranked list of matching candidates, best matches first. Only include candidates with relevanceScore >= 0.3"),
      thinking: z.string().describe("A short, casual note to the searcher (use 'you'/'your') describing the people you found and why they fit. 1–2 sentences. No algorithmic language."),
    });

    const userIdSet = new Set(validCandidates.map((c) => c.user!._id as string));

    // Stream partial results
    const { partialObjectStream } = streamObject({
      model: openai("gpt-5-mini"),
      schema,
      system: LLM_SYSTEM_PROMPT,
      prompt: `Search query: "${args.query}"\n\n${searcherContext ? searcherContext + "\n\n" : ""}Candidate profiles:\n${profileSummaries.join("\n\n")}`,
    });

    let lastThinkingLength = 0;
    let lastResultCount = 0;
    // Track the latest full partial locally — throttled session writes can
    // skip the final chunks of the stream, so the session is not a reliable
    // source for the completed results.
    let latestThinking = "";
    let latestResults: { userId: string; explanation: string; relevanceScore: number }[] = [];

    try {
      for await (const partial of partialObjectStream) {
        const thinkingText = partial.thinking ?? "";
        const results = (partial.results ?? []).filter((r): r is { userId: string; explanation: string; relevanceScore: number } =>
          r !== undefined && r.userId !== undefined && r.explanation !== undefined && r.relevanceScore !== undefined && userIdSet.has(r.userId)
        );
        latestThinking = thinkingText;
        latestResults = results;

        // Throttle writes: only update when thinking grows by 50+ chars or new result appears
        const thinkingGrew = thinkingText.length - lastThinkingLength >= 50;
        const newResults = results.length > lastResultCount;

        if (thinkingGrew || newResults) {
          lastThinkingLength = thinkingText.length;
          lastResultCount = results.length;

          await ctx.runMutation(internal.searchSessions.updateSession, {
            sessionId: args.sessionId,
            thinkingText,
            results: JSON.stringify(results),
            resultCount: results.length,
          });
        }
      }

      const enrichedResults = await Promise.all(
        latestResults.map(async (result) => {
          const mutual = await ctx.runQuery(internal.connections.internalGetMutualConnections, {
            userIdA: args.currentUserId,
            userIdB: result.userId as any,
          });
          return {
            ...result,
            isAIEnhanced: true,
            mutualConnectionCount: mutual.count,
            mutualConnectionNames: mutual.names,
            connectionStatus: mutual.connectionStatus,
          };
        })
      );

      // Final update: mark complete with enriched results
      await ctx.runMutation(internal.searchSessions.updateSession, {
        sessionId: args.sessionId,
        status: "complete",
        thinkingText: latestThinking,
        results: JSON.stringify(enrichedResults),
        resultCount: enrichedResults.length,
      });
    } catch (error) {
      // The client only exits the streaming phase on "complete" or "error" —
      // a session stuck at "streaming" is an infinite spinner.
      await ctx.runMutation(internal.searchSessions.updateSession, {
        sessionId: args.sessionId,
        status: "error",
        thinkingText: "Search failed. Please try again.",
      });
      throw error;
    }
  },
});

// AI-powered search: vector + post search + LLM reasoning + mutual connections
// Called explicitly when user taps "Ask AI" or for conversational queries
export const searchPeople = action({
  args: {
    query: v.string(),
    currentUserId: v.id("users"),
  },
  handler: async (ctx, args): Promise<{
    thinking: string;
    results: SearchResult[];
  }> => {
    // Phase 1: Retrieval via vector search
    const queryVector = await embedQuery(args.query);

    const [userResults, postResults] = await Promise.all([
      ctx.vectorSearch("users", "by_profile_embedding", {
        vector: queryVector,
        limit: 15,
      }),
      ctx.vectorSearch("posts", "by_embedding", {
        vector: queryVector,
        limit: 10,
      }),
    ]);

    // Collect unique user IDs from both sources
    const candidateIds = new Map<string, number>();

    for (const result of userResults) {
      if (result._id !== args.currentUserId) {
        candidateIds.set(result._id as string, result._score);
      }
    }

    const postDocs = await Promise.all(
      postResults.map((r) => ctx.runQuery(internal.posts.getPost, { postId: r._id }))
    );

    for (let i = 0; i < postDocs.length; i++) {
      const post = postDocs[i];
      if (!post) continue;
      const authorId = post.authorId as string;
      if (authorId === (args.currentUserId as string)) continue;

      const existing = candidateIds.get(authorId);
      if (!existing || postResults[i]._score > existing) {
        candidateIds.set(authorId, postResults[i]._score);
      }
    }

    const sorted = [...candidateIds.entries()]
      .sort((a, b) => b[1] - a[1])
      .slice(0, 12);

    if (sorted.length === 0) {
      return { thinking: "No relevant users found for this query.", results: [] };
    }

    // Phase 2: LLM reasoning — fetch searcher profile + candidates in parallel
    const [searcher, ...candidateResults] = await Promise.all([
      ctx.runQuery(api.users.get, { id: args.currentUserId }),
      ...sorted.map(async ([userId]) => {
        const user = await ctx.runQuery(api.users.get, { id: userId as any });
        const posts = await ctx.runQuery(api.posts.list, {
          authorId: userId as any,
          limit: 1,
        });
        return { user, recentPosts: posts };
      }),
    ]);

    const candidates = candidateResults as { user: any; recentPosts: any[] }[];
    const validCandidates = candidates.filter((c) => c.user !== null);

    if (validCandidates.length === 0) {
      return { thinking: "No relevant users found for this query.", results: [] };
    }

    const searcherContext = buildSearcherContext(searcher);

    const profileSummaries = validCandidates.map((c, i) => {
      const m = c.user!;
      const parts = [
        `Candidate ${i + 1} (ID: ${m._id}):`,
        `  Name: ${m.name}`,
        m.headline ? `  Headline: ${m.headline}` : null,
        m.skills?.length ? `  Skills: ${m.skills.join(", ")}` : null,
        m.interests?.length ? `  Interests: ${m.interests.join(", ")}` : null,
        m.lookingFor ? `  Looking for: ${m.lookingFor}` : null,
        m.canHelpWith ? `  Can help with: ${m.canHelpWith}` : null,
        m.currentProject ? `  Current project: ${m.currentProject}` : null,
      ].filter(Boolean);

      if (c.recentPosts.length > 0) {
        parts.push(`  Recent posts:`);
        for (const post of c.recentPosts) {
          parts.push(`    - [${post.category}] ${post.content.slice(0, 150)}`);
        }
      }

      return parts.join("\n");
    });

    const { object } = await generateObject({
      model: openai("gpt-5-mini"),
      schema: z.object({
        results: z.array(z.object({
          userId: z.string().describe("The candidate's ID"),
          explanation: z.string().max(60).describe("Short human-readable label for why they match. Max 60 chars. No AI-speak, no field references."),
          relevanceScore: z.number().min(0).max(1).describe("How relevant this person is to the query, 0-1"),
        })).describe("Ranked list of matching candidates, best matches first. Only include candidates with relevanceScore >= 0.3"),
        thinking: z.string().describe("A short, casual note to the searcher (use 'you'/'your') describing the people you found and why they fit. 1–2 sentences. No algorithmic language."),
      }),
      system: LLM_SYSTEM_PROMPT,
      prompt: `Search query: "${args.query}"\n\n${searcherContext ? searcherContext + "\n\n" : ""}Candidate profiles:\n${profileSummaries.join("\n\n")}`,
    });

    const userIdSet = new Set(validCandidates.map((c) => c.user!._id as string));

    const baseResults = object.results
      .filter((r) => userIdSet.has(r.userId))
      .map((r) => ({
        userId: r.userId,
        explanation: r.explanation,
        relevanceScore: r.relevanceScore,
      }));

    // Enrich with mutual connections
    const enrichedResults = await Promise.all(
      baseResults.map(async (result) => {
        const mutual = await ctx.runQuery(internal.connections.internalGetMutualConnections, {
          userIdA: args.currentUserId,
          userIdB: result.userId as any,
        });
        return {
          ...result,
          mutualConnectionCount: mutual.count,
          mutualConnectionNames: mutual.names,
          connectionStatus: mutual.connectionStatus,
        };
      })
    );

    return {
      thinking: object.thinking,
      results: enrichedResults,
    };
  },
});
