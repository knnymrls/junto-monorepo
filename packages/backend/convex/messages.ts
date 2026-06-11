import { v } from "convex/values";
import { query, mutation } from "./_generated/server";
import { internal } from "./_generated/api";
import { Id } from "./_generated/dataModel";

// === HELPERS ===

function getCanonicalParticipants(id1: Id<"users">, id2: Id<"users">) {
  if (id1 < id2) {
    return { p1: id1, p2: id2 };
  }
  return { p1: id2, p2: id1 };
}

async function areConnected(ctx: any, id1: Id<"users">, id2: Id<"users">): Promise<boolean> {
  const conn1 = await ctx.db
    .query("connections")
    .withIndex("by_requester", (q: any) => q.eq("requesterId", id1))
    .filter((q: any) =>
      q.and(
        q.eq(q.field("accepterId"), id2),
        q.eq(q.field("status"), "connected")
      )
    )
    .first();
  if (conn1) return true;

  const conn2 = await ctx.db
    .query("connections")
    .withIndex("by_requester", (q: any) => q.eq("requesterId", id2))
    .filter((q: any) =>
      q.and(
        q.eq(q.field("accepterId"), id1),
        q.eq(q.field("status"), "connected")
      )
    )
    .first();
  return !!conn2;
}

// === QUERIES ===

// List conversations for a user (with other participant info + unread count)
export const listConversations = query({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    const asP1 = await ctx.db
      .query("conversations")
      .withIndex("by_participant1", (q) => q.eq("participant1Id", args.userId))
      .collect();

    const asP2 = await ctx.db
      .query("conversations")
      .withIndex("by_participant2", (q) => q.eq("participant2Id", args.userId))
      .collect();

    const allConversations = [...asP1, ...asP2];
    allConversations.sort((a, b) => b.lastMessageAt - a.lastMessageAt);

    const enriched = await Promise.all(
      allConversations.map(async (conv) => {
        const otherParticipantId =
          conv.participant1Id === args.userId
            ? conv.participant2Id
            : conv.participant1Id;
        const otherParticipant = await ctx.db.get(otherParticipantId);
        const unreadCount =
          conv.participant1Id === args.userId
            ? conv.participant1UnreadCount
            : conv.participant2UnreadCount;

        // Determine if this is a request TO this user (they didn't initiate it)
        const status = conv.status ?? "active";
        const isRequest = status === "request" && conv.initiatorId !== args.userId;
        const isSentRequest = status === "request" && conv.initiatorId === args.userId;

        return {
          ...conv,
          otherParticipant,
          unreadCount,
          status,
          isRequest,
          isSentRequest,
        };
      })
    );

    return enriched;
  },
});

// Get messages for a conversation
export const getMessages = query({
  args: {
    conversationId: v.id("conversations"),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const limit = args.limit ?? 100;

    // Newest `limit` messages, returned oldest-first for display. Taking
    // ascending returned the OLDEST window, so threads past the limit never
    // showed new messages at all.
    const messages = await ctx.db
      .query("messages")
      .withIndex("by_conversation", (q) =>
        q.eq("conversationId", args.conversationId)
      )
      .order("desc")
      .take(limit);

    return messages.reverse();
  },
});

// Get total unread message count across ACTIVE conversations only (for tab badge)
export const getUnreadMessageCount = query({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    const asP1 = await ctx.db
      .query("conversations")
      .withIndex("by_participant1", (q) => q.eq("participant1Id", args.userId))
      .collect();

    const asP2 = await ctx.db
      .query("conversations")
      .withIndex("by_participant2", (q) => q.eq("participant2Id", args.userId))
      .collect();

    let total = 0;
    for (const conv of asP1) {
      // Only count active conversations (not requests to me)
      const status = conv.status ?? "active";
      if (status === "active" || conv.initiatorId === args.userId) {
        total += conv.participant1UnreadCount;
      }
    }
    for (const conv of asP2) {
      const status = conv.status ?? "active";
      if (status === "active" || conv.initiatorId === args.userId) {
        total += conv.participant2UnreadCount;
      }
    }

    return total;
  },
});

// Get existing conversation between two users (or null)
export const getConversationBetween = query({
  args: {
    userId1: v.id("users"),
    userId2: v.id("users"),
  },
  handler: async (ctx, args) => {
    const { p1, p2 } = getCanonicalParticipants(args.userId1, args.userId2);

    const conversation = await ctx.db
      .query("conversations")
      .withIndex("by_participant1", (q) => q.eq("participant1Id", p1))
      .filter((q) => q.eq(q.field("participant2Id"), p2))
      .first();

    return conversation;
  },
});

// Get typing indicator for a conversation
export const getTypingIndicator = query({
  args: {
    conversationId: v.id("conversations"),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const now = Date.now();

    const indicators = await ctx.db
      .query("typingIndicators")
      .withIndex("by_conversation", (q) =>
        q.eq("conversationId", args.conversationId)
      )
      .collect();

    const otherTyping = indicators.find(
      (ind) => ind.userId !== args.userId && ind.expiresAt > now
    );

    return !!otherTyping;
  },
});

