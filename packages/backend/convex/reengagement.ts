import { v } from "convex/values";
import { internalQuery, internalAction, internalMutation } from "./_generated/server";
import { internal } from "./_generated/api";

// ============================================================
// 1. EVENT REMINDERS — runs every 15 min
//    Notifies users who RSVP'd "going" when event starts in ~1 hour
// ============================================================

export const getUpcomingEventsForReminder = internalQuery({
  handler: async (ctx) => {
    const now = Date.now();
    const thirtyMin = 30 * 60 * 1000;
    const seventyFiveMin = 75 * 60 * 1000;

    // Events starting in 30-75 min window
    const events = await ctx.db
      .query("events")
      .withIndex("by_date")
      .collect();

    const upcoming = events.filter(
      (e) => e.date > now + thirtyMin && e.date < now + seventyFiveMin
    );

    // For each event, get "going" RSVPs
    const results = [];
    for (const event of upcoming) {
      const rsvps = await ctx.db
        .query("eventRsvps")
        .withIndex("by_event", (q) => q.eq("eventId", event._id))
        .filter((q) => q.eq(q.field("status"), "going"))
        .collect();

      for (const rsvp of rsvps) {
        results.push({
          userId: rsvp.userId,
          eventId: event._id,
          eventTitle: event.title,
          hostId: event.createdBy,
        });
      }
    }

    return results;
  },
});

export const sendEventReminders = internalAction({
  handler: async (ctx) => {
    const eligible = await ctx.runQuery(
      internal.reengagement.getUpcomingEventsForReminder
    );

    let sent = 0;
    for (const item of eligible) {
      // Dedup: don't send if already reminded for this event
      const alreadySent = await ctx.runQuery(
        internal.notifications.hasRecentNotification,
        {
          recipientId: item.userId,
          type: "event_reminder",
          sinceTimestamp: Date.now() - 24 * 60 * 60 * 1000,
        }
      );

      if (alreadySent) continue;

      await ctx.runAction(internal.notifications.notifySystem, {
        recipientId: item.userId,
        type: "event_reminder",
        title: `${item.eventTitle} starts in about 1 hour`,
        body: "Don't forget to show up!",
        data: { eventId: item.eventId },
      });
      sent++;
    }

    if (sent > 0) console.log(`Sent ${sent} event reminders`);
  },
});

// ============================================================
// 2. PENDING CONNECTION NUDGE — runs every 6 hours
//    Nudges users who have unanswered connection requests > 24h
// ============================================================

export const getPendingConnectionsForNudge = internalQuery({
  handler: async (ctx) => {
    const twentyFourHoursAgo = Date.now() - 24 * 60 * 60 * 1000;

    const pendingConnections = await ctx.db
      .query("connections")
      .withIndex("by_status", (q) => q.eq("status", "pending"))
      .filter((q) => q.lt(q.field("createdAt"), twentyFourHoursAgo))
      .collect();

    const results = [];
    for (const conn of pendingConnections) {
      const requester = await ctx.db.get(conn.requesterId);
      if (!requester) continue;

      results.push({
        connectionId: conn._id,
        accepterId: conn.accepterId,
        requesterId: conn.requesterId,
        requesterName: requester.name,
      });
    }

    return results;
  },
});

export const sendPendingConnectionNudges = internalAction({
  handler: async (ctx) => {
    const eligible = await ctx.runQuery(
      internal.reengagement.getPendingConnectionsForNudge
    );

    let sent = 0;
    for (const item of eligible) {
      // Dedup: only nudge once per 48h
      const alreadySent = await ctx.runQuery(
        internal.notifications.hasRecentNotification,
        {
          recipientId: item.accepterId,
          type: "pending_connection_reminder",
          sinceTimestamp: Date.now() - 48 * 60 * 60 * 1000,
        }
      );

      if (alreadySent) continue;

      await ctx.runAction(internal.notifications.notifyUser, {
        recipientId: item.accepterId,
        senderId: item.requesterId,
        type: "pending_connection_reminder",
        title: `${item.requesterName} is waiting to connect with you`,
        data: { connectionId: item.connectionId },
      });
      sent++;
    }

    if (sent > 0) console.log(`Sent ${sent} pending connection nudges`);
  },
});

