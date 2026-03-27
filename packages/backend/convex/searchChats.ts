import { v } from "convex/values";
import { query, mutation, internalMutation } from "./_generated/server";

// List all search chats for a user, sorted by lastQueryAt desc
export const listChats = query({
  args: {
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const chats = await ctx.db
      .query("searchChats")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .order("desc")
      .collect();
    return chats;
  },
});

// Get all messages for a chat, sorted by createdAt asc
export const getMessages = query({
  args: {
    chatId: v.id("searchChats"),
  },
  handler: async (ctx, args) => {
    const messages = await ctx.db
      .query("searchMessages")
      .withIndex("by_chat", (q) => q.eq("chatId", args.chatId))
      .order("asc")
      .collect();
    return messages;
  },
});

// Create a new search chat
export const createChat = mutation({
  args: {
    userId: v.id("users"),
    title: v.string(),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    const chatId = await ctx.db.insert("searchChats", {
      userId: args.userId,
      title: args.title,
      lastQueryAt: now,
      createdAt: now,
    });
    return chatId;
  },
});

// Internal: create a chat from an action
export const internalCreateChat = internalMutation({
  args: {
    userId: v.id("users"),
    title: v.string(),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    const chatId = await ctx.db.insert("searchChats", {
      userId: args.userId,
      title: args.title,
      lastQueryAt: now,
      createdAt: now,
    });
    return chatId;
  },
});

// Internal: save a message from an action
export const internalSaveMessage = internalMutation({
  args: {
    chatId: v.id("searchChats"),
    role: v.string(),
    content: v.string(),
    results: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    await ctx.db.insert("searchMessages", {
      chatId: args.chatId,
      role: args.role,
      content: args.content,
      results: args.results,
      createdAt: now,
    });
    // Update chat's lastQueryAt and preview
    await ctx.db.patch(args.chatId, {
      lastQueryAt: now,
      lastQueryPreview: args.content.slice(0, 100),
    });
  },
});

// Delete a chat and all its messages
export const deleteChat = mutation({
  args: {
    chatId: v.id("searchChats"),
  },
  handler: async (ctx, args) => {
    // Delete all messages in this chat
    const messages = await ctx.db
      .query("searchMessages")
      .withIndex("by_chat", (q) => q.eq("chatId", args.chatId))
      .collect();

    for (const message of messages) {
      await ctx.db.delete(message._id);
    }

    // Delete the chat itself
    await ctx.db.delete(args.chatId);
  },
});
