import { v } from "convex/values";
import { query, mutation } from "./_generated/server";
import { internal } from "./_generated/api";

// Resolve a stored image reference to a URL. Storage IDs are resolved via
// ctx.storage.getUrl; full HTTP URLs (legacy seed data) pass through.
async function resolveImageUrl(
  ctx: { storage: { getUrl: (id: any) => Promise<string | null> } },
  url: string | null | undefined,
): Promise<string | undefined> {
  if (!url) return undefined;
  if (url.startsWith("http")) return url;
  return (await ctx.storage.getUrl(url as any)) ?? undefined;
}

// List upcoming events with preview data
export const listUpcoming = query({
  args: {
    universityId: v.optional(v.id("universities")),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const now = Date.now();

    let q = ctx.db.query("events").withIndex("by_date");

    const events = await q.collect();

    // Filter for future events
    let upcomingEvents = events.filter((e) => e.date > now);

    // Filter by university if specified
    if (args.universityId) {
      upcomingEvents = upcomingEvents.filter(
        (e) => e.universityId === args.universityId
      );
    }

    // Sort by date ascending
    upcomingEvents.sort((a, b) => a.date - b.date);

    // Apply limit if specified
    if (args.limit) {
      upcomingEvents = upcomingEvents.slice(0, args.limit);
    }

    // Enrich with preview data
    const enrichedEvents = await Promise.all(
      upcomingEvents.map(async (event) => {
        // Get host
        const host = await ctx.db.get(event.createdBy);

        // Get RSVPs
        const rsvps = await ctx.db
          .query("eventRsvps")
          .withIndex("by_event", (q) => q.eq("eventId", event._id))
          .collect();

        const goingCount = rsvps.filter((r) => r.status === "going").length;

        // Get first 3 attendee avatars
        const previewRsvps = rsvps.filter((r) => r.status === "going").slice(0, 3);
        const attendeePreviews = await Promise.all(
          previewRsvps.map(async (rsvp) => {
            const user = await ctx.db.get(rsvp.userId);
            return user ? { id: user._id, name: user.name, avatarUrl: user.avatarUrl } : null;
          })
        );

        return {
          ...event,
          imageUrl: await resolveImageUrl(ctx, event.imageUrl),
          host: host ? { id: host._id, name: host.name, avatarUrl: host.avatarUrl } : null,
          goingCount,
          attendeePreviews: attendeePreviews.filter(Boolean),
        };
      })
    );

    return enrichedEvents;
  },
});

// List past events with preview data (most recent first)
export const listPast = query({
  args: {
    universityId: v.optional(v.id("universities")),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const now = Date.now();

    const events = await ctx.db.query("events").withIndex("by_date").collect();

    let pastEvents = events.filter((e) => e.date < now);

    if (args.universityId) {
      pastEvents = pastEvents.filter((e) => e.universityId === args.universityId);
    }

    pastEvents.sort((a, b) => b.date - a.date);

    if (args.limit) {
      pastEvents = pastEvents.slice(0, args.limit);
    }

    const enrichedEvents = await Promise.all(
      pastEvents.map(async (event) => {
        const host = await ctx.db.get(event.createdBy);

        const rsvps = await ctx.db
          .query("eventRsvps")
          .withIndex("by_event", (q) => q.eq("eventId", event._id))
          .collect();

        const goingCount = rsvps.filter((r) => r.status === "going").length;

        const previewRsvps = rsvps.filter((r) => r.status === "going").slice(0, 3);
        const attendeePreviews = await Promise.all(
          previewRsvps.map(async (rsvp) => {
            const user = await ctx.db.get(rsvp.userId);
            return user ? { id: user._id, name: user.name, avatarUrl: user.avatarUrl } : null;
          })
        );

        return {
          ...event,
          imageUrl: await resolveImageUrl(ctx, event.imageUrl),
          host: host ? { id: host._id, name: host.name, avatarUrl: host.avatarUrl } : null,
          goingCount,
          attendeePreviews: attendeePreviews.filter(Boolean),
        };
      })
    );

    return enrichedEvents;
  },
});

