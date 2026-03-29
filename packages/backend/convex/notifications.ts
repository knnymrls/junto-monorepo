import { v } from "convex/values";
import { query, mutation, action, internalMutation, internalQuery, internalAction } from "./_generated/server";
import { internal } from "./_generated/api";
import { importPKCS8, SignJWT } from "jose";

// === QUERIES ===

// Get notifications for a user
export const listForUser = query({
  args: {
    userId: v.id("users"),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const limit = args.limit ?? 50;

    const notifications = await ctx.db
      .query("notifications")
      .withIndex("by_recipient", (q) => q.eq("recipientId", args.userId))
      .order("desc")
      .take(limit);

    // Fetch sender info for each notification
    const notificationsWithSenders = await Promise.all(
      notifications.map(async (notification) => {
        let sender = null;
        if (notification.data?.senderId) {
          sender = await ctx.db.get(notification.data.senderId);
        }
        return {
          ...notification,
          sender,
        };
      })
    );

    return notificationsWithSenders;
  },
});

// Get unread count for a user
export const getUnreadCount = query({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    const unread = await ctx.db
      .query("notifications")
      .withIndex("by_recipient_unread", (q) =>
        q.eq("recipientId", args.userId).eq("readAt", undefined)
      )
      .collect();

    return unread.length;
  },
});

// === MUTATIONS ===

// Create a notification (internal use)
export const create = internalMutation({
  args: {
    recipientId: v.id("users"),
    type: v.string(),
    title: v.string(),
    body: v.optional(v.string()),
    data: v.optional(v.object({
      postId: v.optional(v.id("posts")),
      commentId: v.optional(v.id("comments")),
      senderId: v.optional(v.id("users")),
      connectionId: v.optional(v.id("connections")),
      eventId: v.optional(v.id("events")),
      conversationId: v.optional(v.id("conversations")),
    })),
  },
  handler: async (ctx, args) => {
    return await ctx.db.insert("notifications", {
      recipientId: args.recipientId,
      type: args.type,
      title: args.title,
      body: args.body,
      data: args.data,
      createdAt: Date.now(),
    });
  },
});

// Mark notification as read
export const markAsRead = mutation({
  args: { notificationId: v.id("notifications") },
  handler: async (ctx, args) => {
    const notification = await ctx.db.get(args.notificationId);
    if (!notification) throw new Error("Notification not found");

    await ctx.db.patch(args.notificationId, {
      readAt: Date.now(),
    });
  },
});

// Mark all notifications as read for a user
export const markAllAsRead = mutation({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    const unread = await ctx.db
      .query("notifications")
      .withIndex("by_recipient_unread", (q) =>
        q.eq("recipientId", args.userId).eq("readAt", undefined)
      )
      .collect();

    const now = Date.now();
    for (const notification of unread) {
      await ctx.db.patch(notification._id, { readAt: now });
    }

    return unread.length;
  },
});

// Update notification title (e.g. after accepting a connection request)
export const updateTitle = mutation({
  args: {
    notificationId: v.id("notifications"),
    title: v.string(),
  },
  handler: async (ctx, args) => {
    const notification = await ctx.db.get(args.notificationId);
    if (!notification) throw new Error("Notification not found");

    await ctx.db.patch(args.notificationId, {
      title: args.title,
    });
  },
});

// Delete a notification
export const remove = mutation({
  args: { notificationId: v.id("notifications") },
  handler: async (ctx, args) => {
    await ctx.db.delete(args.notificationId);
  },
});

// Check if a notification of a given type was recently sent to a user (for dedup)
export const hasRecentNotification = internalQuery({
  args: {
    recipientId: v.id("users"),
    type: v.string(),
    sinceTimestamp: v.number(),
  },
  handler: async (ctx, args) => {
    const recent = await ctx.db
      .query("notifications")
      .withIndex("by_recipient", (q) => q.eq("recipientId", args.recipientId))
      .filter((q) =>
        q.and(
          q.eq(q.field("type"), args.type),
          q.gte(q.field("createdAt"), args.sinceTimestamp)
        )
      )
      .first();
    return recent !== null;
  },
});

// === ACTIONS (for sending push notifications) ===

