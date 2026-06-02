import { v } from "convex/values";
import { query } from "./_generated/server";
import { Doc, Id } from "./_generated/dataModel";

// ── Tuning ──
const MATCH_EVERY_N_POSTS = 4; // inject one match after every N posts (page 0 only)
const EVENT_POSITION = 1; // inject the soonest event after this many posts (page 0 only)
const MAX_MATCH_TAGS = 2; // skill categories shown on a match card

// ── Helpers (kept local so this module is self-contained) ──

function stripPostEmbedding(post: Doc<"posts">) {
  return {
    _id: post._id,
    _creationTime: post._creationTime,
    authorId: post.authorId,
    content: post.content,
    category: post.category,
    topics: post.topics ?? [],
    imageUrl: post.imageUrl,
    imageUrls: post.imageUrls,
    linkUrl: post.linkUrl,
    gifUrl: post.gifUrl,
    createdAt: post.createdAt,
    updatedAt: post.updatedAt,
  };
}

function stripUserEmbeddings(user: Doc<"users">) {
  const { profileEmbedding, needsEmbedding, ...rest } = user;
  return rest;
}

function cosineSimilarity(a: number[], b: number[]): number {
  let dot = 0;
  let normA = 0;
  let normB = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA === 0 || normB === 0) return 0;
  return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}

// Same scoring as posts.getFeed: connections (tier) + recency + relevance
function calculateFeedScore(
  post: Doc<"posts">,
  isConnection: boolean,
  userEmbedding: number[] | null,
  now: number
): number {
  const tierWeight = isConnection ? 10000 : 0;
  const ageHours = (now - post.createdAt) / (1000 * 60 * 60);
  const recencyScore = Math.max(0, 1000 * Math.exp(-ageHours / 24));
  let relevanceScore = 0;
  if (userEmbedding && post.embedding) {
    const similarity = cosineSimilarity(userEmbedding, post.embedding);
    relevanceScore = Math.max(0, (similarity - 0.3) * 714);
  }
  return tierWeight + recencyScore + relevanceScore;
}

async function resolveImageUrl(
  ctx: { storage: { getUrl: (id: any) => Promise<string | null> } },
  url: string | null | undefined
): Promise<string | undefined> {
  if (!url) return undefined;
  if (url.startsWith("http")) return url;
  return (await ctx.storage.getUrl(url as any)) ?? undefined;
}

// Monday (UTC) of the current week as YYYY-MM-DD — matches weeklyMatches.ts
function currentWeekMonday(): string {
  const now = new Date();
  const day = now.getUTCDay();
  const diff = day === 0 ? -6 : 1 - day;
  const monday = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + diff)
  );
  return monday.toISOString().slice(0, 10);
}

