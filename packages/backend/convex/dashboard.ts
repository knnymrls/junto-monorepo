import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

// ============================================================
// Dashboard aggregate queries for university analytics frontend
// ============================================================

const DAY_MS = 24 * 60 * 60 * 1000;
const WEEK_MS = 7 * DAY_MS;

// Helper: get start of current and previous week windows
function getWeekBoundaries(now: number) {
  const thisWeekStart = now - WEEK_MS;
  const lastWeekStart = thisWeekStart - WEEK_MS;
  return { now, thisWeekStart, lastWeekStart };
}

// Helper: calculate week-over-week change as a percentage
function wowChange(thisWeek: number, lastWeek: number): number {
  if (lastWeek === 0) return thisWeek > 0 ? 100 : 0;
  return Math.round(((thisWeek - lastWeek) / lastWeek) * 100);
}

// Helper: get Monday-based ISO week string from timestamp
function weekLabel(ts: number): string {
  const d = new Date(ts);
  // Shift to Monday-based week
  const day = d.getUTCDay();
  const diff = d.getUTCDate() - day + (day === 0 ? -6 : 1);
  const monday = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), diff));
  return monday.toISOString().slice(0, 10);
}

// Helper: normalize a skill string (trim, lowercase)
function normalizeSkill(s: string): string {
  return s.trim().toLowerCase();
}

// -------------------------------------------------------
// 1. overview — KPI cards for the top of the dashboard
// -------------------------------------------------------
export const overview = query({
  args: {},
  handler: async (ctx) => {
    const now = Date.now();
    const { thisWeekStart, lastWeekStart } = getWeekBoundaries(now);

    // --- Total members (onboarded) ---
    const allUsers = await ctx.db.query("users").collect();
    const onboardedUsers = allUsers.filter((m) => m.isOnboarded);
    const totalMembers = onboardedUsers.length;

    const membersThisWeek = onboardedUsers.filter(
      (m) => m.createdAt >= thisWeekStart
    ).length;
    const membersLastWeek = onboardedUsers.filter(
      (m) => m.createdAt >= lastWeekStart && m.createdAt < thisWeekStart
    ).length;

    // --- Active users (activity in last 7 days) ---
    const activeIds = new Set<string>();

    // Posts this week
    const allPosts = await ctx.db.query("posts").withIndex("by_created").collect();
    const postsThisWeekList = allPosts.filter((p) => p.createdAt >= thisWeekStart);
    for (const p of postsThisWeekList) activeIds.add(p.authorId);

    const postsLastWeekList = allPosts.filter(
      (p) => p.createdAt >= lastWeekStart && p.createdAt < thisWeekStart
    );

    // Comments this week
    const allComments = await ctx.db.query("comments").collect();
    const commentsThisWeek = allComments.filter((c) => c.createdAt >= thisWeekStart);
    for (const c of commentsThisWeek) activeIds.add(c.authorId);

    // Connections this week
    const allConnections = await ctx.db.query("connections").collect();
    const connectionsThisWeek = allConnections.filter(
      (c) => c.status === "connected" && c.createdAt >= thisWeekStart
    );
    for (const c of connectionsThisWeek) {
      activeIds.add(c.requesterId);
      activeIds.add(c.accepterId);
    }

    // Messages this week
    const allMessages = await ctx.db.query("messages").collect();
    const messagesThisWeek = allMessages.filter((m) => m.createdAt >= thisWeekStart);
    for (const m of messagesThisWeek) activeIds.add(m.senderId);

    const activeUsers = activeIds.size;

    // Active users last week (same logic, different window)
    const activeIdsLastWeek = new Set<string>();
    for (const p of postsLastWeekList) activeIdsLastWeek.add(p.authorId);
    const commentsLastWeek = allComments.filter(
      (c) => c.createdAt >= lastWeekStart && c.createdAt < thisWeekStart
    );
    for (const c of commentsLastWeek) activeIdsLastWeek.add(c.authorId);
    const connectionsLastWeek = allConnections.filter(
      (c) =>
        c.status === "connected" &&
        c.createdAt >= lastWeekStart &&
        c.createdAt < thisWeekStart
    );
    for (const c of connectionsLastWeek) {
      activeIdsLastWeek.add(c.requesterId);
      activeIdsLastWeek.add(c.accepterId);
    }
    const messagesLastWeek = allMessages.filter(
      (m) => m.createdAt >= lastWeekStart && m.createdAt < thisWeekStart
    );
    for (const m of messagesLastWeek) activeIdsLastWeek.add(m.senderId);

    // --- Total connections ---
    const totalConnections = allConnections.filter(
      (c) => c.status === "connected"
    ).length;
    const totalConnectionsLastWeek =
      totalConnections - connectionsThisWeek.length;

    // --- Posts this week ---
    const postsThisWeek = postsThisWeekList.length;
    const postsLastWeek = postsLastWeekList.length;

    return {
      totalMembers: {
        value: totalMembers,
        change: wowChange(membersThisWeek, membersLastWeek),
      },
      activeUsers: {
        value: activeUsers,
        change: wowChange(activeUsers, activeIdsLastWeek.size),
      },
      totalConnections: {
        value: totalConnections,
        change: wowChange(
          connectionsThisWeek.length,
          connectionsLastWeek.length
        ),
      },
      postsThisWeek: {
        value: postsThisWeek,
        change: wowChange(postsThisWeek, postsLastWeek),
      },
    };
  },
});

// -------------------------------------------------------
// 2. growth — Weekly signup data for charting
// -------------------------------------------------------
export const growth = query({
  args: {},
  handler: async (ctx) => {
    const allUsers = await ctx.db.query("users").collect();
    const onboarded = allUsers.filter((m) => m.isOnboarded);

    if (onboarded.length === 0) return [];

    // Sort by createdAt ascending
    onboarded.sort((a, b) => a.createdAt - b.createdAt);

    // Group by week
    const weekMap = new Map<string, number>();
    for (const m of onboarded) {
      const week = weekLabel(m.createdAt);
      weekMap.set(week, (weekMap.get(week) ?? 0) + 1);
    }

    // Build ordered array with cumulative count
    const weeks = Array.from(weekMap.entries()).sort(([a], [b]) =>
      a.localeCompare(b)
    );

    let cumulative = 0;
    return weeks.map(([week, count]) => {
      cumulative += count;
      return { week, count, cumulative };
    });
  },
});

