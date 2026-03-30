import { v } from "convex/values";
import { query, action, internalAction, internalMutation, internalQuery } from "./_generated/server";
import { internal } from "./_generated/api";
import { api } from "./_generated/api";
import { Doc, Id } from "./_generated/dataModel";

// Match types
const MATCH_TYPES = ["complementary", "shared_world", "shared_context", "serendipity"] as const;
type MatchType = (typeof MATCH_TYPES)[number];

// Helper to strip embeddings from user
function stripEmbeddings(user: Doc<"users">) {
  const { profileEmbedding, needsEmbedding, ...rest } = user;
  return rest;
}

// Get Monday of the current week (UTC) as YYYY-MM-DD
function currentWeekMonday(): string {
  const now = new Date();
  const day = now.getUTCDay(); // 0=Sun, 1=Mon, ...
  const diff = day === 0 ? -6 : 1 - day; // Shift to Monday
  const monday = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + diff));
  return monday.toISOString().slice(0, 10);
}

// ── Public query: fetch this week's matches for a user ──

export const getWeeklyMatches = query({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    const weekOf = currentWeekMonday();

    const row = await ctx.db
      .query("weeklyMatchBatches")
      .withIndex("by_user_week", (q) =>
        q.eq("userId", args.userId).eq("weekOf", weekOf)
      )
      .first();

    if (!row || row.matches.length === 0) {
      return [];
    }

    // Fetch full user docs for each match
    const results = await Promise.all(
      row.matches.map(async ({ matchId, matchType, matchReason }) => {
        const user = await ctx.db.get(matchId);
        if (!user) return null;
        return { ...stripEmbeddings(user), matchType, matchReason };
      })
    );

    return results.filter((r) => r !== null);
  },
});

// ── Action: generate matches on-demand for current user (first-open fallback) ──

export const generateForCurrentUser = action({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    await ctx.runAction(internal.weeklyMatches.generateForUser, {
      userId: args.userId,
    });
  },
});

// ── Internal query: check if this week's matches exist ──

export const checkWeekExists = internalQuery({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    const weekOf = currentWeekMonday();
    const row = await ctx.db
      .query("weeklyMatchBatches")
      .withIndex("by_user_week", (q) =>
        q.eq("userId", args.userId).eq("weekOf", weekOf)
      )
      .first();
    return row !== null;
  },
});

// ── Internal action: generate weekly matches for a single user ──

export const generateForUser = internalAction({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    const targetMatchCount = 4; // aim for 4, AI may return 3-5
    const candidatePoolSize = 20;

    // Get current user with embedding
    const currentUser = await ctx.runQuery(internal.users.getWithEmbedding, {
      id: args.userId,
    });
    if (!currentUser || !currentUser.profileEmbedding) {
      await ctx.runMutation(internal.weeklyMatches.saveWeeklyMatches, {
        userId: args.userId,
        matches: [],
      });
      return;
    }

    // Get existing connections to exclude
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

    // Get recent match IDs to avoid repeats
    // At small scale (<50 users), use 2-week lookback to avoid running out of candidates
    const allUserCount = (await ctx.runQuery(internal.weeklyMatches.listActiveUsers, {})).length;
    const lookbackWeeks = allUserCount < 50 ? 2 : 4;
    const recentMatchIds = await ctx.runQuery(
      internal.weeklyMatches.getRecentMatchIds,
      { userId: args.userId, weeks: lookbackWeeks }
    );
    const recentSet = new Set(recentMatchIds);

    // --- Build candidate pool from multiple signals ---

    // 1. Profile similarity (shared world candidates)
    const profileResults = await ctx.vectorSearch("users", "by_profile_embedding", {
      vector: currentUser.profileEmbedding,
      limit: candidatePoolSize + connectedIds.size + recentSet.size + 10,
    });

    // 2. Needs-based search (complementary candidates) — if user has needsEmbedding
    let needsResults: { _id: Id<"users">; _score: number }[] = [];
    if (currentUser.needsEmbedding && currentUser.needsEmbedding.length > 0) {
      needsResults = await ctx.vectorSearch("users", "by_profile_embedding", {
        vector: currentUser.needsEmbedding,
        limit: candidatePoolSize,
      });
    }

    // Combine and deduplicate candidate IDs
    const candidateIdSet = new Set<string>();
    const orderedIds: string[] = [];

    for (const r of [...needsResults, ...profileResults]) {
      const id = r._id as string;
      if (!connectedIds.has(id) && !recentSet.has(id) && !candidateIdSet.has(id)) {
        candidateIdSet.add(id);
        orderedIds.push(id);
      }
    }

    // Fetch full user docs
    const candidateDocs: any[] = [];
    for (const id of orderedIds.slice(0, candidatePoolSize)) {
      const doc = await ctx.runQuery(api.users.get, { id: id as Id<"users"> });
      if (doc) candidateDocs.push(doc);
    }

    if (candidateDocs.length === 0) {
      await ctx.runMutation(internal.weeklyMatches.saveWeeklyMatches, {
        userId: args.userId,
        matches: [],
      });
      return;
    }

    // AI ranks and categorizes matches across the four types
    const ranked = await rankAndCategorizeMatches(currentUser, candidateDocs, targetMatchCount);

    const matches = ranked.map(({ index, matchType, reason }) => ({
      matchId: candidateDocs[index]._id as Id<"users">,
      matchType: matchType as "complementary" | "shared_world" | "shared_context" | "serendipity",
      matchReason: reason,
    }));

    await ctx.runMutation(internal.weeklyMatches.saveWeeklyMatches, {
      userId: args.userId,
      matches,
    });
  },
});

