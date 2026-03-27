import { v } from "convex/values";
import { query, action, internalAction, internalMutation, internalQuery } from "./_generated/server";
import { internal } from "./_generated/api";
import { api } from "./_generated/api";
import { Doc, Id } from "./_generated/dataModel";

// Helper to strip embeddings from user
function stripEmbeddings(user: Doc<"users">) {
  const { profileEmbedding, needsEmbedding, ...rest } = user;
  return rest;
}

// Today's date string in YYYY-MM-DD format (UTC)
function todayDateString(): string {
  return new Date().toISOString().slice(0, 10);
}

// ── Public query: fetch today's daily matches for a user ──

export const getDailyMatches = query({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    const today = todayDateString();

    const row = await ctx.db
      .query("dailyMatches")
      .withIndex("by_user_date", (q) =>
        q.eq("userId", args.userId).eq("date", today)
      )
      .first();

    if (!row || row.matches.length === 0) {
      return [];
    }

    // Fetch full user docs for each match
    const results = await Promise.all(
      row.matches.map(async ({ matchId, matchReason }) => {
        const user = await ctx.db.get(matchId);
        if (!user) return null;
        return { ...stripEmbeddings(user), matchReason };
      })
    );

    return results.filter((r) => r !== null);
  },
});

// ── Action: generate matches on-demand for current user (first-open fallback) ──

export const generateForCurrentUser = action({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    await ctx.runAction(internal.dailyMatches.generateForUser, {
      userId: args.userId,
    });
  },
});

// ── Internal query: check if today's matches exist ──

export const checkTodayExists = internalQuery({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    const today = todayDateString();
    const row = await ctx.db
      .query("dailyMatches")
      .withIndex("by_user_date", (q) =>
        q.eq("userId", args.userId).eq("date", today)
      )
      .first();
    return row !== null;
  },
});

// ── Internal action: generate daily matches for a single user ──

export const generateForUser = internalAction({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    const limit = 5;
    const candidatePoolSize = 15;

    // Get current user with embedding
    const currentUser = await ctx.runQuery(internal.users.getWithEmbedding, {
      id: args.userId,
    });
    if (!currentUser || !currentUser.profileEmbedding) {
      // No embedding — save empty matches so we don't retry
      await ctx.runMutation(internal.dailyMatches.saveDailyMatches, {
        userId: args.userId,
        matches: [],
      });
      return;
    }

    // Get existing connections to exclude (only fully connected, not pending)
    const connections = await ctx.runQuery(api.connections.listAll, {
      userId: args.userId,
    });
    const connectedIds = new Set<string>([
      ...connections
        .filter((c: any) => c.status === "connected")
        .map((c: any) =>
          c.requesterId === args.userId ? c.accepterId : c.requesterId
        ),
      args.userId as string,
    ]);

    // Vector search — pull a wide candidate pool
    const results = await ctx.vectorSearch("users", "by_profile_embedding", {
      vector: currentUser.profileEmbedding,
      limit: candidatePoolSize + connectedIds.size + 5,
    });

    // Get full user docs and filter
    const userDocs: any[] = await Promise.all(
      results.map((r: any) => ctx.runQuery(api.users.get, { id: r._id }))
    );

    const candidates = userDocs
      .filter(
        (m: any) =>
          m !== null &&
          !connectedIds.has(m._id)
      )
      .slice(0, candidatePoolSize);

    if (candidates.length === 0) {
      await ctx.runMutation(internal.dailyMatches.saveDailyMatches, {
        userId: args.userId,
        matches: [],
      });
      return;
    }

    // AI ranks the best matches and generates reasons
    const ranked = await rankAndGenerateReasons(currentUser, candidates, limit);

    const matches = ranked.map(({ index, reason }) => ({
      matchId: candidates[index]._id as Id<"users">,
      matchReason: reason,
    }));

    await ctx.runMutation(internal.dailyMatches.saveDailyMatches, {
      userId: args.userId,
      matches,
    });
  },
});

// ── Internal query: get match IDs from recent days ──

export const getRecentMatchIds = internalQuery({
  args: { userId: v.id("users"), days: v.number() },
  handler: async (ctx, args) => {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - args.days);
    const cutoffStr = cutoffDate.toISOString().slice(0, 10);

    // Get all dailyMatches rows for this user, filter by date >= cutoff
    const rows = await ctx.db
      .query("dailyMatches")
      .withIndex("by_user_date", (q) => q.eq("userId", args.userId))
      .collect();

    const matchIds: string[] = [];
    for (const row of rows) {
      if (row.date >= cutoffStr) {
        for (const match of row.matches) {
          matchIds.push(match.matchId);
        }
      }
    }
    return matchIds;
  },
});