// Get single event with RSVP count, host, and attendee previews
export const get = query({
  args: { id: v.id("events") },
  handler: async (ctx, args) => {
    const event = await ctx.db.get(args.id);
    if (!event) return null;

    // Get the host/creator
    const host = await ctx.db.get(event.createdBy);

    // Get RSVPs for this event
    const rsvps = await ctx.db
      .query("eventRsvps")
      .withIndex("by_event", (q) => q.eq("eventId", args.id))
      .collect();

    const goingRsvps = rsvps.filter((r) => r.status === "going");
    const interestedRsvps = rsvps.filter((r) => r.status === "interested");

    // Get first few attendees for preview (going first, then interested)
    const previewUserIds = [
      ...goingRsvps.slice(0, 5).map((r) => r.userId),
      ...interestedRsvps.slice(0, 5 - goingRsvps.length).map((r) => r.userId),
    ].slice(0, 5);

    const attendeePreviews = await Promise.all(
      previewUserIds.map(async (id) => {
        const user = await ctx.db.get(id);
        return user ? { id: user._id, name: user.name, avatarUrl: user.avatarUrl } : null;
      })
    );

    return {
      ...event,
      imageUrl: await resolveImageUrl(ctx, event.imageUrl),
      host: host ? { id: host._id, name: host.name, avatarUrl: host.avatarUrl, headline: host.headline } : null,
      goingCount: goingRsvps.length,
      interestedCount: interestedRsvps.length,
      attendeePreviews: attendeePreviews.filter(Boolean),
    };
  },
});

// RSVP to an event
export const rsvp = mutation({
  args: {
    eventId: v.id("events"),
    userId: v.id("users"),
    status: v.string(), // "going", "interested", "not_going"
  },
  handler: async (ctx, args) => {
    // Check for existing RSVP
    const existing = await ctx.db
      .query("eventRsvps")
      .withIndex("by_event", (q) => q.eq("eventId", args.eventId))
      .filter((q) => q.eq(q.field("userId"), args.userId))
      .first();

    const now = Date.now();

    let rsvpId;
    if (existing) {
      // Update existing RSVP
      await ctx.db.patch(existing._id, {
        status: args.status,
      });
      rsvpId = existing._id;
    } else {
      // Create new RSVP
      rsvpId = await ctx.db.insert("eventRsvps", {
        eventId: args.eventId,
        userId: args.userId,
        status: args.status,
        createdAt: now,
      });
    }

    // Notify event host when someone RSVPs "going"
    if (args.status === "going") {
      const event = await ctx.db.get(args.eventId);
      if (event && event.createdBy !== args.userId) {
        const user = await ctx.db.get(args.userId);
        const userName = user?.name || "Someone";
        await ctx.scheduler.runAfter(0, internal.notifications.notifyUser, {
          recipientId: event.createdBy,
          senderId: args.userId,
          type: "event_rsvp",
          title: `${userName} is going to ${event.title}`,
          data: { eventId: args.eventId },
        });
      }
    }

    return rsvpId;
  },
});

// Get user's RSVP for an event
export const getUserRsvp = query({
  args: {
    eventId: v.id("events"),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("eventRsvps")
      .withIndex("by_event", (q) => q.eq("eventId", args.eventId))
      .filter((q) => q.eq(q.field("userId"), args.userId))
      .first();
  },
});

// Get all attendees for an event
export const getAttendees = query({
  args: { eventId: v.id("events") },
  handler: async (ctx, args) => {
    const rsvps = await ctx.db
      .query("eventRsvps")
      .withIndex("by_event", (q) => q.eq("eventId", args.eventId))
      .collect();

    const attendees = await Promise.all(
      rsvps.map(async (rsvp) => {
        const user = await ctx.db.get(rsvp.userId);
        return user
          ? {
              id: user._id,
              name: user.name,
              avatarUrl: user.avatarUrl,
              headline: user.headline,
              status: rsvp.status,
            }
          : null;
      })
    );

    // Sort: going first, then interested
    return attendees.filter(Boolean).sort((a, b) => {
      if (a!.status === "going" && b!.status !== "going") return -1;
      if (a!.status !== "going" && b!.status === "going") return 1;
      return 0;
    });
  },
});

// Mark that a user added the event to their calendar
export const markCalendarAdded = mutation({
  args: {
    eventId: v.id("events"),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const rsvp = await ctx.db
      .query("eventRsvps")
      .withIndex("by_event", (q) => q.eq("eventId", args.eventId))
      .filter((q) => q.eq(q.field("userId"), args.userId))
      .first();

    if (rsvp) {
      await ctx.db.patch(rsvp._id, { addedToCalendar: true });
    }
  },
});

