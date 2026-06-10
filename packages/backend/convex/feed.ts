import { v } from "convex/values";
import { query } from "./_generated/server";
import { Doc, Id } from "./_generated/dataModel";
import { scorePost } from "./feedScoring";

// ── Tuning ──
const INJECT_EVERY_N_POSTS = 5; // pop one filler card after every N posts (page 0)
const EVENT_TOP_SLOT = 2; // imminent event injected after this many posts
const IMMINENT_EVENT_MS = 48 * 60 * 60 * 1000; // event is "imminent" if within 48h
const MAX_MATCH_TAGS = 2; // skill categories shown on a person card
const MAX_NEW_MAKERS = 6; // people-discovery cards mined from the roster
const SPINE_THIN_THRESHOLD = 5; // below this, the feed leans on manufactured cards
const WEEK_MS = 7 * 24 * 60 * 60 * 1000;
const MILESTONES = [5, 10, 25, 50, 100];

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

// Resolve a person's skills → distinct skill categories (the tag pills on a
// person card). Takes a prebuilt skillId→category map to avoid re-querying.
function tagsForUser(
  user: Doc<"users">,
  skillCategoryById: Map<string, string>
): string[] {
  const tags: string[] = [];
  for (const skillVal of user.skills ?? []) {
    const category =
      skillCategoryById.get(skillVal as string) ?? (skillVal as string);
    if (category && !tags.includes(category)) tags.push(category);
    if (tags.length >= MAX_MATCH_TAGS) break;
  }
  return tags;
}

