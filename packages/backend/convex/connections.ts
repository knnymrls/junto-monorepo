import { v } from "convex/values";
import { query, mutation, internalQuery } from "./_generated/server";
import { internal } from "./_generated/api";
import { Id } from "./_generated/dataModel";

// Create connection between two users (instant mutual connection for MVP)
export const connect = mutation({
  args: {
    requesterId: v.id("users"),
    accepterId: v.id("users"),
  },
  handler: async (ctx, args) => {
    // Check if connection already exists (in either direction)
    const existing = await ctx.db
      .query("connections")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.requesterId))
      .filter((q) => q.eq(q.field("accepterId"), args.accepterId))
      .first();

    if (existing) {
      return existing._id;
    }

    // Also check reverse
    const existingReverse = await ctx.db
      .query("connections")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.accepterId))
      .filter((q) => q.eq(q.field("accepterId"), args.requesterId))
      .first();

    if (existingReverse) {
      return existingReverse._id;
    }

    const now = Date.now();

    // Create instant mutual connection (MVP simplicity)
    return await ctx.db.insert("connections", {
      requesterId: args.requesterId,
      accepterId: args.accepterId,
      status: "connected",
      connectedAt: now,
      createdAt: now,
    });
  },
});

// Get all connections for a user
export const listForUser = query({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    // Get connections where user is requester
    const asRequester = await ctx.db
      .query("connections")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.userId))
      .filter((q) => q.eq(q.field("status"), "connected"))
      .collect();

    // Get connections where user is accepter
    const asAccepter = await ctx.db
      .query("connections")
      .withIndex("by_accepter", (q) => q.eq("accepterId", args.userId))
      .filter((q) => q.eq(q.field("status"), "connected"))
      .collect();

    // Combine and get unique connection IDs
    const allConnections = [...asRequester, ...asAccepter];

    // Get the other user's ID for each connection
    const connectedUserIds = allConnections.map((conn) =>
      conn.requesterId === args.userId ? conn.accepterId : conn.requesterId
    );

    // Fetch the connected users
    const users = await Promise.all(
      connectedUserIds.map((id) => ctx.db.get(id))
    );

    return users.filter(Boolean);
  },
});

// List all connections for a user (raw data, for actions)
export const listAll = query({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    const asRequester = await ctx.db
      .query("connections")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.userId))
      .collect();

    const asAccepter = await ctx.db
      .query("connections")
      .withIndex("by_accepter", (q) => q.eq("accepterId", args.userId))
      .collect();

    return [...asRequester, ...asAccepter];
  },
});

// Check if two users are connected
export const checkConnection = query({
  args: {
    userId1: v.id("users"),
    userId2: v.id("users"),
  },
  handler: async (ctx, args) => {
    // Check both directions
    const connection1 = await ctx.db
      .query("connections")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.userId1))
      .filter((q) =>
        q.and(
          q.eq(q.field("accepterId"), args.userId2),
          q.eq(q.field("status"), "connected")
        )
      )
      .first();

    if (connection1) return true;

    const connection2 = await ctx.db
      .query("connections")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.userId2))
      .filter((q) =>
        q.and(
          q.eq(q.field("accepterId"), args.userId1),
          q.eq(q.field("status"), "connected")
        )
      )
      .first();

    return !!connection2;
  },
});

// Get connection status between two users
export const getConnectionStatus = query({
  args: {
    fromUserId: v.id("users"),
    toUserId: v.id("users"),
  },
  handler: async (ctx, args) => {
    // Check if already connected (either direction)
    const connected1 = await ctx.db
      .query("connections")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.fromUserId))
      .filter((q) =>
        q.and(
          q.eq(q.field("accepterId"), args.toUserId),
          q.eq(q.field("status"), "connected")
        )
      )
      .first();
    if (connected1) return "connected";

    const connected2 = await ctx.db
      .query("connections")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.toUserId))
      .filter((q) =>
        q.and(
          q.eq(q.field("accepterId"), args.fromUserId),
          q.eq(q.field("status"), "connected")
        )
      )
      .first();
    if (connected2) return "connected";

    // Check if I sent a pending request
    const pending1 = await ctx.db
      .query("connections")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.fromUserId))
      .filter((q) =>
        q.and(
          q.eq(q.field("accepterId"), args.toUserId),
          q.eq(q.field("status"), "pending")
        )
      )
      .first();
    if (pending1) return "pending_sent";

    // Check if they sent me a pending request
    const pending2 = await ctx.db
      .query("connections")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.toUserId))
      .filter((q) =>
        q.and(
          q.eq(q.field("accepterId"), args.fromUserId),
          q.eq(q.field("status"), "pending")
        )
      )
      .first();
    if (pending2) return "pending_received";

    return "none";
  },
});