// Internal action to send push notification via APNs
export const sendPushNotification = internalAction({
  args: {
    userId: v.id("users"),
    title: v.string(),
    body: v.string(),
    data: v.optional(v.any()),
  },
  handler: async (ctx, args) => {
    // Get device tokens for the user
    const tokens = await ctx.runQuery(internal.deviceTokens.listForUserInternal, {
      userId: args.userId,
    });

    if (tokens.length === 0) {
      console.log(`No device tokens found for user ${args.userId}`);
      return { sent: 0, failed: 0 };
    }

    // Get APNs configuration from environment
    const apnsKeyId = process.env.APNS_KEY_ID;
    const apnsTeamId = process.env.APNS_TEAM_ID;
    const apnsKey = process.env.APNS_KEY;
    const apnsBundleId = process.env.APNS_BUNDLE_ID;

    if (!apnsKeyId || !apnsTeamId || !apnsKey || !apnsBundleId) {
      console.error("APNs configuration missing");
      return { sent: 0, failed: 0, error: "APNs not configured" };
    }

    let sent = 0;
    let failed = 0;
    const invalidTokens: string[] = [];

    for (const tokenDoc of tokens) {
      if (tokenDoc.platform !== "ios") continue;

      try {
        const jwt = await generateApnsJwt(apnsKeyId, apnsTeamId, apnsKey);
        const response = await sendApnsNotification(
          tokenDoc.token,
          {
            aps: {
              alert: {
                title: args.title,
                body: args.body,
              },
              sound: "default",
              badge: 1,
            },
            data: args.data,
          },
          jwt,
          apnsBundleId
        );

        if (response.success) {
          sent++;
        } else if (response.reason === "BadDeviceToken" || response.reason === "Unregistered") {
          // Token is invalid, mark for removal
          invalidTokens.push(tokenDoc.token);
          failed++;
          console.error(`APNs rejected token: ${response.reason}`);
        } else {
          failed++;
          console.error(`APNs error: ${response.reason}`);
        }
      } catch (error) {
        console.error(`Error sending push to ${tokenDoc.token}:`, error);
        failed++;
      }
    }

    // Remove invalid tokens
    for (const token of invalidTokens) {
      await ctx.runMutation(internal.deviceTokens.removeInternal, { token });
    }

    console.log(`Push notifications sent: ${sent}, failed: ${failed}`);
    return { sent, failed };
  },
});

// Helper to create and send notification + push
export const notifyUser = internalAction({
  args: {
    recipientId: v.id("users"),
    senderId: v.id("users"),
    type: v.string(),
    title: v.string(),
    body: v.optional(v.string()),
    data: v.optional(v.object({
      postId: v.optional(v.id("posts")),
      commentId: v.optional(v.id("comments")),
      connectionId: v.optional(v.id("connections")),
      eventId: v.optional(v.id("events")),
      conversationId: v.optional(v.id("conversations")),
    })),
  },
  handler: async (ctx, args) => {
    // Don't notify yourself
    if (args.recipientId === args.senderId) {
      return;
    }

    // Create in-app notification
    await ctx.runMutation(internal.notifications.create, {
      recipientId: args.recipientId,
      type: args.type,
      title: args.title,
      body: args.body,
      data: {
        ...args.data,
        senderId: args.senderId,
      },
    });

    // Send push notification
    await ctx.runAction(internal.notifications.sendPushNotification, {
      userId: args.recipientId,
      title: args.title,
      body: args.body || "",
      data: {
        type: args.type,
        ...args.data,
      },
    });
  },
});

// System notification (no sender, for crons/re-engagement)
export const notifySystem = internalAction({
  args: {
    recipientId: v.id("users"),
    type: v.string(),
    title: v.string(),
    body: v.optional(v.string()),
    data: v.optional(v.object({
      postId: v.optional(v.id("posts")),
      commentId: v.optional(v.id("comments")),
      senderId: v.optional(v.id("users")),
      connectionId: v.optional(v.id("connections")),
      eventId: v.optional(v.id("events")),
      conversationId: v.optional(v.id("conversations")),
    })),
  },
  handler: async (ctx, args) => {
    // Create in-app notification
    await ctx.runMutation(internal.notifications.create, {
      recipientId: args.recipientId,
      type: args.type,
      title: args.title,
      body: args.body,
      data: args.data,
    });

    // Send push notification
    await ctx.runAction(internal.notifications.sendPushNotification, {
      userId: args.recipientId,
      title: args.title,
      body: args.body || "",
      data: { type: args.type },
    });
  },
});

// === HELPER FUNCTIONS ===

async function generateApnsJwt(
  keyId: string,
  teamId: string,
  privateKeyRaw: string
): Promise<string> {
  // Ensure key is in proper PEM format (env vars may strip headers/newlines)
  let pem = privateKeyRaw.trim();
  if (!pem.startsWith("-----BEGIN PRIVATE KEY-----")) {
    pem = `-----BEGIN PRIVATE KEY-----\n${pem}\n-----END PRIVATE KEY-----`;
  }
  const privateKey = await importPKCS8(pem, "ES256");
  return await new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: keyId })
    .setIssuer(teamId)
    .setIssuedAt()
    .sign(privateKey);
}

async function sendApnsNotification(
  deviceToken: string,
  payload: object,
  jwt: string,
  bundleId: string
): Promise<{ success: boolean; reason?: string }> {
  // Use production URL for App Store apps, sandbox for development
  const isProduction = process.env.APNS_PRODUCTION === "true";
  const apnsUrl = isProduction
    ? `https://api.push.apple.com/3/device/${deviceToken}`
    : `https://api.sandbox.push.apple.com/3/device/${deviceToken}`;

  try {
    const response = await fetch(apnsUrl, {
      method: "POST",
      headers: {
        Authorization: `bearer ${jwt}`,
        "apns-topic": bundleId,
        "apns-push-type": "alert",
        "apns-priority": "10",
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (response.status === 200) {
      return { success: true };
    }

    const errorBody = await response.json().catch(() => ({}));
    return {
      success: false,
      reason: (errorBody as { reason?: string }).reason || `HTTP ${response.status}`,
    };
  } catch (error) {
    console.error("APNs request failed:", error);
    return { success: false, reason: "NetworkError" };
  }
}