// -------------------------------------------------------
// 3. connectionStats — Connection health metrics
// -------------------------------------------------------
export const connectionStats = query({
  args: {},
  handler: async (ctx) => {
    const now = Date.now();
    const thisWeekStart = now - WEEK_MS;

    const allConnections = await ctx.db.query("connections").collect();
    const connected = allConnections.filter((c) => c.status === "connected");

    const total = connected.length;
    const newThisWeek = connected.filter(
      (c) => c.createdAt >= thisWeekStart
    ).length;

    // Members with at least 1 connection
    const allUsers = await ctx.db.query("users").collect();
    const onboarded = allUsers.filter((m) => m.isOnboarded);
    const memberCount = onboarded.length;

    const userConnectionCounts = new Map<string, number>();
    for (const c of connected) {
      userConnectionCounts.set(
        c.requesterId,
        (userConnectionCounts.get(c.requesterId) ?? 0) + 1
      );
      userConnectionCounts.set(
        c.accepterId,
        (userConnectionCounts.get(c.accepterId) ?? 0) + 1
      );
    }

    const membersWithConnections = onboarded.filter((m) =>
      userConnectionCounts.has(m._id)
    ).length;

    const avgConnectionsPerMember =
      memberCount > 0
        ? Math.round((total * 2) / memberCount * 10) / 10
        : 0;

    const percentWithConnection =
      memberCount > 0
        ? Math.round((membersWithConnections / memberCount) * 100)
        : 0;

    // Recent 5 connections with names
    const recentConnected = connected
      .sort((a, b) => b.createdAt - a.createdAt)
      .slice(0, 5);

    const recentConnections = await Promise.all(
      recentConnected.map(async (c) => {
        const requester = await ctx.db.get(c.requesterId);
        const accepter = await ctx.db.get(c.accepterId);
        return {
          id: c._id,
          requesterName: requester?.name ?? "Unknown",
          requesterAvatar: requester?.avatarUrl ?? null,
          accepterName: accepter?.name ?? "Unknown",
          accepterAvatar: accepter?.avatarUrl ?? null,
          connectedAt: c.connectedAt ?? c.createdAt,
        };
      })
    );

    return {
      total,
      newThisWeek,
      avgConnectionsPerMember,
      percentWithConnection,
      recentConnections,
    };
  },
});

// -------------------------------------------------------
// 4. skillsIntelligence — Supply/demand skill analysis
// -------------------------------------------------------
export const skillsIntelligence = query({
  args: {},
  handler: async (ctx) => {
    const allUsers = await ctx.db.query("users").collect();
    const onboarded = allUsers.filter((m) => m.isOnboarded);

    const lookingForCounts = new Map<string, number>();
    const canHelpWithCounts = new Map<string, number>();

    for (const m of onboarded) {
      if (m.lookingFor) {
        const skills = m.lookingFor.split(",").map(normalizeSkill).filter(Boolean);
        for (const s of skills) {
          lookingForCounts.set(s, (lookingForCounts.get(s) ?? 0) + 1);
        }
      }
      if (m.canHelpWith) {
        const skills = m.canHelpWith
          .split(",")
          .map(normalizeSkill)
          .filter(Boolean);
        for (const s of skills) {
          canHelpWithCounts.set(s, (canHelpWithCounts.get(s) ?? 0) + 1);
        }
      }
    }

    // Convert to sorted arrays
    const lookingFor = Array.from(lookingForCounts.entries())
      .map(([skill, count]) => ({ skill, count }))
      .sort((a, b) => b.count - a.count);

    const canHelpWith = Array.from(canHelpWithCounts.entries())
      .map(([skill, count]) => ({ skill, count }))
      .sort((a, b) => b.count - a.count);

    // Gaps: skills demanded more than supplied
    const allSkills = new Set([
      ...lookingForCounts.keys(),
      ...canHelpWithCounts.keys(),
    ]);

    const gaps = Array.from(allSkills)
      .map((skill) => {
        const demand = lookingForCounts.get(skill) ?? 0;
        const supply = canHelpWithCounts.get(skill) ?? 0;
        return { skill, demand, supply, gap: demand - supply };
      })
      .filter((g) => g.gap > 0)
      .sort((a, b) => b.gap - a.gap);

    return { lookingFor, canHelpWith, gaps };
  },
});