// Send a connection request (creates pending connection)
export const sendRequest = mutation({
  args: {
    requesterId: v.id("users"),
    accepterId: v.id("users"),
  },
  handler: async (ctx, args) => {
    // Check if connection already exists (in either direction)
    const existing = await ctx.db
      .query("connections")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.requesterId))
      .filter((q) => q.eq(q.field("accepterId"), args.accepterId))
      .first();

    if (existing) {
      return existing._id;
    }

    const existingReverse = await ctx.db
      .query("connections")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.accepterId))
      .filter((q) => q.eq(q.field("accepterId"), args.requesterId))
      .first();

    if (existingReverse) {
      // They already sent us a request - auto-accept!
      if (existingReverse.status === "pending") {
        await ctx.db.patch(existingReverse._id, {
          status: "connected",
          connectedAt: Date.now(),
        });

        // Notify the original requester that their request was accepted
        const accepter = await ctx.db.get(args.requesterId);
        const accepterName = accepter?.name || "Someone";
        await ctx.scheduler.runAfter(0, internal.notifications.notifyUser, {
          recipientId: args.accepterId,
          senderId: args.requesterId,
          type: "connection_accepted",
          title: `${accepterName} accepted your connection request`,
          data: {
            connectionId: existingReverse._id,
          },
        });
      }
      return existingReverse._id;
    }

    const now = Date.now();

    // Create pending connection request
    const connectionId = await ctx.db.insert("connections", {
      requesterId: args.requesterId,
      accepterId: args.accepterId,
      status: "pending",
      createdAt: now,
    });

    // Notify the recipient about the connection request
    const requester = await ctx.db.get(args.requesterId);
    const requesterName = requester?.name || "Someone";
    await ctx.scheduler.runAfter(0, internal.notifications.notifyUser, {
      recipientId: args.accepterId,
      senderId: args.requesterId,
      type: "connection_request",
      title: `${requesterName} wants to connect with you`,
      data: {
        connectionId: connectionId,
      },
    });

    return connectionId;
  },
});

// Accept a connection request
export const acceptRequest = mutation({
  args: {
    connectionId: v.id("connections"),
  },
  handler: async (ctx, args) => {
    const connection = await ctx.db.get(args.connectionId);
    if (!connection) {
      throw new Error("Connection not found");
    }

    if (connection.status !== "pending") {
      return connection._id;
    }

    await ctx.db.patch(args.connectionId, {
      status: "connected",
      connectedAt: Date.now(),
    });

    // Notify the requester that their connection was accepted
    const accepter = await ctx.db.get(connection.accepterId);
    const accepterName = accepter?.name || "Someone";
    await ctx.scheduler.runAfter(0, internal.notifications.notifyUser, {
      recipientId: connection.requesterId,
      senderId: connection.accepterId,
      type: "connection_accepted",
      title: `${accepterName} accepted your connection request`,
      data: {
        connectionId: args.connectionId,
      },
    });

    return args.connectionId;
  },
});

// Accept a connection request by user IDs (finds the pending connection)
export const acceptRequestByUsers = mutation({
  args: {
    currentUserId: v.id("users"),
    otherUserId: v.id("users"),
  },
  handler: async (ctx, args) => {
    // The other user sent the request, so they are the requester
    const connection = await ctx.db
      .query("connections")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.otherUserId))
      .filter((q: any) =>
        q.and(
          q.eq(q.field("accepterId"), args.currentUserId),
          q.eq(q.field("status"), "pending")
        )
      )
      .first();

    if (!connection) {
      throw new Error("No pending request found");
    }

    await ctx.db.patch(connection._id, {
      status: "connected",
      connectedAt: Date.now(),
    });

    const accepter = await ctx.db.get(args.currentUserId);
    const accepterName = accepter?.name || "Someone";
    await ctx.scheduler.runAfter(0, internal.notifications.notifyUser, {
      recipientId: args.otherUserId,
      senderId: args.currentUserId,
      type: "connection_accepted",
      title: `${accepterName} accepted your connection request`,
      data: {
        connectionId: connection._id,
      },
    });

    return connection._id;
  },
});

// Reject (delete) a connection request
export const rejectRequest = mutation({
  args: {
    connectionId: v.id("connections"),
  },
  handler: async (ctx, args) => {
    const connection = await ctx.db.get(args.connectionId);
    if (!connection) {
      throw new Error("Connection not found");
    }

    if (connection.status !== "pending") {
      return connection._id;
    }

    await ctx.db.delete(args.connectionId);
    return args.connectionId;
  },
});

