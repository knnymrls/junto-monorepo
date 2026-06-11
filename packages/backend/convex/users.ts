import { v } from "convex/values";
import { query, mutation, internalQuery, internalMutation, action } from "./_generated/server";
import { internal } from "./_generated/api";
import { Doc } from "./_generated/dataModel";

// Helper to strip embeddings from user (reduces bandwidth significantly)
function stripEmbeddings(user: Doc<"users">) {
  const { profileEmbedding, needsEmbedding, ...rest } = user;
  return rest;
}

// One-time repair: onboarding used to store raw storage IDs in avatarUrl,
// which render nowhere. Resolve them to real serving URLs.
// Run with: npx convex run users:backfillAvatarUrls
export const backfillAvatarUrls = internalMutation({
  args: {},
  handler: async (ctx) => {
    const users = await ctx.db.query("users").collect();
    let patched = 0;
    for (const user of users) {
      const url = user.avatarUrl;
      if (url && !url.startsWith("http")) {
        const resolved = await ctx.storage.getUrl(url as any);
        if (resolved) {
          await ctx.db.patch(user._id, { avatarUrl: resolved, updatedAt: Date.now() });
          patched++;
        }
      }
    }
    return patched;
  },
});

// Get all users (with optional filters)
export const list = query({
  args: {
    universityId: v.optional(v.id("universities")),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    let users;

    if (args.universityId) {
      users = await ctx.db
        .query("users")
        .withIndex("by_university", (q) => q.eq("universityId", args.universityId))
        .collect();
    } else {
      users = await ctx.db.query("users").collect();
    }

    // Sort by createdAt descending
    users.sort((a, b) => b.createdAt - a.createdAt);

    // Apply limit if specified
    const limited = args.limit ? users.slice(0, args.limit) : users;

    // Strip embeddings before returning
    return limited.map(stripEmbeddings);
  },
});

// Get single user by ID
export const get = query({
  args: { id: v.id("users") },
  handler: async (ctx, args) => {
    const user = await ctx.db.get(args.id);
    return user ? stripEmbeddings(user) : null;
  },
});

// Get user by Clerk ID (for current user)
export const getByClerkId = query({
  args: { clerkId: v.string() },
  handler: async (ctx, args) => {
    const user = await ctx.db
      .query("users")
      .withIndex("by_clerk_id", (q) => q.eq("clerkId", args.clerkId))
      .first();
    return user ? stripEmbeddings(user) : null;
  },
});

// Get user by name (for mentions)
export const getByName = query({
  args: { name: v.string() },
  handler: async (ctx, args) => {
    const users = await ctx.db.query("users").collect();
    const user = users.find(
      (m) => m.name.toLowerCase() === args.name.toLowerCase()
    );
    return user ? stripEmbeddings(user) : null;
  },
});

// Internal: Search users by name using text search index
export const internalSearchByName = internalQuery({
  args: { query: v.string(), limit: v.optional(v.number()) },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("users")
      .withSearchIndex("search_name", (q) => q.search("name", args.query))
      .take(args.limit ?? 10);
  },
});

// Public: Search users by name (lightweight, for autocomplete)
export const searchByName = action({
  args: {
    query: v.string(),
    limit: v.optional(v.number()),
    currentUserId: v.optional(v.string()),
  },
  handler: async (ctx, args): Promise<{ _id: string; name: string; headline: string | null; avatarUrl: string | null }[]> => {
    const results: Doc<"users">[] = await ctx.runQuery(internal.users.internalSearchByName, {
      query: args.query,
      limit: args.limit ?? 8,
    });

    return results
      .filter((m: Doc<"users">) => !args.currentUserId || (m._id as string) !== args.currentUserId)
      .map((m: Doc<"users">) => ({
        _id: m._id as string,
        name: m.name,
        headline: m.headline ?? null,
        avatarUrl: m.avatarUrl ?? null,
      }));
  },
});

// Internal: Get user with embedding (for vector search actions)
export const getWithEmbedding = internalQuery({
  args: { id: v.id("users") },
  handler: async (ctx, args) => {
    return await ctx.db.get(args.id);
  },
});