// === MUTATIONS ===

// Send a message (works for both connected users and message requests)
export const sendMessage = mutation({
  args: {
    senderId: v.id("users"),
    recipientId: v.id("users"),
    content: v.string(),
    gifUrl: v.optional(v.string()),
    replyToId: v.optional(v.id("messages")),
  },
  handler: async (ctx, args) => {
    const { p1, p2 } = getCanonicalParticipants(args.senderId, args.recipientId);
    const now = Date.now();

    // Check if connected
    const connected = await areConnected(ctx, args.senderId, args.recipientId);

    // Find or create conversation
    let conversation = await ctx.db
      .query("conversations")
      .withIndex("by_participant1", (q) => q.eq("participant1Id", p1))
      .filter((q) => q.eq(q.field("participant2Id"), p2))
      .first();

    let conversationId: Id<"conversations">;

    if (conversation) {
      conversationId = conversation._id;

      const isRecipientP1 = args.recipientId === p1;
      const preview = args.gifUrl ? "Sent a GIF" : args.content.substring(0, 100);
      await ctx.db.patch(conversationId, {
        lastMessageAt: now,
        lastMessagePreview: preview,
        lastMessageSenderId: args.senderId,
        participant1UnreadCount: isRecipientP1
          ? conversation.participant1UnreadCount + 1
          : conversation.participant1UnreadCount,
        participant2UnreadCount: isRecipientP1
          ? conversation.participant2UnreadCount
          : conversation.participant2UnreadCount + 1,
      });
    } else {
      // Create new conversation
      const isRecipientP1 = args.recipientId === p1;
      const status = connected ? "active" : "request";
      const newPreview = args.gifUrl ? "Sent a GIF" : args.content.substring(0, 100);
      conversationId = await ctx.db.insert("conversations", {
        participant1Id: p1,
        participant2Id: p2,
        lastMessageAt: now,
        lastMessagePreview: newPreview,
        lastMessageSenderId: args.senderId,
        participant1UnreadCount: isRecipientP1 ? 1 : 0,
        participant2UnreadCount: isRecipientP1 ? 0 : 1,
        status,
        initiatorId: args.senderId,
        createdAt: now,
      });
    }

    // Insert message
    const messageId = await ctx.db.insert("messages", {
      conversationId,
      senderId: args.senderId,
      content: args.content,
      gifUrl: args.gifUrl,
      replyToId: args.replyToId,
      createdAt: now,
    });

    // Clear sender's typing indicator
    const typingIndicators = await ctx.db
      .query("typingIndicators")
      .withIndex("by_conversation", (q) =>
        q.eq("conversationId", conversationId)
      )
      .collect();

    for (const ind of typingIndicators) {
      if (ind.userId === args.senderId) {
        await ctx.db.delete(ind._id);
      }
    }

    // Notify recipient
    const sender = await ctx.db.get(args.senderId);
    const senderName = sender?.name || "Someone";
    const isRequest = !connected && !conversation;
    await ctx.scheduler.runAfter(0, internal.notifications.notifyUser, {
      recipientId: args.recipientId,
      senderId: args.senderId,
      type: isRequest ? "message_request" : "new_message",
      title: isRequest
        ? `${senderName} sent you a message request`
        : `${senderName} sent you a message`,
      body: args.gifUrl ? "Sent a GIF" : args.content.substring(0, 100),
      data: {
        conversationId,
      },
    });

    return messageId;
  },
});

// Accept a message request (moves conversation from "request" to "active")
export const acceptMessageRequest = mutation({
  args: {
    conversationId: v.id("conversations"),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const conversation = await ctx.db.get(args.conversationId);
    if (!conversation) throw new Error("Conversation not found");

    // Only the recipient (non-initiator) can accept
    if (conversation.initiatorId === args.userId) {
      throw new Error("Cannot accept your own request");
    }

    await ctx.db.patch(args.conversationId, {
      status: "active",
    });
  },
});

// Delete/decline a message request
export const declineMessageRequest = mutation({
  args: {
    conversationId: v.id("conversations"),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const conversation = await ctx.db.get(args.conversationId);
    if (!conversation) throw new Error("Conversation not found");

    // Delete all messages in the conversation
    const messages = await ctx.db
      .query("messages")
      .withIndex("by_conversation", (q) =>
        q.eq("conversationId", args.conversationId)
      )
      .collect();

    for (const msg of messages) {
      await ctx.db.delete(msg._id);
    }

    // Delete typing indicators
    const indicators = await ctx.db
      .query("typingIndicators")
      .withIndex("by_conversation", (q) =>
        q.eq("conversationId", args.conversationId)
      )
      .collect();

    for (const ind of indicators) {
      await ctx.db.delete(ind._id);
    }

    // Delete the conversation
    await ctx.db.delete(args.conversationId);
  },
});