// -------------------------------------------------------
// 5. eventPerformance — Per-event analytics (full data)
// -------------------------------------------------------
export const eventPerformance = query({
  args: {},
  handler: async (ctx) => {
    const allEvents = await ctx.db.query("events").withIndex("by_date").collect();
    const allRsvps = await ctx.db.query("eventRsvps").collect();
    const allFeedback = await ctx.db.query("eventFeedback").collect();
    const allConnections = await ctx.db.query("connections").collect();
    const allUsers = await ctx.db.query("users").collect();
    const connected = allConnections.filter((c) => c.status === "connected");

    // Index users by ID for lookups
    const usersById = new Map<string, typeof allUsers[0]>();
    for (const m of allUsers) {
      usersById.set(m._id, m);
    }

    // Pre-index RSVPs and feedback by event
    const rsvpsByEvent = new Map<string, typeof allRsvps>();
    for (const r of allRsvps) {
      const list = rsvpsByEvent.get(r.eventId) ?? [];
      list.push(r);
      rsvpsByEvent.set(r.eventId, list);
    }

    const feedbackByEvent = new Map<string, typeof allFeedback>();
    for (const f of allFeedback) {
      const list = feedbackByEvent.get(f.eventId) ?? [];
      list.push(f);
      feedbackByEvent.set(f.eventId, list);
    }

    // Sort events most recent first
    const sortedEvents = [...allEvents].sort((a, b) => b.date - a.date);

    const results = sortedEvents.map((event) => {
      const rsvps = rsvpsByEvent.get(event._id) ?? [];
      const goingRsvps = rsvps.filter((r) => r.status === "going");
      const interestedRsvps = rsvps.filter((r) => r.status === "interested");
      const feedback = feedbackByEvent.get(event._id) ?? [];

      const averageRating =
        feedback.length > 0
          ? Math.round(
              (feedback.reduce((sum, f) => sum + f.rating, 0) /
                feedback.length) *
                10
            ) / 10
          : null;

      // Post-event connections: created within 48h of event, both RSVP'd going
      const goingUserIds = new Set(goingRsvps.map((r) => r.userId as string));
      const fortyEightHoursAfter = event.date + 48 * 60 * 60 * 1000;

      const postEventConnections = connected.filter((c) => {
        const connectionTime = c.connectedAt ?? c.createdAt;
        return (
          connectionTime >= event.date &&
          connectionTime <= fortyEightHoursAfter &&
          goingUserIds.has(c.requesterId) &&
          goingUserIds.has(c.accepterId)
        );
      }).length;

      // Build attendee lists with user details
      const attendees = goingRsvps.map((r) => {
        const user = usersById.get(r.userId);
        return {
          id: r.userId,
          name: user?.name ?? "Unknown",
          avatarUrl: user?.avatarUrl ?? null,
          headline: user?.headline ?? null,
          rsvpStatus: r.status as string,
          rsvpDate: r.createdAt,
        };
      });

      const interestedAttendees = interestedRsvps.map((r) => {
        const user = usersById.get(r.userId);
        return {
          id: r.userId,
          name: user?.name ?? "Unknown",
          avatarUrl: user?.avatarUrl ?? null,
          headline: user?.headline ?? null,
          rsvpStatus: r.status as string,
          rsvpDate: r.createdAt,
        };
      });

      // Feedback improvements breakdown
      const improvementCounts = new Map<string, number>();
      for (const f of feedback) {
        for (const imp of f.improvements) {
          improvementCounts.set(imp, (improvementCounts.get(imp) ?? 0) + 1);
        }
      }
      const topImprovements = [...improvementCounts.entries()]
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5)
        .map(([label, count]) => ({ label, count }));

      // Rating breakdown (1-5 stars)
      const ratingBreakdown = [0, 0, 0, 0, 0];
      for (const f of feedback) {
        const idx = Math.min(Math.max(Math.round(f.rating) - 1, 0), 4);
        ratingBreakdown[idx]++;
      }

      // Created by
      const creator = usersById.get(event.createdBy);

      return {
        id: event._id,
        title: event.title,
        description: event.description ?? null,
        date: event.date,
        endDate: event.endDate ?? null,
        location: event.location ?? null,
        type: event.type,
        imageUrl: event.imageUrl ?? null,
        createdBy: {
          id: event.createdBy,
          name: creator?.name ?? "Unknown",
          avatarUrl: creator?.avatarUrl ?? null,
        },
        rsvpCount: goingRsvps.length,
        interestedCount: interestedRsvps.length,
        feedbackCount: feedback.length,
        averageRating,
        postEventConnections,
        attendees,
        interestedAttendees,
        topImprovements,
        ratingBreakdown,
      };
    });

    return results;
  },
});

// -------------------------------------------------------
// 6. communityHealth — Overall engagement pulse
// -------------------------------------------------------
export const communityHealth = query({
  args: {},
  handler: async (ctx) => {
    const now = Date.now();
    const { thisWeekStart, lastWeekStart } = getWeekBoundaries(now);

    // Posts
    const allPosts = await ctx.db.query("posts").withIndex("by_created").collect();
    const postsThisWeek = allPosts.filter(
      (p) => p.createdAt >= thisWeekStart
    ).length;
    const postsLastWeek = allPosts.filter(
      (p) => p.createdAt >= lastWeekStart && p.createdAt < thisWeekStart
    ).length;

    // Comments
    const allComments = await ctx.db.query("comments").collect();
    const averageCommentsPerPost =
      allPosts.length > 0
        ? Math.round((allComments.length / allPosts.length) * 10) / 10
        : 0;

    // Messages this week
    const allMessages = await ctx.db.query("messages").collect();
    const messagesThisWeek = allMessages.filter(
      (m) => m.createdAt >= thisWeekStart
    ).length;

    // Pending reports
    const allReports = await ctx.db
      .query("reports")
      .withIndex("by_status", (q) => q.eq("status", "pending"))
      .collect();
    const pendingReports = allReports.length;

    // Users
    const allUsers = await ctx.db.query("users").collect();
    const totalUsers = allUsers.length;
    const onboardedCount = allUsers.filter((m) => m.isOnboarded).length;

    return {
      postsPerWeek: {
        thisWeek: postsThisWeek,
        lastWeek: postsLastWeek,
        change: wowChange(postsThisWeek, postsLastWeek),
      },
      averageCommentsPerPost,
      messagesThisWeek,
      pendingReports,
      totalUsers,
      onboardedCount,
    };
  },
});