// ── Internal query: get match IDs from recent weeks ──

export const getRecentMatchIds = internalQuery({
  args: { userId: v.id("users"), weeks: v.number() },
  handler: async (ctx, args) => {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - args.weeks * 7);
    const cutoffStr = cutoffDate.toISOString().slice(0, 10);

    const rows = await ctx.db
      .query("weeklyMatchBatches")
      .withIndex("by_user_week", (q) => q.eq("userId", args.userId))
      .collect();

    const matchIds: string[] = [];
    for (const row of rows) {
      if (row.weekOf >= cutoffStr) {
        for (const match of row.matches) {
          matchIds.push(match.matchId);
        }
      }
    }
    return matchIds;
  },
});

// ── Internal mutation: save weekly matches row ──

export const saveWeeklyMatches = internalMutation({
  args: {
    userId: v.id("users"),
    matches: v.array(
      v.object({
        matchId: v.id("users"),
        matchType: v.union(
          v.literal("complementary"),
          v.literal("shared_world"),
          v.literal("shared_context"),
          v.literal("serendipity")
        ),
        matchReason: v.string(),
      })
    ),
  },
  handler: async (ctx, args) => {
    const weekOf = currentWeekMonday();

    // Upsert: delete existing row for this week if any
    const existing = await ctx.db
      .query("weeklyMatchBatches")
      .withIndex("by_user_week", (q) =>
        q.eq("userId", args.userId).eq("weekOf", weekOf)
      )
      .first();

    if (existing) {
      await ctx.db.delete(existing._id);
    }

    await ctx.db.insert("weeklyMatchBatches", {
      userId: args.userId,
      matches: args.matches,
      weekOf,
      generatedAt: Date.now(),
    });
  },
});

// ── Internal mutation: cleanup old match batches ──