// ── Internal mutation: save daily matches row ──

export const saveDailyMatches = internalMutation({
  args: {
    userId: v.id("users"),
    matches: v.array(
      v.object({
        matchId: v.id("users"),
        matchReason: v.string(),
      })
    ),
  },
  handler: async (ctx, args) => {
    const today = todayDateString();

    // Upsert: delete existing row for today if any
    const existing = await ctx.db
      .query("dailyMatches")
      .withIndex("by_user_date", (q) =>
        q.eq("userId", args.userId).eq("date", today)
      )
      .first();

    if (existing) {
      await ctx.db.delete(existing._id);
    }

    await ctx.db.insert("dailyMatches", {
      userId: args.userId,
      matches: args.matches,
      date: today,
      generatedAt: Date.now(),
    });
  },
});

// ── Internal mutation: cleanup old matches ──

export const cleanupOldMatches = internalMutation({
  args: {},
  handler: async (ctx) => {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 7);
    const cutoffStr = cutoff.toISOString().slice(0, 10);

    // Query all dailyMatches and delete old ones
    const rows = await ctx.db.query("dailyMatches").collect();
    let deleted = 0;
    for (const row of rows) {
      if (row.date < cutoffStr) {
        await ctx.db.delete(row._id);
        deleted++;
      }
    }
    if (deleted > 0) {
      console.log(`Cleaned up ${deleted} old dailyMatches rows`);
    }
  },
});

// ── Internal query: list active users with embeddings ──

export const listActiveUsers = internalQuery({
  args: {},
  handler: async (ctx) => {
    const users = await ctx.db.query("users").collect();
    return users
      .filter((m) => m.isOnboarded && m.profileEmbedding && m.profileEmbedding.length > 0)
      .map((m) => m._id);
  },
});

// ── Internal action: generate matches for all users (called by cron) ──

export const generateForAllUsers = internalAction({
  args: {},
  handler: async (ctx) => {
    // Cleanup old matches first
    await ctx.runMutation(internal.dailyMatches.cleanupOldMatches, {});

    // Get all active user IDs
    const userIds = await ctx.runQuery(
      internal.dailyMatches.listActiveUsers,
      {}
    );

    console.log(`Generating daily matches for ${userIds.length} users`);

    for (let i = 0; i < userIds.length; i++) {
      try {
        await ctx.runAction(internal.dailyMatches.generateForUser, {
          userId: userIds[i],
        });
      } catch (error) {
        console.error(
          `Failed to generate matches for user ${userIds[i]}:`,
          error
        );
      }

      // Small delay between calls for rate limit safety (100ms)
      if (i < userIds.length - 1) {
        await new Promise((resolve) => setTimeout(resolve, 100));
      }
    }

    console.log(`Daily match generation complete for ${userIds.length} users`);
  },
});

// ── AI helper functions (moved from users.ts) ──

function profileSummary(m: any): string {
  const parts: string[] = [];
  if (m.headline) parts.push(`Headline: ${m.headline}`);
  if (m.currentProject) parts.push(`Project: ${m.currentProject}`);
  if (m.lookingFor) parts.push(`Looking for: ${m.lookingFor}`);
  if (m.canHelpWith) parts.push(`Can help with: ${m.canHelpWith}`);
  if (m.skills?.length) parts.push(`Skills: ${m.skills.join(", ")}`);
  if (m.interests?.length) parts.push(`Interests: ${m.interests.join(", ")}`);
  return parts.join(" | ");
}