// -------------------------------------------------------
// 7. recentActivity — Last 10 notable activities
// -------------------------------------------------------
export const recentActivity = query({
  args: {},
  handler: async (ctx) => {
    type Activity = {
      timestamp: number;
      type: "new_member" | "new_connection" | "new_post" | "new_rsvp";
      description: string;
    };

    const activities: Activity[] = [];

    // Recent members (onboarded)
    const recentUsers = await ctx.db
      .query("users")
      .order("desc")
      .take(20);
    for (const m of recentUsers) {
      if (m.isOnboarded) {
        activities.push({
          timestamp: m.createdAt,
          type: "new_member",
          description: `${m.name} joined the community`,
        });
      }
    }

    // Recent connections
    const recentConnections = await ctx.db
      .query("connections")
      .withIndex("by_status", (q) => q.eq("status", "connected"))
      .order("desc")
      .take(10);
    for (const c of recentConnections) {
      const requester = await ctx.db.get(c.requesterId);
      const accepter = await ctx.db.get(c.accepterId);
      if (requester && accepter) {
        activities.push({
          timestamp: c.connectedAt ?? c.createdAt,
          type: "new_connection",
          description: `${requester.name} connected with ${accepter.name}`,
        });
      }
    }

    // Recent posts
    const recentPosts = await ctx.db
      .query("posts")
      .withIndex("by_created")
      .order("desc")
      .take(10);
    for (const p of recentPosts) {
      const author = await ctx.db.get(p.authorId);
      if (author) {
        const preview =
          p.content.length > 60
            ? p.content.slice(0, 60) + "..."
            : p.content;
        activities.push({
          timestamp: p.createdAt,
          type: "new_post",
          description: `${author.name} posted: "${preview}"`,
        });
      }
    }

    // Recent RSVPs (going only)
    const recentRsvps = await ctx.db
      .query("eventRsvps")
      .order("desc")
      .take(20);
    for (const r of recentRsvps) {
      if (r.status !== "going") continue;
      const user = await ctx.db.get(r.userId);
      const event = await ctx.db.get(r.eventId);
      if (user && event) {
        activities.push({
          timestamp: r.createdAt,
          type: "new_rsvp",
          description: `${user.name} RSVP'd to ${event.title}`,
        });
      }
    }

    // Sort all activities by timestamp desc and take top 10
    activities.sort((a, b) => b.timestamp - a.timestamp);
    return activities.slice(0, 10);
  },
});

// -------------------------------------------------------
// 8. networkGraph — All users + connections for graph viz
// -------------------------------------------------------
export const networkGraph = query({
  args: {},
  handler: async (ctx) => {
    const allUsers = await ctx.db.query("users").collect();
    const onboarded = allUsers.filter((m) => m.isOnboarded);

    const nodes = onboarded.map((m) => ({
      id: m._id,
      name: m.name,
      avatarUrl: m.avatarUrl ?? null,
      headline: m.headline ?? null,
      skills: m.skills ?? [],
      interests: m.interests ?? [],
      lookingFor: m.lookingFor ?? null,
      canHelpWith: m.canHelpWith ?? null,
      createdAt: m.createdAt,
    }));

    const allConnections = await ctx.db.query("connections").collect();
    const connected = allConnections.filter((c) => c.status === "connected");

    const edges = connected.map((c) => ({
      id: c._id,
      source: c.requesterId,
      target: c.accepterId,
      connectedAt: c.connectedAt ?? c.createdAt,
    }));

    return { nodes, edges };
  },
});

// -------------------------------------------------------
// 9. userProfile — Individual user detail
// -------------------------------------------------------
export const userProfile = query({
  args: {},
  handler: async (ctx) => {
    const allUsers = await ctx.db.query("users").collect();
    const onboarded = allUsers.filter((m) => m.isOnboarded);

    const allConnections = await ctx.db.query("connections").collect();
    const connected = allConnections.filter((c) => c.status === "connected");

    const allPosts = await ctx.db.query("posts").withIndex("by_created").collect();
    const allComments = await ctx.db.query("comments").collect();

    const profiles = await Promise.all(
      onboarded.map(async (m) => {
        // Count connections
        const userConnections = connected.filter(
          (c) => c.requesterId === m._id || c.accepterId === m._id
        );

        // Get connected user names
        const connectedUsers = await Promise.all(
          userConnections.map(async (c) => {
            const otherId =
              c.requesterId === m._id ? c.accepterId : c.requesterId;
            const other = await ctx.db.get(otherId);
            return other
              ? { id: other._id, name: other.name }
              : null;
          })
        );

        // Count posts
        const userPosts = allPosts.filter((p) => p.authorId === m._id);

        // Count comments made
        const userComments = allComments.filter((c) => c.authorId === m._id);

        return {
          id: m._id,
          name: m.name,
          avatarUrl: m.avatarUrl ?? null,
          headline: m.headline ?? null,
          skills: m.skills ?? [],
          interests: m.interests ?? [],
          lookingFor: m.lookingFor ?? null,
          canHelpWith: m.canHelpWith ?? null,
          createdAt: m.createdAt,
          connectionCount: userConnections.length,
          connections: connectedUsers.filter(Boolean),
          postCount: userPosts.length,
          commentCount: userComments.length,
          recentPosts: userPosts
            .sort((a, b) => b.createdAt - a.createdAt)
            .slice(0, 5)
            .map((p) => ({
              id: p._id,
              content:
                p.content.length > 120
                  ? p.content.slice(0, 120) + "..."
                  : p.content,
              createdAt: p.createdAt,
            })),
        };
      })
    );

    return profiles;
  },
});