// ============================================================
// 3. WEEKLY DIGEST — Saturday 10am CT (16:00 UTC)
//    Community stats for the past week
// ============================================================

export const getWeeklyDigestData = internalQuery({
  handler: async (ctx) => {
    const oneWeekAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;

    // Count new users this week
    const allUsers = await ctx.db.query("users").collect();
    const newUsersCount = allUsers.filter(
      (m) => m.createdAt > oneWeekAgo && m.isOnboarded
    ).length;

    // Count new posts this week
    const allPosts = await ctx.db
      .query("posts")
      .withIndex("by_created")
      .collect();
    const newPostsCount = allPosts.filter(
      (p) => p.createdAt > oneWeekAgo
    ).length;

    // Count upcoming events
    const now = Date.now();
    const allEvents = await ctx.db
      .query("events")
      .withIndex("by_date")
      .collect();
    const upcomingEventsCount = allEvents.filter((e) => e.date > now).length;

    // Get all onboarded users to send digest to
    const recipients = allUsers
      .filter((m) => m.isOnboarded)
      .map((m) => m._id);

    return {
      newUsersCount,
      newPostsCount,
      upcomingEventsCount,
      recipients,
    };
  },
});

export const sendWeeklyDigest = internalAction({
  handler: async (ctx) => {
    const data = await ctx.runQuery(
      internal.reengagement.getWeeklyDigestData
    );

    // Only send if there's something to report
    if (
      data.newUsersCount === 0 &&
      data.newPostsCount === 0 &&
      data.upcomingEventsCount === 0
    ) {
      console.log("Weekly digest: nothing to report, skipping");
      return;
    }

    // Build summary body
    const parts = [];
    if (data.newUsersCount > 0) {
      parts.push(
        `${data.newUsersCount} new user${data.newUsersCount === 1 ? "" : "s"} joined`
      );
    }
    if (data.newPostsCount > 0) {
      parts.push(
        `${data.newPostsCount} new post${data.newPostsCount === 1 ? "" : "s"} shared`
      );
    }
    if (data.upcomingEventsCount > 0) {
      parts.push(
        `${data.upcomingEventsCount} upcoming event${data.upcomingEventsCount === 1 ? "" : "s"}`
      );
    }
    const body = parts.join(" / ");

    let sent = 0;
    for (const recipientId of data.recipients) {
      await ctx.runAction(internal.notifications.notifySystem, {
        recipientId,
        type: "weekly_digest",
        title: "Your weekly Junto roundup",
        body,
      });
      sent++;
    }

    console.log(`Sent weekly digest to ${sent} users`);
  },
});

// ============================================================
// 4. NEW EVENT NOTIFICATION — triggered from events:create
//    Notifies all users when a new event is posted
// ============================================================

export const notifyNewEvent = internalAction({
  args: {
    eventId: v.id("events"),
    hostId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const data = await ctx.runQuery(
      internal.reengagement.getNewEventNotificationData,
      { eventId: args.eventId, hostId: args.hostId }
    );

    if (!data) return;

    let sent = 0;
    for (const recipientId of data.recipientIds) {
      await ctx.runAction(internal.notifications.notifyUser, {
        recipientId,
        senderId: data.hostId,
        type: "new_event",
        title: `${data.hostName} posted a new event: ${data.eventTitle}`,
        data: { eventId: data.eventId },
      });
      sent++;
    }

    console.log(`Notified ${sent} users about new event`);
  },
});

export const getNewEventNotificationData = internalQuery({
  args: {
    eventId: v.id("events"),
    hostId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const event = await ctx.db.get(args.eventId);
    const host = await ctx.db.get(args.hostId);
    if (!event || !host) return null;

    // Notify all onboarded users except the host
    const allUsers = await ctx.db.query("users").collect();
    const recipientIds = allUsers
      .filter((m) => m.isOnboarded && m._id !== args.hostId)
      .map((m) => m._id);

    return {
      eventId: args.eventId,
      eventTitle: event.title,
      hostId: args.hostId,
      hostName: host.name,
      recipientIds,
    };
  },
});

// ============================================================
// 5. INACTIVITY NUDGE — runs daily
//    Nudges users who haven't posted or commented in 7+ days
// ============================================================