// Create or update user profile
export const upsert = mutation({
  args: {
    clerkId: v.string(),
    email: v.optional(v.string()),
    phone: v.optional(v.string()),
    name: v.string(),
    headline: v.optional(v.string()),
    avatarUrl: v.optional(v.string()),
    currentProject: v.optional(v.string()),
    lookingFor: v.optional(v.string()),
    canHelpWith: v.optional(v.string()),
    skills: v.optional(v.array(v.id("skills"))),
    interests: v.optional(v.array(v.id("interests"))),
    majors: v.optional(v.array(v.object({
      majorId: v.id("majors"),
      credentialLevel: v.number(),
    }))),
    minors: v.optional(v.array(v.id("majors"))),
    graduationSemester: v.optional(v.string()),
    programs: v.optional(v.array(v.string())),
    socialLinks: v.optional(
      v.object({
        linkedin: v.optional(v.string()),
        instagram: v.optional(v.string()),
        twitter: v.optional(v.string()),
        github: v.optional(v.string()),
        website: v.optional(v.string()),
      })
    ),
    role: v.optional(v.string()),
    platformRole: v.optional(v.string()),
    universityId: v.optional(v.id("universities")),
  },
  handler: async (ctx, args) => {
    const existing = await ctx.db
      .query("users")
      .withIndex("by_clerk_id", (q) => q.eq("clerkId", args.clerkId))
      .first();

    const now = Date.now();

    if (existing) {
      // Update existing user
      await ctx.db.patch(existing._id, {
        ...args,
        isOnboarded: true,
        updatedAt: now,
      });

      // Schedule embedding generation (runs async after mutation)
      await ctx.scheduler.runAfter(0, internal.embeddings.generateEmbedding, {
        userId: existing._id,
      });

      return existing._id;
    } else {
      // Create new user
      const userId = await ctx.db.insert("users", {
        ...args,
        isOnboarded: true,
        createdAt: now,
        updatedAt: now,
      });

      // Schedule embedding generation for new user
      await ctx.scheduler.runAfter(0, internal.embeddings.generateEmbedding, {
        userId,
      });

      return userId;
    }
  },
});

// Profile display context — resolves the reference IDs hanging off a user
// (university, majors, skills) into display names so the profile page never
// renders raw Convex IDs.
export const getProfileContext = query({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    const user = await ctx.db.get(args.userId);
    if (!user) return null;

    let university = null;
    if (user.universityId) {
      const u = await ctx.db.get(user.universityId);
      if (u) {
        university = {
          name: u.name,
          shortName: u.shortName ?? null,
          logoUrl: u.logoStorageId
            ? await ctx.storage.getUrl(u.logoStorageId as any)
            : u.logoUrl ?? null,
        };
      }
    }

    const majorNames: string[] = [];
    for (const m of user.majors ?? []) {
      const major = await ctx.db.get(m.majorId);
      if (major) majorNames.push(major.name);
    }

    const skillNames: string[] = [];
    for (const skillId of user.skills ?? []) {
      const skill = await ctx.db.get(skillId);
      if (skill) skillNames.push(skill.name);
    }

    return { university, majorNames, skillNames };
  },
});

// Search users by text (basic text search)
export const search = query({
  args: {
    query: v.string(),
    universityId: v.optional(v.id("universities")),
  },
  handler: async (ctx, args) => {
    let searchQuery = ctx.db
      .query("users")
      .withSearchIndex("search_headline", (q) => {
        let search = q.search("headline", args.query);
        if (args.universityId) {
          search = search.eq("universityId", args.universityId);
        }
        return search;
      });

    return await searchQuery.collect();
  },
});

// Fast name search for masonry cards (typing phase — no embedding, no action overhead)
export const searchForCards = query({
  args: {
    query: v.string(),
    currentUserId: v.optional(v.id("users")),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const results = await ctx.db
      .query("users")
      .withSearchIndex("search_name", (q) => q.search("name", args.query))
      .take(args.limit ?? 8);

    return results
      .filter((m) => !args.currentUserId || m._id !== args.currentUserId)
      .map(stripEmbeddings);
  },
});

// Get users with their embedding status (for admin)
export const listWithEmbeddingStatus = query({
  args: {},
  handler: async (ctx) => {
    const users = await ctx.db.query("users").collect();
    return users.map((m) => ({
      _id: m._id,
      name: m.name,
      headline: m.headline,
      hasProfileEmbedding: !!m.profileEmbedding && m.profileEmbedding.length > 0,
      hasNeedsEmbedding: !!m.needsEmbedding && m.needsEmbedding.length > 0,
      lookingFor: m.lookingFor,
      canHelpWith: m.canHelpWith,
    }));
  },
});