// -------------------------------------------------------
// 10. aiIntelligence — AI matching & search analytics
// -------------------------------------------------------
export const aiIntelligence = query({
  args: {},
  handler: async (ctx) => {
    const now = Date.now();
    const thisWeekStart = now - WEEK_MS;

    // --- Daily matches ---
    const allMatches = await ctx.db.query("dailyMatches").collect();
    const totalMatchDays = allMatches.length; // total user-days of matches
    const uniqueDates = new Set(allMatches.map((m) => m.date));
    const daysWithMatches = uniqueDates.size;

    // Today's matches
    const today = new Date().toISOString().slice(0, 10);
    const todayMatches = allMatches.filter((m) => m.date === today);
    const todayMatchCount = todayMatches.reduce(
      (sum, m) => sum + m.matches.length,
      0
    );
    const todayUsersMatched = todayMatches.length;

    // Total unique match pairs ever (deduplicated)
    const matchPairSet = new Set<string>();
    for (const dm of allMatches) {
      for (const match of dm.matches) {
        const pair = [dm.userId, match.matchId].sort().join("-");
        matchPairSet.add(pair);
      }
    }
    const totalUniqueMatchPairs = matchPairSet.size;

    // Recent match examples (last 5 from today or most recent date)
    const sortedMatches = [...allMatches].sort(
      (a, b) => b.generatedAt - a.generatedAt
    );
    const recentMatchDocs = sortedMatches.slice(0, 8);

    const recentMatches = await Promise.all(
      recentMatchDocs.flatMap((dm) =>
        dm.matches.slice(0, 1).map(async (match) => {
          const user = await ctx.db.get(dm.userId);
          const matchedUser = await ctx.db.get(match.matchId);
          return user && matchedUser
            ? {
                userName: user.name,
                userAvatar: user.avatarUrl ?? null,
                matchName: matchedUser.name,
                matchAvatar: matchedUser.avatarUrl ?? null,
                reason: match.matchReason,
                date: dm.date,
              }
            : null;
        })
      )
    );

    // --- AI search sessions ---
    const allSessions = await ctx.db.query("searchSessions").collect();
    const totalSearches = allSessions.length;
    const searchesThisWeek = allSessions.filter(
      (s) => s.createdAt >= thisWeekStart
    ).length;

    // Recent search queries
    const recentSearches = [...allSessions]
      .sort((a, b) => b.createdAt - a.createdAt)
      .slice(0, 5);

    const searchExamples = await Promise.all(
      recentSearches.map(async (s) => {
        const user = await ctx.db.get(s.userId);
        return {
          query: s.query,
          userName: user?.name ?? "Unknown",
          resultCount: s.resultCount ?? 0,
          createdAt: s.createdAt,
        };
      })
    );

    // --- Embedding coverage ---
    const allUsers = await ctx.db.query("users").collect();
    const onboarded = allUsers.filter((m) => m.isOnboarded);
    const withEmbedding = onboarded.filter(
      (m) => m.profileEmbedding && m.profileEmbedding.length > 0
    );
    const embeddingCoverage =
      onboarded.length > 0
        ? Math.round((withEmbedding.length / onboarded.length) * 100)
        : 0;

    // --- Match-to-connection conversion ---
    // How many AI match pairs actually connected?
    const allConnections = await ctx.db.query("connections").collect();
    const connected = allConnections.filter((c) => c.status === "connected");
    const connectedPairs = new Set<string>();
    for (const c of connected) {
      connectedPairs.add(
        [c.requesterId, c.accepterId].sort().join("-")
      );
    }
    let matchesConverted = 0;
    for (const pair of matchPairSet) {
      if (connectedPairs.has(pair)) matchesConverted++;
    }
    const conversionRate =
      totalUniqueMatchPairs > 0
        ? Math.round((matchesConverted / totalUniqueMatchPairs) * 100)
        : 0;

    return {
      matching: {
        totalMatchDays,
        daysWithMatches,
        todayMatchCount,
        todayUsersMatched,
        totalUniqueMatchPairs,
        conversionRate,
        matchesConverted,
        recentMatches: recentMatches.filter(Boolean),
      },
      search: {
        totalSearches,
        searchesThisWeek,
        searchExamples,
      },
      embeddings: {
        total: onboarded.length,
        withEmbedding: withEmbedding.length,
        coverage: embeddingCoverage,
      },
    };
  },
});

// -------------------------------------------------------
// Helper: classify a user into skill clusters (proxy for "department")
// -------------------------------------------------------
const TECH_KEYWORDS = ["coding", "programming", "development", "developer", "engineering", "engineer", "software", "ai", "ml", "machine learning", "data", "ios", "android", "python", "javascript", "react", "swift", "flutter", "web", "mobile", "blockchain", "cybersecurity", "devops", "backend", "frontend", "full stack", "api", "database", "cloud", "aws", "tech", "computer", "code", "app"];
const BIZ_KEYWORDS = ["marketing", "sales", "finance", "fundraising", "pitch", "strategy", "consulting", "management", "accounting", "operations", "growth", "business", "entrepreneurship", "startup", "venture", "economics", "product management", "analytics"];
const DESIGN_KEYWORDS = ["design", "ui", "ux", "figma", "graphic", "branding", "product design", "illustration", "typography", "visual", "creative direction", "wireframe", "prototyping"];
const CREATIVE_KEYWORDS = ["content", "video", "photography", "music", "writing", "social media", "editing", "film", "art", "creative", "media", "storytelling", "journalism", "podcast"];

function classifyUser(skills: string[], interests: string[]): Set<string> {
  const all = [...skills, ...interests].map(s => s.toLowerCase());
  const clusters = new Set<string>();

  for (const skill of all) {
    if (TECH_KEYWORDS.some(k => skill.includes(k))) clusters.add("Technology");
    if (BIZ_KEYWORDS.some(k => skill.includes(k))) clusters.add("Business");
    if (DESIGN_KEYWORDS.some(k => skill.includes(k))) clusters.add("Design");
    if (CREATIVE_KEYWORDS.some(k => skill.includes(k))) clusters.add("Creative");
  }

  if (clusters.size === 0) clusters.add("Other");
  return clusters;
}