export const getInactiveUsers = internalQuery({
  handler: async (ctx) => {
    const sevenDaysAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;

    const allUsers = await ctx.db.query("users").collect();
    const onboarded = allUsers.filter((m) => m.isOnboarded);

    const inactiveUserIds = [];
    for (const user of onboarded) {
      // Check for recent posts
      const recentPost = await ctx.db
        .query("posts")
        .withIndex("by_author", (q) => q.eq("authorId", user._id))
        .order("desc")
        .first();

      if (recentPost && recentPost.createdAt > sevenDaysAgo) continue;

      // Check for recent comments
      const recentComment = await ctx.db
        .query("comments")
        .withIndex("by_author", (q) => q.eq("authorId", user._id))
        .order("desc")
        .first();

      if (recentComment && recentComment.createdAt > sevenDaysAgo) continue;

      inactiveUserIds.push(user._id);
    }

    return inactiveUserIds;
  },
});

export const sendInactivityNudges = internalAction({
  handler: async (ctx) => {
    const inactiveUserIds = await ctx.runQuery(
      internal.reengagement.getInactiveUsers
    );

    let sent = 0;
    for (const userId of inactiveUserIds) {
      // Dedup: only nudge once per 7 days
      const alreadySent = await ctx.runQuery(
        internal.notifications.hasRecentNotification,
        {
          recipientId: userId,
          type: "inactivity_nudge",
          sinceTimestamp: Date.now() - 7 * 24 * 60 * 60 * 1000,
        }
      );

      if (alreadySent) continue;

      await ctx.runAction(internal.notifications.notifySystem, {
        recipientId: userId,
        type: "inactivity_nudge",
        title: "Your connections are posting — come see what's new",
        body: "Check out what the community has been up to",
      });
      sent++;
    }

    if (sent > 0) console.log(`Sent ${sent} inactivity nudges`);
  },
});

// ============================================================
// 6. MILESTONE CELEBRATIONS — runs daily
//    Celebrates connection milestones: 5, 10, 25, 50, 100
// ============================================================

const MILESTONES = [5, 10, 25, 50, 100];

export const getMilestoneEligibleUsers = internalQuery({
  handler: async (ctx) => {
    const allUsers = await ctx.db.query("users").collect();
    const onboarded = allUsers.filter((m) => m.isOnboarded);

    const eligible = [];
    for (const user of onboarded) {
      // Count connections (both directions)
      const asRequester = await ctx.db
        .query("connections")
        .withIndex("by_requester", (q) => q.eq("requesterId", user._id))
        .filter((q) => q.eq(q.field("status"), "connected"))
        .collect();

      const asAccepter = await ctx.db
        .query("connections")
        .withIndex("by_accepter", (q) => q.eq("accepterId", user._id))
        .filter((q) => q.eq(q.field("status"), "connected"))
        .collect();

      const connectionCount = asRequester.length + asAccepter.length;

      // Find the highest milestone they've hit
      const hitMilestone = MILESTONES.filter((m) => connectionCount >= m).pop();
      if (hitMilestone) {
        eligible.push({ userId: user._id, milestone: hitMilestone });
      }
    }

    return eligible;
  },
});

export const sendMilestoneCelebrations = internalAction({
  handler: async (ctx) => {
    const eligible = await ctx.runQuery(
      internal.reengagement.getMilestoneEligibleUsers
    );

    let sent = 0;
    for (const item of eligible) {
      // Dedup: check if already celebrated this milestone (ever)
      // Use a long lookback to prevent re-celebrating the same milestone
      const alreadyCelebrated = await ctx.runQuery(
        internal.notifications.hasRecentNotification,
        {
          recipientId: item.userId,
          type: "milestone",
          // Check last 365 days for this type — effectively "ever" for milestones
          sinceTimestamp: Date.now() - 365 * 24 * 60 * 60 * 1000,
        }
      );

      if (alreadyCelebrated) continue;

      await ctx.runAction(internal.notifications.notifySystem, {
        recipientId: item.userId,
        type: "milestone",
        title: `You've hit ${item.milestone} connections!`,
        body: "Your network is growing — keep building",
      });
      sent++;
    }

    if (sent > 0) console.log(`Sent ${sent} milestone celebrations`);
  },
});