// ── Unified feed ──
// One ordered list of typed cards. Asks + Updates are the scored spine; Matches,
// Opportunities (events), and manufactured cards (new makers, digest, momentum,
// vouch, milestone, prompt) are injected on page 0 so the feed stays full even
// on a near-empty campus. Page 0 ends with a `caught_up` sentinel (finite feed).
// Pages 1+ are spine-only so infinite scroll never repeats an injected card.
// `offset` counts POSTS already loaded. See docs/feed-spec.md.
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
    const weekStart = now - WEEK_MS;

    const currentUser = await ctx.db.get(args.userId);
    const profileEmbedding = currentUser?.profileEmbedding ?? null;
    const needsEmbedding = currentUser?.needsEmbedding ?? null;
    const userUniversityId = currentUser?.universityId ?? null;

    // --- Connections (tier weighting + already-acted) ---
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
    // Real connection count, captured before weekly-match ids are folded into
    // `connectionIds` below (those are added only to de-dupe people-discovery).
    const realConnectionCount = connectionIds.size;

    // Posts I've already acted on: I commented, or I connected from this post.
    const myComments = await ctx.db
      .query("comments")
      .withIndex("by_author", (q) => q.eq("authorId", args.userId))
      .collect();
    const actedPostIds = new Set<string>(myComments.map((c) => c.postId));
    for (const c of [...asRequester, ...asAccepter]) {
      if (c.source?.type === "post" && c.source.referenceId) {
        actedPostIds.add(c.source.referenceId);
      }
    }

    // Posts I've reported (hide them). No by-reporter index; the table is small.
    const myReports = await ctx.db
      .query("reports")
      .filter((q) => q.eq(q.field("reporterId"), args.userId))
      .collect();
    const reportedPostIds = new Set<string>(myReports.map((r) => r.postId));

    // --- Post spine (scored + paginated), excluding own/reported posts ---
    const allPosts = await ctx.db
      .query("posts")
      .withIndex("by_created")
      .order("desc")
      .take((offset + limit) * 2 + 10);

    const eligiblePosts = allPosts.filter(
      (p) => p.authorId !== args.userId && !reportedPostIds.has(p._id)
    );

    // We need each post's comment count for both the engagement signal and the
    // card payload — fetch comments once per post, reuse.
    const postsWithComments = await Promise.all(
      eligiblePosts.map(async (post) => {
        const comments = await ctx.db
          .query("comments")
          .withIndex("by_post", (q) => q.eq("postId", post._id))
          .order("desc")
          .collect();
        return { post, comments };
      })
    );

    const scored = postsWithComments
      .map(({ post, comments }) => ({
        post,
        comments,
        score: scorePost({
          post,
          isConnection: connectionIds.has(post.authorId),
          profileEmbedding,
          needsEmbedding,
          responseCount: comments.length,
          alreadyActed: actedPostIds.has(post._id),
          now,
        }),
      }))
      .sort((a, b) => b.score - a.score);

    const page = scored.slice(offset, offset + limit);

    // Enrich spine posts: author + comment count + recent commenters
    const postItems = await Promise.all(
      page.map(async ({ post, comments }) => {
        const author = await ctx.db.get(post.authorId);

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

    // Pages 1+ are spine-only — return as-is.
    if (!isFirstPage) {
      return postItems;
    }

    // ════════════════════════ PAGE 0: manufactured cards ════════════════════════

    // Build a skillId→category map once for all person-card tag resolution.
    const allSkills = await ctx.db.query("skills").collect();
    const skillCategoryById = new Map<string, string>();
    for (const s of allSkills) {
      skillCategoryById.set(s._id as string, s.category);
    }

    // --- Matches: this week's batch (hero + spread through the feed) ---
    const matchItems: any[] = [];
    {
      const batch = await ctx.db
        .query("weeklyMatchBatches")
        .withIndex("by_user_week", (q) =>
          q.eq("userId", args.userId).eq("weekOf", currentWeekMonday())
        )
        .first();

      if (batch && batch.matches.length > 0) {
        for (const m of batch.matches) {
          const user = await ctx.db.get(m.matchId as Id<"users">);
          if (!user) continue;
          connectionIds.add(user._id); // de-dupe against new-maker mining below
          matchItems.push({
            kind: "match" as const,
            key: `match:${user._id}`,
            tags: tagsForUser(user, skillCategoryById),
            match: {
              ...stripUserEmbeddings(user),
              matchType: m.matchType,
              matchReason: m.matchReason,
            },
          });
        }
      }
    }

    // --- New makers / people-discovery: mine the roster (scales with campus
    //     SIZE, not posting activity). Reuses the `match` person card. ---
    const peopleItems: any[] = [];
    {
      const candidates = userUniversityId
        ? await ctx.db
            .query("users")
            .withIndex("by_university", (q) =>
              q.eq("universityId", userUniversityId)
            )
            .collect()
        : await ctx.db.query("users").collect();

      const fresh = candidates
        .filter(
          (u) =>
            u._id !== args.userId &&
            u.isOnboarded &&
            !connectionIds.has(u._id)
        )
        .sort((a, b) => b.createdAt - a.createdAt) // newest joiners first
        .slice(0, MAX_NEW_MAKERS);

      for (const user of fresh) {
        const isNew = user.createdAt > weekStart;
        peopleItems.push({
          kind: "match" as const,
          key: `person:${user._id}`,
          tags: tagsForUser(user, skillCategoryById),
          match: {
            ...stripUserEmbeddings(user),
            matchType: "serendipity",
            matchReason: isNew
              ? "New on campus — say hi"
              : "Someone you should know",
          },
        });
      }
    }

    // --- Opportunity: soonest upcoming event, university-scoped ---
    let eventItem: any = null;
    let eventImminent = false;
    {
      const events = await ctx.db.query("events").withIndex("by_date").collect();
      let upcoming = events.filter((e) => e.date > now);
      if (userUniversityId) {
        const scoped = upcoming.filter(
          (e) => e.universityId === userUniversityId
        );
        upcoming = scoped.length > 0 ? scoped : upcoming;
      }
      upcoming.sort((a, b) => a.date - b.date);
      const event = upcoming[0];
      if (event) {
        eventImminent = event.date - now <= IMMINENT_EVENT_MS;
        const host = await ctx.db.get(event.createdBy);
        const rsvps = await ctx.db
          .query("eventRsvps")
          .withIndex("by_event", (q) => q.eq("eventId", event._id))
          .collect();
        const going = rsvps.filter((r) => r.status === "going");
        const attendeePreviews = (
          await Promise.all(
            going.slice(0, 3).map(async (r) => {
              const u = await ctx.db.get(r.userId);
              return u
                ? { id: u._id, name: u.name, avatarUrl: u.avatarUrl }
                : null;
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
            goingCount: going.length,
            attendeePreviews,
          },
        };
      }
    }

    // --- Digest: this week's campus activity in one card ---
    let digestItem: any = null;
    {
      const newMakers = (
        userUniversityId
          ? await ctx.db
              .query("users")
              .withIndex("by_university", (q) =>
                q.eq("universityId", userUniversityId)
              )
              .collect()
          : await ctx.db.query("users").collect()
      ).filter((u) => u.isOnboarded && u.createdAt > weekStart).length;

      const newAsks = scored.filter(
        ({ post }) => post.createdAt > weekStart && post.category !== "sharing"
      ).length;

      const upcomingEvents = (
        await ctx.db.query("events").withIndex("by_date").collect()
      ).filter(
        (e) =>
          e.date > now &&
          (!userUniversityId || e.universityId === userUniversityId)
      ).length;

      if (newMakers > 0 || newAsks > 0 || upcomingEvents > 0) {
        digestItem = {
          kind: "digest" as const,
          key: `digest:${currentWeekMonday()}`,
          digest: { newMakers, newAsks, upcomingEvents },
        };
      }
    }

    // --- Momentum: connections made across the platform this week ---
    let momentumItem: any = null;
    {
      const connectedThisWeek = (
        await ctx.db
          .query("connections")
          .withIndex("by_status", (q) => q.eq("status", "connected"))
          .collect()
      ).filter((c) => (c.connectedAt ?? c.createdAt) > weekStart).length;

      if (connectedThisWeek > 0) {
        momentumItem = {
          kind: "momentum" as const,
          key: `momentum:${currentWeekMonday()}`,
          momentum: { connectionsThisWeek: connectedThisWeek },
        };
      }
    }

    // --- Vouch: vouches I received this week ("Alex vouched for you") ---
    let vouchItem: any = null;
    {
      const recentVouch = (
        await ctx.db
          .query("vouches")
          .withIndex("by_to_user", (q) => q.eq("toUserId", args.userId))
          .order("desc")
          .collect()
      ).find((vch) => vch.createdAt > weekStart);

      if (recentVouch) {
        const fromUser = await ctx.db.get(recentVouch.fromUserId);
        if (fromUser) {
          vouchItem = {
            kind: "vouch" as const,
            key: `vouch:${recentVouch._id}`,
            vouch: {
              _id: recentVouch._id,
              reason: recentVouch.reason,
              createdAt: recentVouch.createdAt,
              fromUser: {
                _id: fromUser._id,
                name: fromUser.name,
                avatarUrl: fromUser.avatarUrl,
                headline: fromUser.headline,
              },
            },
          };
        }
      }
    }

    // --- Milestone: I just crossed a connection milestone ---
    let milestoneItem: any = null;
    {
      // Only celebrate when freshly crossed (within +2 of the threshold), since
      // there's no per-user "seen" state yet — avoids showing it forever.
      const justCrossed = MILESTONES.find(
        (m) => realConnectionCount >= m && realConnectionCount < m + 3
      );
      if (justCrossed) {
        milestoneItem = {
          kind: "milestone" as const,
          key: `milestone:${justCrossed}`,
          milestone: { count: justCrossed },
        };
      }
    }

    // --- Prompt: nudge to post if I've been quiet for 7 days ---
    let promptItem: any = null;
    {
      const myLatestPost = await ctx.db
        .query("posts")
        .withIndex("by_author", (q) => q.eq("authorId", args.userId))
        .order("desc")
        .first();
      const quiet = !myLatestPost || myLatestPost.createdAt < weekStart;
      if (quiet) {
        promptItem = {
          kind: "prompt" as const,
          key: `prompt:${currentWeekMonday()}`,
          prompt: { text: "What do you need right now?" },
        };
      }
    }

    // ════════════════════════ Assembly ════════════════════════

    const items: any[] = [];

    // Hero: the strongest re-engagement card opens the feed.
    const heroMatch = matchItems.shift() ?? null;
    if (heroMatch) items.push(heroMatch);

    // Filler queue, popped between posts and then drained so nothing is lost
    // (this is what keeps a sparse feed full). Imminent events lead.
    const fillers: any[] = [];
    if (eventItem && eventImminent) fillers.push(eventItem);
    fillers.push(...matchItems, ...peopleItems);
    if (digestItem) fillers.push(digestItem);
    if (momentumItem) fillers.push(momentumItem);
    if (vouchItem) fillers.push(vouchItem);
    if (milestoneItem) fillers.push(milestoneItem);
    if (eventItem && !eventImminent) fillers.push(eventItem);

    for (let i = 0; i < postItems.length; i++) {
      items.push(postItems[i]);
      const postsSoFar = i + 1;

      // Drop an imminent event near the very top.
      if (
        eventItem &&
        eventImminent &&
        postsSoFar === EVENT_TOP_SLOT &&
        fillers[0] === eventItem
      ) {
        items.push(fillers.shift());
        continue;
      }

      if (postsSoFar % INJECT_EVERY_N_POSTS === 0 && fillers.length > 0) {
        items.push(fillers.shift());
      }
    }

    // Is the whole spine on this page? (No page 1 to load.) Only then do the
    // terminal cards belong at the end — otherwise they'd strand mid-feed once
    // load-more appends the next page of posts.
    const spineExhausted = scored.length <= offset + limit;

    if (!spineExhausted && promptItem) {
      // More posts exist — fold the prompt into the interleave instead of trailing it.
      fillers.push(promptItem);
    }

    // Drain remaining fillers — on a thin spine this is most of the feed.
    while (fillers.length > 0) items.push(fillers.shift());

    if (spineExhausted) {
      if (promptItem) items.push(promptItem);
      items.push({ kind: "caught_up" as const, key: "caught_up" });
    }

    return items;
  },
});