// -------------------------------------------------------
// 11. intelligenceHub — Cross-layer intelligence metrics
// -------------------------------------------------------
export const intelligenceHub = query({
  args: {},
  handler: async (ctx) => {
    // Pull all needed data upfront
    const allUsers = await ctx.db.query("users").collect();
    const onboarded = allUsers.filter(m => m.isOnboarded);
    const allPosts = await ctx.db.query("posts").withIndex("by_created").collect();
    const allComments = await ctx.db.query("comments").collect();
    const allConnections = await ctx.db.query("connections").collect();
    const connected = allConnections.filter(c => c.status === "connected");
    const allEvents = await ctx.db.query("events").withIndex("by_date").collect();
    const allRsvps = await ctx.db.query("eventRsvps").collect();
    const allFeedback = await ctx.db.query("eventFeedback").collect();
    const allSearchSessions = await ctx.db.query("searchSessions").collect();
    const allConversations = await ctx.db.query("conversations").collect();
    const allPortfolio = await ctx.db.query("portfolioItems").collect();

    // ---- INNOVATION FUNNEL ----
    const totalSignups = allUsers.length;
    const onboardedCount = onboarded.length;

    const authorsWithPosts = new Set(allPosts.map(p => p.authorId));
    const hasPosted = onboarded.filter(m => authorsWithPosts.has(m._id)).length;

    const userConnectionCounts = new Map<string, number>();
    for (const c of connected) {
      userConnectionCounts.set(c.requesterId, (userConnectionCounts.get(c.requesterId) ?? 0) + 1);
      userConnectionCounts.set(c.accepterId, (userConnectionCounts.get(c.accepterId) ?? 0) + 1);
    }
    const hasConnected = onboarded.filter(m => userConnectionCounts.has(m._id)).length;
    const deeplyEngaged = onboarded.filter(m => (userConnectionCounts.get(m._id) ?? 0) >= 3).length;

    // ---- SEARCH DEMAND ----
    const totalSearches = allSearchSessions.length;
    const unmatchedSessions = allSearchSessions.filter(s => (s.resultCount ?? 0) === 0);
    const unmatchedCount = unmatchedSessions.length;

    const unmatchedQueryCounts = new Map<string, number>();
    for (const s of unmatchedSessions) {
      const q = s.query.trim().toLowerCase();
      unmatchedQueryCounts.set(q, (unmatchedQueryCounts.get(q) ?? 0) + 1);
    }
    const unmatchedQueries = Array.from(unmatchedQueryCounts.entries())
      .map(([query, count]) => ({ query, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 10);

    const searchQueryCounts = new Map<string, { count: number; totalResults: number }>();
    for (const s of allSearchSessions) {
      const q = s.query.trim().toLowerCase();
      const existing = searchQueryCounts.get(q) ?? { count: 0, totalResults: 0 };
      existing.count++;
      existing.totalResults += (s.resultCount ?? 0);
      searchQueryCounts.set(q, existing);
    }
    const topSearches = Array.from(searchQueryCounts.entries())
      .map(([query, data]) => ({
        query,
        count: data.count,
        avgResults: Math.round((data.totalResults / data.count) * 10) / 10,
      }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 8);

    // ---- EVENT IMPACT ----
    const rsvpsByEvent = new Map<string, typeof allRsvps>();
    for (const r of allRsvps) {
      const list = rsvpsByEvent.get(r.eventId) ?? [];
      list.push(r);
      rsvpsByEvent.set(r.eventId, list);
    }

    const connectedPairSet = new Set<string>();
    for (const c of connected) {
      connectedPairSet.add([c.requesterId, c.accepterId].sort().join("-"));
    }

    let totalPostEventConnections = 0;
    let totalPostEventDMs = 0;
    let totalAttendees = 0;
    let bestEvent: { title: string; connectionRate: number; connections: number } | null = null;

    for (const event of allEvents) {
      const rsvps = rsvpsByEvent.get(event._id) ?? [];
      const going = rsvps.filter(r => r.status === "going");
      const goingIds = new Set(going.map(r => r.userId as string));
      totalAttendees += going.length;

      const eventEnd = event.endDate ?? event.date + 3 * 60 * 60 * 1000;
      const window48h = eventEnd + 48 * 60 * 60 * 1000;

      const eventConnections = connected.filter(c => {
        const t = c.connectedAt ?? c.createdAt;
        return t >= event.date && t <= window48h && goingIds.has(c.requesterId) && goingIds.has(c.accepterId);
      });
      totalPostEventConnections += eventConnections.length;

      const eventDMs = allConversations.filter(c =>
        c.createdAt >= event.date && c.createdAt <= window48h &&
        goingIds.has(c.participant1Id) && goingIds.has(c.participant2Id)
      );
      totalPostEventDMs += eventDMs.length;

      const connectionRate = going.length > 0 ? eventConnections.length / going.length : 0;
      if (going.length > 0 && (!bestEvent || connectionRate > bestEvent.connectionRate)) {
        bestEvent = { title: event.title, connectionRate: Math.round(connectionRate * 100), connections: eventConnections.length };
      }
    }

    let totalWants = 0;
    let fulfilledWants = 0;
    for (const fb of allFeedback) {
      for (const wantId of fb.wantToConnectWith) {
        totalWants++;
        const pair = [fb.userId, wantId].sort().join("-");
        if (connectedPairSet.has(pair)) fulfilledWants++;
      }
    }

    // ---- NETWORK DIVERSITY ----
    const userClusters = new Map<string, Set<string>>();
    for (const m of onboarded) {
      userClusters.set(m._id, classifyUser(m.skills ?? [], m.interests ?? []));
    }

    let crossClusterCount = 0;
    const clusterPairCounts = new Map<string, number>();
    for (const conn of connected) {
      const clusters1 = userClusters.get(conn.requesterId);
      const clusters2 = userClusters.get(conn.accepterId);
      if (!clusters1 || !clusters2) continue;

      let shared = false;
      for (const cl of clusters1) {
        if (clusters2.has(cl)) { shared = true; break; }
      }
      if (!shared) {
        crossClusterCount++;
        for (const c1 of clusters1) {
          for (const c2 of clusters2) {
            const pair = [c1, c2].sort().join(" \u2194 ");
            clusterPairCounts.set(pair, (clusterPairCounts.get(pair) ?? 0) + 1);
          }
        }
      }
    }

    const crossClusterPairs = Array.from(clusterPairCounts.entries())
      .map(([pair, count]) => ({ pair, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 5);

    const userConnectedClusters = new Map<string, Set<string>>();
    for (const conn of connected) {
      const c2 = userClusters.get(conn.accepterId);
      const c1 = userClusters.get(conn.requesterId);
      if (c2) {
        const set = userConnectedClusters.get(conn.requesterId) ?? new Set();
        for (const cl of c2) set.add(cl);
        userConnectedClusters.set(conn.requesterId, set);
      }
      if (c1) {
        const set = userConnectedClusters.get(conn.accepterId) ?? new Set();
        for (const cl of c1) set.add(cl);
        userConnectedClusters.set(conn.accepterId, set);
      }
    }

    const bridgeNodes = onboarded
      .filter(m => (userConnectedClusters.get(m._id)?.size ?? 0) >= 2)
      .map(m => ({
        name: m.name,
        avatar: m.avatarUrl ?? null,
        clustersConnected: Array.from(userConnectedClusters.get(m._id) ?? []),
        connectionCount: userConnectionCounts.get(m._id) ?? 0,
      }))
      .sort((a, b) => b.clustersConnected.length - a.clustersConnected.length || b.connectionCount - a.connectionCount)
      .slice(0, 5);

    // ---- PROJECT INTELLIGENCE ----
    const activeProjectCount = onboarded.filter(m => m.currentProject && m.currentProject.trim().length > 0).length;
    const portfolioByType = new Map<string, number>();
    for (const p of allPortfolio) {
      portfolioByType.set(p.type, (portfolioByType.get(p.type) ?? 0) + 1);
    }

    // ---- CONTENT HEALTH ----
    const postsByCategory = { asking: 0, sharing: 0, looking_for: 0 };
    for (const p of allPosts) {
      if (p.category === "asking") postsByCategory.asking++;
      else if (p.category === "sharing") postsByCategory.sharing++;
      else if (p.category === "looking_for") postsByCategory.looking_for++;
    }

    return {
      funnel: {
        totalSignups,
        onboarded: onboardedCount,
        hasPosted,
        hasConnected,
        deeplyEngaged,
      },
      searchDemand: {
        totalSearches,
        unmatchedCount,
        unmatchedRate: totalSearches > 0 ? Math.round((unmatchedCount / totalSearches) * 100) : 0,
        unmatchedQueries,
        topSearches,
      },
      eventImpact: {
        totalEvents: allEvents.length,
        totalAttendees,
        totalPostEventConnections,
        totalPostEventDMs,
        bestEvent,
        wantToConnectFulfillment: totalWants > 0 ? Math.round((fulfilledWants / totalWants) * 100) : 0,
        totalWants,
        fulfilledWants,
      },
      network: {
        totalConnections: connected.length,
        crossClusterCount,
        crossClusterRate: connected.length > 0 ? Math.round((crossClusterCount / connected.length) * 100) : 0,
        crossClusterPairs,
        bridgeNodes,
      },
      projects: {
        activeProjectCount,
        portfolioItemCount: allPortfolio.length,
        portfolioByType: Array.from(portfolioByType.entries())
          .map(([type, count]) => ({ type, count }))
          .sort((a, b) => b.count - a.count),
      },
      content: {
        total: allPosts.length,
        asking: postsByCategory.asking,
        sharing: postsByCategory.sharing,
        lookingFor: postsByCategory.looking_for,
        totalComments: allComments.length,
        avgCommentsPerPost: allPosts.length > 0 ? Math.round((allComments.length / allPosts.length) * 10) / 10 : 0,
      },
    };
  },
});

// -------------------------------------------------------
// Helper: classify free-text into skill categories
// -------------------------------------------------------
function classifyText(text: string): Set<string> {
  const lower = text.toLowerCase();
  const clusters = new Set<string>();
  if (TECH_KEYWORDS.some(k => lower.includes(k))) clusters.add("Technology");
  if (BIZ_KEYWORDS.some(k => lower.includes(k))) clusters.add("Business");
  if (DESIGN_KEYWORDS.some(k => lower.includes(k))) clusters.add("Design");
  if (CREATIVE_KEYWORDS.some(k => lower.includes(k))) clusters.add("Creative");
  return clusters;
}

// -------------------------------------------------------
// 12. skillsEcosystem — AI-categorized skills intelligence
// -------------------------------------------------------
export const skillsEcosystem = query({
  args: {},
  handler: async (ctx) => {
    const allUsers = await ctx.db.query("users").collect();
    const onboarded = allUsers.filter(m => m.isOnboarded);
    const allConnections = await ctx.db.query("connections").collect();
    const connected = allConnections.filter(c => c.status === "connected");

    // Connection counts per user
    const connCounts = new Map<string, number>();
    for (const c of connected) {
      connCounts.set(c.requesterId, (connCounts.get(c.requesterId) ?? 0) + 1);
      connCounts.set(c.accepterId, (connCounts.get(c.accepterId) ?? 0) + 1);
    }

    // Connected pair set for match checking
    const connectedPairs = new Set<string>();
    for (const c of connected) {
      connectedPairs.add([c.requesterId, c.accepterId].sort().join("-"));
    }

    // ---- CLASSIFY SUPPLY & DEMAND PER USER ----
    const CATEGORIES = ["Technology", "Business", "Design", "Creative"] as const;

    // Supply = what they can help with (canHelpWith text + skills array)
    // Demand = what they need (lookingFor text)
    const userSupply = new Map<string, Set<string>>();
    const userDemand = new Map<string, Set<string>>();
    const userAllCategories = new Map<string, Set<string>>();

    const categorySupply: Record<string, number> = {};
    const categoryDemand: Record<string, number> = {};
    const categoryUsers: Record<string, string[]> = {};
    for (const cat of CATEGORIES) {
      categorySupply[cat] = 0;
      categoryDemand[cat] = 0;
      categoryUsers[cat] = [];
    }

    for (const m of onboarded) {
      // Supply: canHelpWith text + skills + interests
      const supplyCats = new Set<string>();
      if (m.canHelpWith) {
        for (const cat of classifyText(m.canHelpWith)) supplyCats.add(cat);
      }
      if (m.skills) {
        for (const s of m.skills) {
          for (const cat of classifyText(s)) supplyCats.add(cat);
        }
      }
      userSupply.set(m._id, supplyCats);

      // Demand: lookingFor text
      const demandCats = new Set<string>();
      if (m.lookingFor) {
        for (const cat of classifyText(m.lookingFor)) demandCats.add(cat);
      }
      userDemand.set(m._id, demandCats);

      // All categories this user touches
      const allCats = new Set([...supplyCats, ...demandCats]);
      if (m.interests) {
        for (const s of m.interests) {
          for (const cat of classifyText(s)) allCats.add(cat);
        }
      }
      userAllCategories.set(m._id, allCats);

      for (const cat of supplyCats) {
        categorySupply[cat] = (categorySupply[cat] ?? 0) + 1;
      }
      for (const cat of demandCats) {
        categoryDemand[cat] = (categoryDemand[cat] ?? 0) + 1;
      }
      for (const cat of allCats) {
        if (!categoryUsers[cat]) categoryUsers[cat] = [];
        categoryUsers[cat].push(m._id);
      }
    }

    // ---- CATEGORY OVERVIEW ----
    const categories = CATEGORIES.map(cat => {
      const users = categoryUsers[cat] ?? [];
      const supply = categorySupply[cat] ?? 0;
      const demand = categoryDemand[cat] ?? 0;
      const gap = demand - supply;

      // Avg connections for users in this category
      let totalConns = 0;
      for (const id of users) totalConns += (connCounts.get(id) ?? 0);
      const avgConnections = users.length > 0
        ? Math.round((totalConns / users.length) * 10) / 10
        : 0;

      return { category: cat, users: users.length, supply, demand, gap, avgConnections };
    }).sort((a, b) => b.users - a.users);

    // ---- SKILL GAPS (categories where demand > supply) ----
    const gaps = categories
      .filter(c => c.gap > 0)
      .sort((a, b) => b.gap - a.gap);

    // ---- POTENTIAL MATCHES (complementary, not connected) ----
    let potentialMatches = 0;
    const matchExamples: { needsName: string; needsAvatar: string | null; offersName: string; offersAvatar: string | null; category: string }[] = [];

    for (let i = 0; i < onboarded.length; i++) {
      const a = onboarded[i];
      const aDemand = userDemand.get(a._id);
      if (!aDemand || aDemand.size === 0) continue;

      for (let j = i + 1; j < onboarded.length; j++) {
        const b = onboarded[j];
        const pair = [a._id, b._id].sort().join("-");
        if (connectedPairs.has(pair)) continue; // already connected

        const bSupply = userSupply.get(b._id);
        const bDemand = userDemand.get(b._id);
        const aSupply = userSupply.get(a._id);

        // A needs X, B offers X
        if (bSupply) {
          for (const cat of aDemand) {
            if (bSupply.has(cat)) {
              potentialMatches++;
              if (matchExamples.length < 3) {
                matchExamples.push({
                  needsName: a.name,
                  needsAvatar: a.avatarUrl ?? null,
                  offersName: b.name,
                  offersAvatar: b.avatarUrl ?? null,
                  category: cat,
                });
              }
              break; // count pair once
            }
          }
        }

        // B needs X, A offers X (if not already counted)
        if (bDemand && aSupply) {
          let alreadyCounted = false;
          if (bSupply) {
            for (const cat of aDemand) {
              if (bSupply.has(cat)) { alreadyCounted = true; break; }
            }
          }
          if (!alreadyCounted) {
            for (const cat of bDemand) {
              if (aSupply.has(cat)) {
                potentialMatches++;
                if (matchExamples.length < 3) {
                  matchExamples.push({
                    needsName: b.name,
                    needsAvatar: b.avatarUrl ?? null,
                    offersName: a.name,
                    offersAvatar: a.avatarUrl ?? null,
                    category: cat,
                  });
                }
                break;
              }
            }
          }
        }
      }
    }

    // ---- SKILLS THAT DRIVE CONNECTIONS ----
    // Which categories correlate with more connections?
    const connectionDrivers = categories
      .filter(c => c.users > 0)
      .sort((a, b) => b.avgConnections - a.avgConnections);

    // ---- TOP RAW SKILLS (cleaned — only from skills array, not free text) ----
    const rawSkillCounts = new Map<string, number>();
    for (const m of onboarded) {
      if (m.skills) {
        for (const s of m.skills) {
          const clean = s.trim();
          if (clean.length > 0 && clean.length < 40) {
            const key = clean.toLowerCase();
            rawSkillCounts.set(key, (rawSkillCounts.get(key) ?? 0) + 1);
          }
        }
      }
    }
    const topRawSkills = Array.from(rawSkillCounts.entries())
      .map(([skill, count]) => ({ skill, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 12);

    // ---- DIVERSITY SCORE ----
    // How many categories does the average user span?
    let totalCats = 0;
    for (const m of onboarded) {
      totalCats += (userAllCategories.get(m._id)?.size ?? 0);
    }
    const avgDiversity = onboarded.length > 0
      ? Math.round((totalCats / onboarded.length) * 10) / 10
      : 0;

    return {
      categories,
      gaps,
      potentialMatches,
      matchExamples,
      connectionDrivers,
      topRawSkills,
      avgDiversity,
      totalUsers: onboarded.length,
    };
  },
});

// -------------------------------------------------------
// 13. createEvent — Create a new event from the dashboard
// -------------------------------------------------------
export const createEvent = mutation({
  args: {
    title: v.string(),
    description: v.optional(v.string()),
    date: v.number(),
    endDate: v.optional(v.number()),
    location: v.optional(v.string()),
    type: v.string(),
    imageUrl: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    // Use first user as the creator (dashboard admin proxy)
    const admin = await ctx.db.query("users").first();
    if (!admin) throw new Error("No users exist yet");

    return await ctx.db.insert("events", {
      title: args.title,
      description: args.description,
      date: args.date,
      endDate: args.endDate,
      location: args.location,
      type: args.type,
      imageUrl: args.imageUrl,
      createdBy: admin._id,
      createdAt: Date.now(),
    });
  },
});

// -------------------------------------------------------
// 14. updateEvent — Update an existing event
// -------------------------------------------------------
export const updateEvent = mutation({
  args: {
    id: v.id("events"),
    title: v.optional(v.string()),
    description: v.optional(v.string()),
    date: v.optional(v.number()),
    endDate: v.optional(v.number()),
    location: v.optional(v.string()),
    type: v.optional(v.string()),
    imageUrl: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const { id, ...fields } = args;
    const existing = await ctx.db.get(id);
    if (!existing) throw new Error("Event not found");

    // Only update provided fields
    const updates: Record<string, unknown> = {};
    if (fields.title !== undefined) updates.title = fields.title;
    if (fields.description !== undefined) updates.description = fields.description;
    if (fields.date !== undefined) updates.date = fields.date;
    if (fields.endDate !== undefined) updates.endDate = fields.endDate;
    if (fields.location !== undefined) updates.location = fields.location;
    if (fields.type !== undefined) updates.type = fields.type;
    if (fields.imageUrl !== undefined) updates.imageUrl = fields.imageUrl;

    await ctx.db.patch(id, updates);
    return id;
  },
});