// Remove an existing connection between two users
export const removeConnection = mutation({
  args: {
    userId1: v.id("users"),
    userId2: v.id("users"),
  },
  handler: async (ctx, args) => {
    // Check both directions
    const conn1 = await ctx.db
      .query("connections")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.userId1))
      .filter((q) => q.eq(q.field("accepterId"), args.userId2))
      .first();

    if (conn1) {
      await ctx.db.delete(conn1._id);
      return conn1._id;
    }

    const conn2 = await ctx.db
      .query("connections")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.userId2))
      .filter((q) => q.eq(q.field("accepterId"), args.userId1))
      .first();

    if (conn2) {
      await ctx.db.delete(conn2._id);
      return conn2._id;
    }

    throw new Error("Connection not found");
  },
});

// Withdraw a pending connection request I sent (by user IDs)
export const withdrawRequest = mutation({
  args: {
    requesterId: v.id("users"),
    accepterId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const pending = await ctx.db
      .query("connections")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.requesterId))
      .filter((q) =>
        q.and(
          q.eq(q.field("accepterId"), args.accepterId),
          q.eq(q.field("status"), "pending")
        )
      )
      .first();

    if (!pending) {
      throw new Error("No pending request found");
    }

    await ctx.db.delete(pending._id);
    return pending._id;
  },
});

// Get pending connection requests for a user (requests they received)
export const listPendingRequests = query({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    const pending = await ctx.db
      .query("connections")
      .withIndex("by_accepter", (q) => q.eq("accepterId", args.userId))
      .filter((q) => q.eq(q.field("status"), "pending"))
      .collect();

    // Get requester details
    const requests = await Promise.all(
      pending.map(async (conn) => {
        const requester = await ctx.db.get(conn.requesterId);
        return {
          connectionId: conn._id,
          requester,
          createdAt: conn.createdAt,
        };
      })
    );

    return requests.filter((r) => r.requester !== null);
  },
});

// Get IDs of users I've sent pending requests to
export const listPendingSentIds = query({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    const pending = await ctx.db
      .query("connections")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.userId))
      .filter((q) => q.eq(q.field("status"), "pending"))
      .collect();

    return pending.map((conn) => conn.accepterId);
  },
});

// Internal: Get mutual connections between two users
export const internalGetMutualConnections = internalQuery({
  args: {
    userIdA: v.id("users"),
    userIdB: v.id("users"),
  },
  handler: async (ctx, args) => {
    // Helper to get all connected user IDs for a given user
    async function getConnectedIds(userId: typeof args.userIdA) {
      const asRequester = await ctx.db
        .query("connections")
        .withIndex("by_requester", (q) => q.eq("requesterId", userId))
        .filter((q) => q.eq(q.field("status"), "connected"))
        .collect();

      const asAccepter = await ctx.db
        .query("connections")
        .withIndex("by_accepter", (q) => q.eq("accepterId", userId))
        .filter((q) => q.eq(q.field("status"), "connected"))
        .collect();

      return new Set([
        ...asRequester.map((c) => c.accepterId as string),
        ...asAccepter.map((c) => c.requesterId as string),
      ]);
    }

    const [connectionsA, connectionsB] = await Promise.all([
      getConnectedIds(args.userIdA),
      getConnectedIds(args.userIdB),
    ]);

    // Intersect
    const mutualIds: string[] = [];
    for (const id of connectionsA) {
      if (connectionsB.has(id)) {
        mutualIds.push(id);
      }
    }

    // Fetch first 2 mutual connection names
    const names: string[] = [];
    for (const id of mutualIds.slice(0, 2)) {
      const user = await ctx.db.get(id as Id<"users">);
      if (user) {
        names.push(user.name);
      }
    }

    // Check direct connection status between A and B
    let connectionStatus = "none";

    const conn1 = await ctx.db
      .query("connections")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.userIdA))
      .filter((q) => q.eq(q.field("accepterId"), args.userIdB))
      .first();

    if (conn1) {
      connectionStatus = conn1.status === "connected" ? "connected" : "pending_sent";
    } else {
      const conn2 = await ctx.db
        .query("connections")
        .withIndex("by_requester", (q) => q.eq("requesterId", args.userIdB))
        .filter((q) => q.eq(q.field("accepterId"), args.userIdA))
        .first();

      if (conn2) {
        connectionStatus = conn2.status === "connected" ? "connected" : "pending_received";
      }
    }

    return {
      count: mutualIds.length,
      names,
      connectionStatus,
    };
  },
});