export const cleanupOldBatches = internalMutation({
  args: {},
  handler: async (ctx) => {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 28); // Keep 4 weeks
    const cutoffStr = cutoff.toISOString().slice(0, 10);

    const rows = await ctx.db.query("weeklyMatchBatches").collect();
    let deleted = 0;
    for (const row of rows) {
      if (row.weekOf < cutoffStr) {
        await ctx.db.delete(row._id);
        deleted++;
      }
    }
    if (deleted > 0) {
      console.log(`Cleaned up ${deleted} old weeklyMatchBatches rows`);
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
    // Cleanup old batches first
    await ctx.runMutation(internal.weeklyMatches.cleanupOldBatches, {});

    // Get all active user IDs
    const userIds = await ctx.runQuery(
      internal.weeklyMatches.listActiveUsers,
      {}
    );

    console.log(`Generating weekly matches for ${userIds.length} users`);

    for (let i = 0; i < userIds.length; i++) {
      try {
        await ctx.runAction(internal.weeklyMatches.generateForUser, {
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

    console.log(`Weekly match generation complete for ${userIds.length} users`);
  },
});

// ── AI helper: rank and categorize matches across four types ──

function profileSummary(m: any): string {
  const parts: string[] = [];
  if (m.headline) parts.push(`Headline: ${m.headline}`);
  if (m.currentProject) parts.push(`Project: ${m.currentProject}`);
  if (m.lookingFor) parts.push(`Looking for: ${m.lookingFor}`);
  if (m.canHelpWith) parts.push(`Can help with: ${m.canHelpWith}`);
  if (m.skills?.length) parts.push(`Skills: ${m.skills.join(", ")}`);
  if (m.interests?.length) parts.push(`Interests: ${m.interests.join(", ")}`);
  if (m.graduationSemester) parts.push(`Graduating: ${m.graduationSemester}`);
  if (m.programs?.length) parts.push(`Programs: ${m.programs.join(", ")}`);
  return parts.join(" | ");
}

async function rankAndCategorizeMatches(
  currentUser: any,
  candidates: any[],
  targetCount: number
): Promise<{ index: number; matchType: string; reason: string }[]> {
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

Pick ${targetCount} matches from the candidate pool. Each match MUST be categorized as one of four types:

1. **complementary** — One person needs what the other offers. The user is looking for X and this person has X (or vice versa). This is the "they can help you" match.
2. **shared_world** — Same field, same interests, would actually have things to talk about. They're building in the same space.
3. **shared_context** — Same situation. Same stage, same grind, same program, same graduation timeline. They'd get each other's struggles.
4. **serendipity** — Cross-discipline wildcard. Someone from a totally different world who'd bring a fresh perspective. The unexpected connection.

REQUIRED DISTRIBUTION (follow this exactly):
- Pick exactly ${targetCount} matches total.
- You MUST include exactly this mix: 1-2 complementary, 1 shared_world, 1 shared_context, and 0-1 serendipity.
- If you can't find a good fit for a type, skip it — but never pick more than 2 of any single type.
- Each match gets a short reason (max 12 words).

REASON RULES:
- Don't include their name (it's already on the card)
- Start each reason with one of: "They're looking for" or "Yall would" or "Yall are both" or "They can help with" or "Totally different world but"
- Be specific. Mention actual skills or projects or what they're working on.
- Keep it casual not corporate. Write like a college student texts.
- NEVER use dashes or commas. Use periods or "and" instead.
- Keep it short enough to fit on 3 lines of a phone screen (under 10 words).
- No filler like "great person" or "worth connecting with".

BAD MATCHES:
- Both need the same thing (two people looking for a designer doesn't help either)
- No real connection beyond both being "in tech"
- Only one person benefits

Return candidate numbers (1-indexed) with their match type and reason.`,
          },
          { role: "user", content: userMessage },
        ],
        response_format: {
          type: "json_schema",
          json_schema: {
            name: "categorized_matches",
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
                      match_type: {
                        type: "string",
                        enum: ["complementary", "shared_world", "shared_context", "serendipity"],
                      },
                      reason: { type: "string" },
                    },
                    required: ["candidate_number", "match_type", "reason"],
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
      return fallbackRanking(currentUser, candidates, targetCount);
    }

    const data = await response.json();
    const parsed = JSON.parse(data.choices[0].message.content);

    const picks: { index: number; matchType: string; reason: string }[] = [];
    for (const pick of parsed.picks ?? []) {
      const idx = pick.candidate_number - 1;
      if (
        idx >= 0 &&
        idx < candidates.length &&
        MATCH_TYPES.includes(pick.match_type)
      ) {
        picks.push({
          index: idx,
          matchType: pick.match_type,
          reason: pick.reason,
        });
      }
    }

    if (picks.length > 0) return enforceTypeDistribution(picks);

    return fallbackRanking(currentUser, candidates, targetCount);
  } catch (error) {
    console.error("Failed to rank matches:", error);
    return fallbackRanking(currentUser, candidates, targetCount);
  }
}

// ── Post-processing: enforce max 2 of any single type, cap at 5 total ──

function enforceTypeDistribution(
  picks: { index: number; matchType: string; reason: string }[]
): { index: number; matchType: string; reason: string }[] {
  const typeCounts: Record<string, number> = {};
  const result: typeof picks = [];

  for (const pick of picks) {
    const count = typeCounts[pick.matchType] || 0;
    if (count < 2) {
      result.push(pick);
      typeCounts[pick.matchType] = count + 1;
    }
    if (result.length >= 5) break;
  }

  return result;
}

// ── Fallback ranking (no AI) ──

function fallbackRanking(
  currentUser: any,
  candidates: any[],
  limit: number
): { index: number; matchType: string; reason: string }[] {
  const typeRotation: MatchType[] = ["complementary", "shared_world", "shared_context", "serendipity"];
  const usedStyles = new Set<string>();

  return candidates.slice(0, limit).map((match, i) => ({
    index: i,
    matchType: typeRotation[i % typeRotation.length],
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

  if (currentUser.lookingFor && match.canHelpWith) {
    pool.push({
      style: "theyHelp",
      reason: `They can help with ${match.canHelpWith}`,
    });
  }

  if (match.lookingFor && currentUser.canHelpWith) {
    pool.push({
      style: "youHelp",
      reason: `They're looking for ${match.lookingFor}`,
    });
  }

  if (currentUser.skills?.length && match.skills?.length) {
    const shared = currentUser.skills.filter((s: string) =>
      match.skills.some(
        (ms: string) => ms.toLowerCase() === s.toLowerCase()
      )
    );
    if (shared.length >= 1) {
      pool.push({ style: "sharedSkills", reason: `Yall are both into ${shared[0]}` });
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
        reason: `Yall would vibe on ${shared[0]}`,
      });
    }
  }

  if (match.currentProject) {
    pool.push({
      style: "project",
      reason: `Yall would vibe on ${match.currentProject}`,
    });
  }

  for (const entry of pool) {
    if (!usedStyles.has(entry.style)) {
      usedStyles.add(entry.style);
      return entry.reason;
    }
  }

  if (pool.length > 0) return pool[0].reason;
  return `Totally different world but ${firstName} is building cool stuff`;
}