async function rankAndGenerateReasons(
  currentUser: any,
  candidates: any[],
  limit: number
): Promise<{ index: number; reason: string }[]> {
  const candidateProfiles = candidates
    .map(
      (m: any, i: number) =>
        `Candidate ${i + 1} (${m.name}):\n${profileSummary(m)}`
    )
    .join("\n\n");

  const userMessage = `User profile (${currentUser.name}):\n${profileSummary(currentUser)}\n\nCandidate pool (${candidates.length} people):\n\n${candidateProfiles}`;

  try {
    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
      },
      body: JSON.stringify({
        model: "gpt-5-nano",
        messages: [
          {
            role: "system",
            content: `You're matching people on Junto — a community app for college students who are building things (startups, side projects, creative work, etc).

Pick the ${limit} best matches from the candidate pool and rank them best to worst. For each pick, write a short reason (max 12 words) explaining why they'd vibe.

How to pick matches (in priority order):
1. They can help each other — one needs what the other offers (e.g. someone needs a designer and the other IS a designer)
2. They could build something together — their skills or projects combine in a cool way
3. Same world — they're into the same stuff and would actually have things to talk about
4. Same energy — similar stage, similar grind, could support each other

Bad matches:
- Both need the same thing (two people looking for a designer doesn't help either)
- No real connection beyond both being "in tech"
- Only one person benefits

Rules for reasons:
- Don't include their name (it's already on the card)
- Start each reason with one of these phrases: "They're looking for" or "Yall would" or "Yall are both" or "They can help with"
- Be specific. Mention actual skills or projects or what they're working on
- Keep it casual not corporate. Write like a college student texts
- NEVER use dashes or commas. Use periods or "and" instead
- Keep it short enough to fit on 3 lines of a phone screen (under 10 words)
- No filler like "great person" or "worth connecting with"

Return candidate numbers (1-indexed) of your top ${limit} picks, best to worst.`,
          },
          { role: "user", content: userMessage },
        ],
        response_format: {
          type: "json_schema",
          json_schema: {
            name: "ranked_matches",
            strict: true,
            schema: {
              type: "object",
              properties: {
                picks: {
                  type: "array",
                  items: {
                    type: "object",
                    properties: {
                      candidate_number: { type: "integer" },
                      reason: { type: "string" },
                    },
                    required: ["candidate_number", "reason"],
                    additionalProperties: false,
                  },
                },
              },
              required: ["picks"],
              additionalProperties: false,
            },
          },
        },
      }),
    });

    if (!response.ok) {
      console.error("OpenAI API error:", response.status, await response.text());
      return fallbackRanking(currentUser, candidates, limit);
    }

    const data = await response.json();
    const parsed = JSON.parse(data.choices[0].message.content);

    const picks: { index: number; reason: string }[] = [];
    for (const pick of parsed.picks ?? []) {
      const idx = pick.candidate_number - 1;
      if (idx >= 0 && idx < candidates.length) {
        picks.push({ index: idx, reason: pick.reason });
      }
    }

    if (picks.length > 0) return picks.slice(0, limit);

    return fallbackRanking(currentUser, candidates, limit);
  } catch (error) {
    console.error("Failed to rank matches:", error);
    return fallbackRanking(currentUser, candidates, limit);
  }
}

function fallbackRanking(
  currentUser: any,
  candidates: any[],
  limit: number
): { index: number; reason: string }[] {
  const usedStyles = new Set<string>();
  return candidates.slice(0, limit).map((match, i) => ({
    index: i,
    reason: fallbackReason(currentUser, match, usedStyles),
  }));
}

function fallbackReason(
  currentUser: any,
  match: any,
  usedStyles: Set<string>
): string {
  const firstName = match.name.split(" ")[0];
  const pool: { style: string; reason: string }[] = [];

  if (currentUser.skills?.length && match.skills?.length) {
    const shared = currentUser.skills.filter((s: string) =>
      match.skills.some(
        (ms: string) => ms.toLowerCase() === s.toLowerCase()
      )
    );
    if (shared.length >= 1) {
      pool.push({ style: "sharedSkills", reason: `You both know ${shared[0]}` });
    }
  }

  if (currentUser.interests?.length && match.interests?.length) {
    const shared = currentUser.interests.filter((i: string) =>
      match.interests.some(
        (mi: string) => mi.toLowerCase() === i.toLowerCase()
      )
    );
    if (shared.length >= 1) {
      pool.push({
        style: "sharedInterests",
        reason: `Also into ${shared[0]}`,
      });
    }
  }

  if (currentUser.lookingFor && match.canHelpWith) {
    pool.push({
      style: "theyHelp",
      reason: `Could help you with ${match.canHelpWith}`,
    });
  }

  if (match.lookingFor && currentUser.canHelpWith) {
    pool.push({
      style: "youHelp",
      reason: `Needs ${match.lookingFor} and you got it`,
    });
  }

  if (match.currentProject) {
    pool.push({
      style: "project",
      reason: `Working on ${match.currentProject}`,
    });
  }

  if (match.skills?.length) {
    pool.push({
      style: "skills",
      reason: `${firstName} is into ${match.skills.slice(0, 2).join(" and ")}`,
    });
  }

  if (match.lookingFor) {
    pool.push({
      style: "lookingFor",
      reason: `Looking for ${match.lookingFor}`,
    });
  }

  for (const entry of pool) {
    if (!usedStyles.has(entry.style)) {
      usedStyles.add(entry.style);
      return entry.reason;
    }
  }

  if (pool.length > 0) return pool[0].reason;
  return `${firstName} is building in the same space as you`;
}