// Submit feedback for an event (upsert)
export const submitFeedback = mutation({
  args: {
    eventId: v.id("events"),
    userId: v.id("users"),
    rating: v.number(),
    improvements: v.array(v.string()),
    wantToConnectWith: v.array(v.id("users")),
  },
  handler: async (ctx, args) => {
    // Check for existing feedback via compound index
    const existing = await ctx.db
      .query("eventFeedback")
      .withIndex("by_event_and_user", (q) =>
        q.eq("eventId", args.eventId).eq("userId", args.userId)
      )
      .first();

    if (existing) {
      await ctx.db.patch(existing._id, {
        rating: args.rating,
        improvements: args.improvements,
        wantToConnectWith: args.wantToConnectWith,
      });
      return existing._id;
    }

    return await ctx.db.insert("eventFeedback", {
      ...args,
      createdAt: Date.now(),
    });
  },
});

// Get user's feedback for an event
export const getUserFeedback = query({
  args: {
    eventId: v.id("events"),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("eventFeedback")
      .withIndex("by_event_and_user", (q) =>
        q.eq("eventId", args.eventId).eq("userId", args.userId)
      )
      .first();
  },
});

// Get events needing feedback (user RSVP'd going, event ended, no feedback yet)
export const getEventsNeedingFeedback = query({
  args: {
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const now = Date.now();

    // Get all RSVPs where user is going
    const rsvps = await ctx.db
      .query("eventRsvps")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .filter((q) => q.eq(q.field("status"), "going"))
      .collect();

    const results = [];

    for (const rsvp of rsvps) {
      const event = await ctx.db.get(rsvp.eventId);
      if (!event) continue;

      const endTime = event.endDate ?? event.date + 2 * 60 * 60 * 1000;
      if (endTime >= now) continue;

      // Check if feedback already exists
      const feedback = await ctx.db
        .query("eventFeedback")
        .withIndex("by_event_and_user", (q) =>
          q.eq("eventId", event._id).eq("userId", args.userId)
        )
        .first();

      if (feedback) continue;

      // Enrich with host info
      const host = await ctx.db.get(event.createdBy);

      // Get RSVP counts
      const eventRsvps = await ctx.db
        .query("eventRsvps")
        .withIndex("by_event", (q) => q.eq("eventId", event._id))
        .collect();

      const goingRsvps = eventRsvps.filter((r) => r.status === "going");
      const interestedRsvps = eventRsvps.filter((r) => r.status === "interested");

      // Get attendee previews
      const previewUserIds = goingRsvps.slice(0, 5).map((r) => r.userId);
      const attendeePreviews = await Promise.all(
        previewUserIds.map(async (id) => {
          const user = await ctx.db.get(id);
          return user ? { id: user._id, name: user.name, avatarUrl: user.avatarUrl } : null;
        })
      );

      results.push({
        ...event,
        host: host
          ? { id: host._id, name: host.name, avatarUrl: host.avatarUrl, headline: host.headline }
          : null,
        goingCount: goingRsvps.length,
        interestedCount: interestedRsvps.length,
        attendeePreviews: attendeePreviews.filter(Boolean),
      });
    }

    // Sort most recent first
    results.sort((a, b) => b.date - a.date);

    return results;
  },
});

// List events a user has attended (RSVPd "going")
export const listAttendedByUser = query({
  args: {
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const rsvps = await ctx.db
      .query("eventRsvps")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .filter((q) => q.eq(q.field("status"), "going"))
      .collect();

    const events = await Promise.all(
      rsvps.map(async (rsvp) => {
        const event = await ctx.db.get(rsvp.eventId);
        if (!event) return null;
        return {
          _id: event._id,
          title: event.title,
          date: event.date,
          location: event.location ?? null,
          type: event.type,
        };
      })
    );

    // Filter nulls, sort by date descending
    return events
      .filter((e): e is NonNullable<typeof e> => e !== null)
      .sort((a, b) => b.date - a.date);
  },
});

// Create a new event (host is automatically "going")
export const create = mutation({
  args: {
    title: v.string(),
    description: v.optional(v.string()),
    date: v.number(),
    endDate: v.optional(v.number()),
    location: v.optional(v.string()),
    type: v.string(),
    hostName: v.optional(v.string()),
    category: v.optional(v.string()),
    imageUrl: v.optional(v.string()),
    createdBy: v.id("users"),
    universityId: v.optional(v.id("universities")),
  },
  handler: async (ctx, args) => {
    const now = Date.now();

    const eventId = await ctx.db.insert("events", {
      ...args,
      createdAt: now,
    });

    // Host automatically RSVPs as going
    await ctx.db.insert("eventRsvps", {
      eventId,
      userId: args.createdBy,
      status: "going",
      createdAt: now,
    });

    // Notify all users about the new event
    await ctx.scheduler.runAfter(0, internal.reengagement.notifyNewEvent, {
      eventId,
      hostId: args.createdBy,
    });

    return eventId;
  },
});
