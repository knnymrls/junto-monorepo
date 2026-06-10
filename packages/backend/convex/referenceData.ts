import { v } from "convex/values";
import { internalMutation, internalQuery } from "./_generated/server";

// Insert a batch of skills, skipping duplicates by name
export const insertSkills = internalMutation({
  args: {
    skills: v.array(v.object({ name: v.string(), category: v.string() })),
  },
  handler: async (ctx, args) => {
    let inserted = 0;
    for (const skill of args.skills) {
      const existing = await ctx.db
        .query("skills")
        .withSearchIndex("search_name", (q) => q.search("name", skill.name))
        .first();
      if (!existing || existing.name !== skill.name) {
        await ctx.db.insert("skills", skill);
        inserted++;
      }
    }
    return inserted;
  },
});

// ============================================================
// JUNTO SKILL CATALOG — the 12 maker categories and the starter
// skills under each. Categories match the client SkillCategory enum
// exactly, so a user's skillCategories = unique(category per skill).
// Curated, not exhaustive — add skills, keep each in one category.
// ============================================================
export const SKILL_CATALOG: { name: string; category: string }[] = [
  // Software
  ...["Web Development", "iOS Development", "Android Development", "Backend & APIs", "Full-Stack", "DevOps & Cloud", "Game Development"].map((name) => ({ name, category: "Software" })),
  // AI
  ...["Machine Learning", "Generative AI", "LLM Apps", "Computer Vision", "NLP", "AI Agents", "Prompt Engineering"].map((name) => ({ name, category: "AI" })),
  // Design
  ...["UX/UI Design", "Product Design", "Brand Identity", "Graphic Design", "Industrial Design", "Motion Design", "Wireframing"].map((name) => ({ name, category: "Design" })),
  // Hardware
  ...["Mechanical Engineering", "Electrical Engineering", "Robotics", "CAD & 3D Modeling", "Embedded Systems", "Prototyping", "Manufacturing"].map((name) => ({ name, category: "Hardware" })),
  // Data
  ...["Data Science", "Data Analytics", "SQL & Databases", "Data Visualization", "Statistics", "A/B Testing"].map((name) => ({ name, category: "Data" })),
  // Business
  ...["Business Strategy", "Operations", "Product Management", "Consulting", "Supply Chain", "Legal & IP"].map((name) => ({ name, category: "Business" })),
  // Finance
  ...["Accounting", "Fundraising", "Investing", "Financial Modeling", "Fintech", "Venture Capital"].map((name) => ({ name, category: "Finance" })),
  // Marketing
  ...["Growth Marketing", "Social Media", "SEO & SEM", "Content Marketing", "Sales", "Partnerships"].map((name) => ({ name, category: "Marketing" })),
  // Content
  ...["Video Production", "Photography", "Copywriting", "Music & Audio", "Podcasting", "Video Editing", "Creative Writing"].map((name) => ({ name, category: "Content" })),
  // Science
  ...["Biology", "Chemistry", "Physics", "Lab Research", "Environmental Science", "Agriculture"].map((name) => ({ name, category: "Science" })),
  // Health
  ...["Pre-Med & Clinical", "Public Health", "Nutrition & Wellness", "Biotech", "Nursing", "Mental Health"].map((name) => ({ name, category: "Health" })),
  // Impact
  ...["Public Policy", "Nonprofit", "Sustainability", "Education", "Social Entrepreneurship", "Community Organizing"].map((name) => ({ name, category: "Impact" })),
  // Leadership
  ...["Public Speaking", "Team Leadership", "Project Management", "Event Organizing", "Mentorship", "Recruiting"].map((name) => ({ name, category: "Leadership" })),
];

// Seed the catalog (dedup by name) — safe to re-run.
export const seedSkillCatalog = internalMutation({
  args: {},
  handler: async (ctx) => {
    let inserted = 0;
    let recategorized = 0;
    for (const skill of SKILL_CATALOG) {
      const existing = await ctx.db
        .query("skills")
        .withSearchIndex("search_name", (q) => q.search("name", skill.name))
        .first();
      if (!existing || existing.name !== skill.name) {
        await ctx.db.insert("skills", skill);
        inserted++;
      } else if (existing.category !== skill.category) {
        // Re-point an existing skill onto the new maker category.
        await ctx.db.patch(existing._id, { category: skill.category });
        recategorized++;
      }
    }
    return { inserted, recategorized, total: SKILL_CATALOG.length };
  },
});

// Insert a batch of interests, skipping duplicates by name
export const insertInterests = internalMutation({
  args: {
    interests: v.array(v.object({ name: v.string(), category: v.string() })),
  },
  handler: async (ctx, args) => {
    let inserted = 0;
    for (const interest of args.interests) {
      const existing = await ctx.db
        .query("interests")
        .withSearchIndex("search_name", (q) => q.search("name", interest.name))
        .first();
      if (!existing || existing.name !== interest.name) {
        await ctx.db.insert("interests", interest);
        inserted++;
      }
    }
    return inserted;
  },
});