// Mark conversation as read for a participant
export const markConversationRead = mutation({
  args: {
    conversationId: v.id("conversations"),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const conversation = await ctx.db.get(args.conversationId);
    if (!conversation) throw new Error("Conversation not found");

    if (conversation.participant1Id === args.userId) {
      await ctx.db.patch(args.conversationId, { participant1UnreadCount: 0 });
    } else if (conversation.participant2Id === args.userId) {
      await ctx.db.patch(args.conversationId, { participant2UnreadCount: 0 });
    }

    const now = Date.now();
    const messages = await ctx.db
      .query("messages")
      .withIndex("by_conversation", (q) =>
        q.eq("conversationId", args.conversationId)
      )
      .filter((q) =>
        q.and(
          q.neq(q.field("senderId"), args.userId),
          q.eq(q.field("readAt"), undefined)
        )
      )
      .collect();

    for (const msg of messages) {
      await ctx.db.patch(msg._id, { readAt: now });
    }
  },
});

// Set typing indicator
export const setTyping = mutation({
  args: {
    conversationId: v.id("conversations"),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const expiresAt = Date.now() + 5000;

    const existing = await ctx.db
      .query("typingIndicators")
      .withIndex("by_conversation", (q) =>
        q.eq("conversationId", args.conversationId)
      )
      .filter((q) => q.eq(q.field("userId"), args.userId))
      .first();

    if (existing) {
      await ctx.db.patch(existing._id, { expiresAt });
    } else {
      await ctx.db.insert("typingIndicators", {
        conversationId: args.conversationId,
        userId: args.userId,
        expiresAt,
      });
    }
  },
});

// Clear typing indicator
export const clearTyping = mutation({
  args: {
    conversationId: v.id("conversations"),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const existing = await ctx.db
      .query("typingIndicators")
      .withIndex("by_conversation", (q) =>
        q.eq("conversationId", args.conversationId)
      )
      .filter((q) => q.eq(q.field("userId"), args.userId))
      .first();

    if (existing) {
      await ctx.db.delete(existing._id);
    }
  },
});

// Is this message the conversation's most recent one? Used to keep the
// conversation-list preview in sync after an edit/delete.
async function isLatestMessage(
  ctx: any,
  conversationId: Id<"conversations">,
  messageId: Id<"messages">
): Promise<boolean> {
  const latest = await ctx.db
    .query("messages")
    .withIndex("by_conversation", (q: any) =>
      q.eq("conversationId", conversationId)
    )
    .order("desc")
    .first();
  return latest?._id === messageId;
}

// Edit a message (sender only). Updates the conversation preview if it was the
// last message.
export const editMessage = mutation({
  args: {
    messageId: v.id("messages"),
    userId: v.id("users"),
    content: v.string(),
  },
  handler: async (ctx, args) => {
    const message = await ctx.db.get(args.messageId);
    if (!message) throw new Error("Message not found");
    if (message.senderId !== args.userId) throw new Error("Not your message");
    if (message.deletedAt) throw new Error("Message was deleted");

    await ctx.db.patch(args.messageId, {
      content: args.content,
      editedAt: Date.now(),
    });

    if (await isLatestMessage(ctx, message.conversationId, args.messageId)) {
      await ctx.db.patch(message.conversationId, {
        lastMessagePreview: args.content.substring(0, 100),
      });
    }
  },
});

// Soft-delete a message (sender only). Keeps the row so the thread layout is
// stable, but blanks the content and drops reactions.
export const deleteMessage = mutation({
  args: {
    messageId: v.id("messages"),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const message = await ctx.db.get(args.messageId);
    if (!message) throw new Error("Message not found");
    if (message.senderId !== args.userId) throw new Error("Not your message");

    await ctx.db.patch(args.messageId, {
      deletedAt: Date.now(),
      content: "",
      gifUrl: undefined,
      reactions: [],
    });

    if (await isLatestMessage(ctx, message.conversationId, args.messageId)) {
      await ctx.db.patch(message.conversationId, {
        lastMessagePreview: "Message deleted",
      });
    }
  },
});

// Toggle an emoji reaction on a message for a user. Same user + emoji removes
// it; otherwise it's added (a user may react with several distinct emojis).
export const toggleReaction = mutation({
  args: {
    messageId: v.id("messages"),
    userId: v.id("users"),
    emoji: v.string(),
  },
  handler: async (ctx, args) => {
    const message = await ctx.db.get(args.messageId);
    if (!message) throw new Error("Message not found");
    if (message.deletedAt) return;

    const reactions = message.reactions ?? [];
    const existingIndex = reactions.findIndex(
      (r) => r.userId === args.userId && r.emoji === args.emoji
    );

    const next =
      existingIndex >= 0
        ? reactions.filter((_, i) => i !== existingIndex)
        : [...reactions, { userId: args.userId, emoji: args.emoji }];

    await ctx.db.patch(args.messageId, { reactions: next });
  },
});
