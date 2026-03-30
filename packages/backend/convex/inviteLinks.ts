import { v } from "convex/values";
import { query, mutation, internalMutation } from "./_generated/server";

// Generate a random 8-char URL-safe code
function generateCode(): string {
  const chars = "abcdefghijklmnopqrstuvwxyz0123456789";
  let code = "";
  for (let i = 0; i < 8; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

// === CREATE ===

export const create = mutation({
  args: {
    universityId: v.id("universities"),
    program: v.optional(v.string()),
    role: v.optional(v.string()),
    createdBy: v.id("users"),
    label: v.optional(v.string()),
    maxUses: v.optional(v.number()),
    expiresAt: v.optional(v.number()),
    customCode: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    // Use custom code or auto-generate
    let code = args.customCode?.trim().toLowerCase().replace(/[^a-z0-9-]/g, "") || generateCode();

    // Ensure code is unique
    const existing = await ctx.db
      .query("inviteLinks")
      .withIndex("by_code", (q) => q.eq("code", code))
      .first();

    if (existing) {
      if (args.customCode) {
        throw new Error(`Invite code "${code}" is already in use`);
      }
      // Auto-generated collision — retry once
      code = generateCode();
      const retry = await ctx.db
        .query("inviteLinks")
        .withIndex("by_code", (q) => q.eq("code", code))
        .first();
      if (retry) {
        throw new Error("Code generation collision — please try again");
      }
    }

    const now = Date.now();
    const id = await ctx.db.insert("inviteLinks", {
      code,
      universityId: args.universityId,
      program: args.program,
      role: args.role,
      createdBy: args.createdBy,
      label: args.label,
      maxUses: args.maxUses,
      expiresAt: args.expiresAt,
      useCount: 0,
      isActive: true,
      createdAt: now,
    });

    return { id, code };
  },
});

// === GET BY CODE (public — no auth required) ===

export const getByCode = query({
  args: { code: v.string() },
  handler: async (ctx, args) => {
    const link = await ctx.db
      .query("inviteLinks")
      .withIndex("by_code", (q) => q.eq("code", args.code.toLowerCase()))
      .first();

    if (!link) return null;
    if (!link.isActive) return null;
    if (link.expiresAt && link.expiresAt < Date.now()) return null;
    if (link.maxUses && link.useCount >= link.maxUses) return null;

    // Resolve university details
    const university = await ctx.db.get(link.universityId);
    if (!university) return null;

    // Resolve logo URL
    let logoUrl = university.logoUrl ?? null;
    if (university.logoStorageId) {
      logoUrl = await ctx.storage.getUrl(university.logoStorageId as any) ?? logoUrl;
    }

    return {
      _id: link._id,
      code: link.code,
      universityId: link.universityId,
      universityName: university.name,
      universityShortName: university.shortName ?? null,
      universityCity: university.city,
      universityState: university.state,
      universityLogoUrl: logoUrl,
      program: link.program ?? null,
      role: link.role ?? null,
      label: link.label ?? null,
    };
  },
});

// === REDEEM ===

export const redeem = mutation({
  args: {
    code: v.string(),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const link = await ctx.db
      .query("inviteLinks")
      .withIndex("by_code", (q) => q.eq("code", args.code.toLowerCase()))
      .first();

    if (!link) throw new Error("Invalid invite code");
    if (!link.isActive) throw new Error("This invite link is no longer active");
    if (link.expiresAt && link.expiresAt < Date.now()) throw new Error("This invite link has expired");
    if (link.maxUses && link.useCount >= link.maxUses) throw new Error("This invite link has reached its maximum uses");

    // Check if user already redeemed this link
    const existingRedemption = await ctx.db
      .query("inviteRedemptions")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .collect();

    const alreadyRedeemed = existingRedemption.some((r) => r.inviteLinkId === link._id);
    if (alreadyRedeemed) return { alreadyRedeemed: true };

    // Record redemption
    await ctx.db.insert("inviteRedemptions", {
      inviteLinkId: link._id,
      userId: args.userId,
      redeemedAt: Date.now(),
    });

    // Increment use count
    await ctx.db.patch(link._id, {
      useCount: link.useCount + 1,
    });

    return { alreadyRedeemed: false };
  },
});

// === LIST (for admin/dashboard) ===

export const list = query({
  args: {
    universityId: v.optional(v.id("universities")),
  },
  handler: async (ctx, args) => {
    if (args.universityId) {
      return await ctx.db
        .query("inviteLinks")
        .withIndex("by_university", (q) => q.eq("universityId", args.universityId!))
        .collect();
    }
    return await ctx.db.query("inviteLinks").collect();
  },
});

// === DEACTIVATE ===

export const deactivate = mutation({
  args: { id: v.id("inviteLinks") },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.id, { isActive: false });
    return { success: true };
  },
});

// === INTERNAL: Create (for Convex dashboard / seed scripts) ===

export const internalCreate = internalMutation({
  args: {
    universityId: v.id("universities"),
    program: v.optional(v.string()),
    role: v.optional(v.string()),
    createdBy: v.id("users"),
    label: v.optional(v.string()),
    maxUses: v.optional(v.number()),
    expiresAt: v.optional(v.number()),
    customCode: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    let code = args.customCode?.trim().toLowerCase().replace(/[^a-z0-9-]/g, "") || generateCode();

    const existing = await ctx.db
      .query("inviteLinks")
      .withIndex("by_code", (q) => q.eq("code", code))
      .first();

    if (existing) {
      if (args.customCode) {
        throw new Error(`Invite code "${code}" is already in use`);
      }
      code = generateCode();
    }

    const id = await ctx.db.insert("inviteLinks", {
      code,
      universityId: args.universityId,
      program: args.program,
      role: args.role,
      createdBy: args.createdBy,
      label: args.label,
      maxUses: args.maxUses,
      expiresAt: args.expiresAt,
      useCount: 0,
      isActive: true,
      createdAt: Date.now(),
    });

    return { id, code };
  },
});