// Insert a single university, return its ID
export const insertUniversity = internalMutation({
  args: {
    name: v.string(),
    shortName: v.optional(v.string()),
    domains: v.optional(v.array(v.string())),
    logoUrl: v.optional(v.string()),
    city: v.string(),
    state: v.string(),
    scorecardId: v.optional(v.number()),
    carnegieClassification: v.optional(v.number()),
    institutionLevel: v.optional(v.number()),
    isHbcu: v.optional(v.boolean()),
    isHsi: v.optional(v.boolean()),
    plan: v.string(),
    programs: v.optional(v.array(v.string())),
    isActive: v.boolean(),
  },
  handler: async (ctx, args) => {
    // Skip if university with same scorecardId already exists
    if (args.scorecardId) {
      const existing = await ctx.db
        .query("universities")
        .filter((q) => q.eq(q.field("scorecardId"), args.scorecardId))
        .first();
      if (existing) return existing._id;
    }
    return await ctx.db.insert("universities", {
      ...args,
      createdAt: Date.now(),
    });
  },
});

// Insert a batch of majors, return array of { cipCode, id }
export const insertMajors = internalMutation({
  args: {
    majors: v.array(
      v.object({
        name: v.string(),
        cipCode: v.string(),
        category: v.string(),
      })
    ),
  },
  handler: async (ctx, args) => {
    const results: { cipCode: string; id: string }[] = [];
    for (const major of args.majors) {
      // Check if this CIP code already exists
      const existing = await ctx.db
        .query("majors")
        .withIndex("by_cip_code", (q) => q.eq("cipCode", major.cipCode))
        .first();
      if (existing) {
        results.push({ cipCode: major.cipCode, id: existing._id });
      } else {
        const id = await ctx.db.insert("majors", major);
        results.push({ cipCode: major.cipCode, id });
      }
    }
    return results;
  },
});

// Merge duplicate majors: remap universityMajors links from old → new, then delete old
export const mergeDuplicateMajors = internalMutation({
  args: {
    merges: v.array(
      v.object({
        keepId: v.id("majors"),
        deleteId: v.id("majors"),
      })
    ),
  },
  handler: async (ctx, args) => {
    let remapped = 0;
    let deleted = 0;
    for (const { keepId, deleteId } of args.merges) {
      // Find all universityMajors pointing to the duplicate
      const links = await ctx.db
        .query("universityMajors")
        .withIndex("by_major", (q) => q.eq("majorId", deleteId))
        .collect();
      for (const link of links) {
        // Check if a link already exists for the same university + keepId + credentialLevel
        const existing = await ctx.db
          .query("universityMajors")
          .withIndex("by_university_major", (q) =>
            q.eq("universityId", link.universityId).eq("majorId", keepId)
          )
          .collect();
        const alreadyHasLevel = existing.some(
          (e) => e.credentialLevel === link.credentialLevel
        );
        if (alreadyHasLevel) {
          // Duplicate link — just delete it
          await ctx.db.delete(link._id);
        } else {
          // Remap to the kept major
          await ctx.db.patch(link._id, { majorId: keepId });
          remapped++;
        }
      }
      // Delete the duplicate major
      await ctx.db.delete(deleteId);
      deleted++;
    }
    return { remapped, deleted };
  },
});

// Insert a batch of university-major links
export const insertUniversityMajors = internalMutation({
  args: {
    links: v.array(
      v.object({
        universityId: v.id("universities"),
        majorId: v.id("majors"),
        credentialLevel: v.number(),
        credentialTitle: v.string(),
      })
    ),
  },
  handler: async (ctx, args) => {
    let count = 0;
    for (const link of args.links) {
      // Skip if this exact link already exists
      const existing = await ctx.db
        .query("universityMajors")
        .withIndex("by_university_major", (q) =>
          q.eq("universityId", link.universityId).eq("majorId", link.majorId)
        )
        .collect();
      const alreadyHasLevel = existing.some(
        (e) => e.credentialLevel === link.credentialLevel
      );
      if (!alreadyHasLevel) {
        await ctx.db.insert("universityMajors", link);
        count++;
      }
    }
    return count;
  },
});

// Generate an upload URL for file storage
export const generateUploadUrl = internalMutation({
  handler: async (ctx) => {
    return await ctx.storage.generateUploadUrl();
  },
});

// Save a logo storage ID on a university
export const saveLogoStorageId = internalMutation({
  args: {
    universityId: v.id("universities"),
    storageId: v.string(),
  },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.universityId, { logoStorageId: args.storageId });
  },
});

// List universities that have a logoUrl but no logoStorageId (need download)
export const listUniversitiesNeedingLogos = internalQuery({
  args: { limit: v.number(), cursor: v.optional(v.string()) },
  handler: async (ctx, args) => {
    const all = await ctx.db.query("universities").collect();
    const needsLogo = all.filter((u) => u.logoUrl && !u.logoStorageId);
    // Simple cursor: skip past the cursor ID
    let start = 0;
    if (args.cursor) {
      const idx = needsLogo.findIndex((u) => u._id === args.cursor);
      if (idx >= 0) start = idx + 1;
    }
    const batch = needsLogo.slice(start, start + args.limit);
    return {
      universities: batch.map((u) => ({ _id: u._id, logoUrl: u.logoUrl! })),
      total: needsLogo.length,
      hasMore: start + args.limit < needsLogo.length,
    };
  },
});