// ── Unified feed ──
// Returns one ordered list of typed items: posts are the spine (scored like
// posts.getFeed), with the soonest upcoming event and this week's matches
// injected into page 0. Pages 1+ are posts-only so infinite scroll never
// repeats an event/match. `offset` counts POSTS already loaded.
export const getFeed = query({
  args: {
    userId: v.id("users"),
    limit: v.optional(v.number()),
    offset: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const limit = args.limit ?? 20;
    const offset = args.offset ?? 0;
    const isFirstPage = offset === 0;
    const now = Date.now();

    const currentUser = await ctx.db.get(args.userId);
    const userEmbedding = currentUser?.profileEmbedding ?? null;
    const userUniversityId = currentUser?.universityId ?? null;

    // --- Connections (for tier weighting) ---
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
    const connectionIds = new Set<string>([
      ...asRequester.map((c) => c.accepterId),
      ...asAccepter.map((c) => c.requesterId),
    ]);

    // --- Post spine (scored + paginated, same as posts.getFeed) ---
    const allPosts = await ctx.db
      .query("posts")
      .withIndex("by_created")
      .order("desc")
      .take((offset + limit) * 2);

    const scoredPosts = allPosts
      .map((post) => ({
        post,
        score: calculateFeedScore(
          post,
          connectionIds.has(post.authorId),
          userEmbedding,
          now
        ),
      }))
      .sort((a, b) => b.score - a.score);

    const pagePosts = scoredPosts
      .slice(offset, offset + limit)
      .map((sp) => sp.post);

    // Enrich posts: author, comment count, recent commenters
    const postItems = await Promise.all(
      pagePosts.map(async (post) => {
        const author = await ctx.db.get(post.authorId);
        const comments = await ctx.db
          .query("comments")
          .withIndex("by_post", (q) => q.eq("postId", post._id))
          .order("desc")
          .collect();

        const seen = new Set<string>();
        const recentCommenters: {
          _id: string;
          name: string;
          avatarUrl: string | undefined;
        }[] = [];
        for (const comment of comments) {
          if (!seen.has(comment.authorId) && recentCommenters.length < 3) {
            seen.add(comment.authorId);
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

        const stripped = stripPostEmbedding(post);
        return {
          kind: "post" as const,
          key: `post:${post._id}`,
          tags: stripped.topics,
          post: {
            ...stripped,
            author: author ? stripUserEmbeddings(author) : null,
            commentCount: comments.length,
            recentCommenters,
          },
        };
      })
    );

    // Pages 1+ are posts-only — return the spine as-is.
    if (!isFirstPage) {
      return postItems;
    }

    // --- Soonest upcoming event (page 0 only) ---
    let eventItem: any = null;
    {
      const events = await ctx.db.query("events").withIndex("by_date").collect();
      let upcoming = events.filter((e) => e.date > now);
      if (userUniversityId) {
        const scoped = upcoming.filter((e) => e.universityId === userUniversityId);
        // Fall back to all upcoming if this university has none.
        upcoming = scoped.length > 0 ? scoped : upcoming;
      }
      upcoming.sort((a, b) => a.date - b.date);
      const event = upcoming[0];
      if (event) {
        const host = await ctx.db.get(event.createdBy);
        const rsvps = await ctx.db
          .query("eventRsvps")
          .withIndex("by_event", (q) => q.eq("eventId", event._id))
          .collect();
        const goingCount = rsvps.filter((r) => r.status === "going").length;
        const previewRsvps = rsvps
          .filter((r) => r.status === "going")
          .slice(0, 3);
        const attendeePreviews = (
          await Promise.all(
            previewRsvps.map(async (r) => {
              const u = await ctx.db.get(r.userId);
              return u ? { id: u._id, name: u.name, avatarUrl: u.avatarUrl } : null;
            })
          )
        ).filter(Boolean);

        eventItem = {
          kind: "event" as const,
          key: `event:${event._id}`,
          event: {
            ...event,
            imageUrl: await resolveImageUrl(ctx, event.imageUrl),
            hostName: event.hostName ?? host?.name ?? null,
            host: host
              ? { id: host._id, name: host.name, avatarUrl: host.avatarUrl }
              : null,
            goingCount,
            attendeePreviews,
          },
        };
      }
    }

    // --- This week's matches (page 0 only) ---
    const matchItems: any[] = [];
    {
      const weekOf = currentWeekMonday();
      const batch = await ctx.db
        .query("weeklyMatchBatches")
        .withIndex("by_user_week", (q) =>
          q.eq("userId", args.userId).eq("weekOf", weekOf)
        )
        .first();

      if (batch && batch.matches.length > 0) {
        // Build a skill id/name → category map once for tag resolution.
        const allSkills = await ctx.db.query("skills").collect();
        const skillCategoryById = new Map<string, string>();
        for (const s of allSkills) {
          skillCategoryById.set(s._id as string, s.category);
        }

        for (const m of batch.matches) {
          const user = await ctx.db.get(m.matchId as Id<"users">);
          if (!user) continue;

          // Resolve the person's skills → distinct skill categories (the tag pills).
          const tags: string[] = [];
          for (const skillVal of user.skills ?? []) {
            const category =
              skillCategoryById.get(skillVal as string) ?? (skillVal as string);
            if (category && !tags.includes(category)) tags.push(category);
            if (tags.length >= MAX_MATCH_TAGS) break;
          }

          matchItems.push({
            kind: "match" as const,
            key: `match:${user._id}`,
            tags,
            match: {
              ...stripUserEmbeddings(user),
              matchType: m.matchType,
              matchReason: m.matchReason,
            },
          });
        }
      }
    }

    // --- Interleave: posts spine + event near top + matches every N posts ---
    const items: any[] = [];
    let matchCursor = 0;
    let eventInjected = false;

    for (let i = 0; i < postItems.length; i++) {
      items.push(postItems[i]);
      const postsSoFar = i + 1;

      if (!eventInjected && eventItem && postsSoFar === EVENT_POSITION) {
        items.push(eventItem);
        eventInjected = true;
      }

      if (
        postsSoFar % MATCH_EVERY_N_POSTS === 0 &&
        matchCursor < matchItems.length
      ) {
        items.push(matchItems[matchCursor++]);
      }
    }

    // If the page was short (few posts), make sure the event still appears.
    if (!eventInjected && eventItem) {
      items.unshift(eventItem);
    }
    // Append any matches that didn't fit the cadence so they aren't lost.
    while (matchCursor < matchItems.length) {
      items.push(matchItems[matchCursor++]);
    }

    return items;
  },
});