// ============================================================
// 7. CONTENT PROMPTS — Thursday 10am CT (16:00 UTC)
//    Gentle nudge to share what they're working on
// ============================================================

export const getUsersForContentPrompt = internalQuery({
  handler: async (ctx) => {
    const sevenDaysAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;

    const allUsers = await ctx.db.query("users").collect();
    const onboarded = allUsers.filter((m) => m.isOnboarded);

    // Only prompt users who haven't posted recently
    const eligible = [];
    for (const user of onboarded) {
      const recentPost = await ctx.db
        .query("posts")
        .withIndex("by_author", (q) => q.eq("authorId", user._id))
        .order("desc")
        .first();

      if (!recentPost || recentPost.createdAt < sevenDaysAgo) {
        eligible.push(user._id);
      }
    }

    return eligible;
  },
});

export const sendContentPrompts = internalAction({
  handler: async (ctx) => {
    const eligible = await ctx.runQuery(
      internal.reengagement.getUsersForContentPrompt
    );

    let sent = 0;
    for (const userId of eligible) {
      // Dedup: only prompt once per 7 days
      const alreadySent = await ctx.runQuery(
        internal.notifications.hasRecentNotification,
        {
          recipientId: userId,
          type: "content_prompt",
          sinceTimestamp: Date.now() - 7 * 24 * 60 * 60 * 1000,
        }
      );

      if (alreadySent) continue;

      await ctx.runAction(internal.notifications.notifySystem, {
        recipientId: userId,
        type: "content_prompt",
        title: "What are you working on this week?",
        body: "Share an update with the community",
      });
      sent++;
    }

    if (sent > 0) console.log(`Sent ${sent} content prompts`);
  },
});

// ============================================================
// 7. MEET NUDGES — runs every 6 hours
//    After 5+ messages in a conversation, nudge both users to meet IRL
// ============================================================

export const getConversationsForMeetNudge = internalQuery({
  handler: async (ctx) => {
    const conversations = await ctx.db
      .query("conversations")
      .collect();

    const eligible = [];
    for (const convo of conversations) {
      // Skip if already nudged or not active
      if (convo.meetNudgeSentAt) continue;
      if (convo.status === "request") continue;

      // Count messages
      const messages = await ctx.db
        .query("messages")
        .withIndex("by_conversation", (q) => q.eq("conversationId", convo._id))
        .collect();

      if (messages.length >= 5) {
        eligible.push({
          conversationId: convo._id,
          participant1Id: convo.participant1Id,
          participant2Id: convo.participant2Id,
        });
      }
    }

    return eligible;
  },
});

export const markMeetNudgeSent = internalMutation({
  args: { conversationId: v.id("conversations") },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.conversationId, {
      meetNudgeSentAt: Date.now(),
    });
  },
});

export const sendMeetNudges = internalAction({
  handler: async (ctx) => {
    const eligible = await ctx.runQuery(
      internal.reengagement.getConversationsForMeetNudge
    );

    let sent = 0;
    for (const convo of eligible) {
      // Get both user names
      const user1 = await ctx.runQuery(internal.users.getWithEmbedding, { id: convo.participant1Id });
      const user2 = await ctx.runQuery(internal.users.getWithEmbedding, { id: convo.participant2Id });

      if (!user1 || !user2) continue;

      const firstName1 = user1.name.split(" ")[0];
      const firstName2 = user2.name.split(" ")[0];

      // Nudge user 1
      await ctx.runAction(internal.notifications.notifySystem, {
        recipientId: convo.participant1Id,
        type: "meet_nudge",
        title: `You and ${firstName2} are both on campus`,
        body: "Grab coffee this week?",
        data: { conversationId: convo.conversationId },
      });

      // Nudge user 2
      await ctx.runAction(internal.notifications.notifySystem, {
        recipientId: convo.participant2Id,
        type: "meet_nudge",
        title: `You and ${firstName1} are both on campus`,
        body: "Grab coffee this week?",
        data: { conversationId: convo.conversationId },
      });

      // Mark as sent
      await ctx.runMutation(internal.reengagement.markMeetNudgeSent, {
        conversationId: convo.conversationId,
      });

      sent++;
    }

    if (sent > 0) console.log(`Sent meet nudges for ${sent} conversations`);
  },
});
