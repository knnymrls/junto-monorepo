import { v } from "convex/values";
import { query } from "./_generated/server";

// === Major category → suggested skill/interest categories mapping ===
// When a student picks a major, we surface relevant skills/interests first
const MAJOR_TO_SKILL_CATEGORIES: Record<string, string[]> = {
  "Computing & IT": ["Development", "Data & Analytics", "Design"],
  "Engineering": ["Engineering", "Development", "Data & Analytics"],
  "Business": ["Business", "Marketing & Content", "Data & Analytics", "Communication & Leadership"],
  "Sciences": ["Sciences & Research", "Data & Analytics", "Health & Wellness"],
  "Health & Medicine": ["Health & Wellness", "Sciences & Research", "Communication & Leadership"],
  "Arts & Design": ["Design", "Creative Arts", "Marketing & Content"],
  "Communications & Media": ["Marketing & Content", "Creative Arts", "Communication & Leadership"],
  "Education": ["Communication & Leadership", "Creative Arts"],
  "Social Sciences": ["Communication & Leadership", "Legal & Policy", "Data & Analytics"],
  "Humanities & Languages": ["Communication & Leadership", "Creative Arts"],
  "Law & Public Safety": ["Legal & Policy", "Communication & Leadership"],
  "Agriculture & Environment": ["Sciences & Research", "Trades & Applied"],
  "Trades & Applied": ["Trades & Applied", "Engineering"],
  "Other": [],
};

const MAJOR_TO_INTEREST_CATEGORIES: Record<string, string[]> = {
  "Computing & IT": ["Technology", "Entrepreneurship & Business", "Design & Aesthetics"],
  "Engineering": ["Technology", "Science & Discovery", "Environment & Sustainability"],
  "Business": ["Entrepreneurship & Business", "Technology", "Lifestyle & Culture"],
  "Sciences": ["Science & Discovery", "Health & Wellness", "Environment & Sustainability"],
  "Health & Medicine": ["Health & Wellness", "Science & Discovery", "Social Impact & Justice"],
  "Arts & Design": ["Design & Aesthetics", "Arts & Culture", "Media & Entertainment"],
  "Communications & Media": ["Media & Entertainment", "Arts & Culture", "Technology"],
  "Education": ["Education & Growth", "Social Impact & Justice"],
  "Social Sciences": ["Social Impact & Justice", "Education & Growth", "Science & Discovery"],
  "Humanities & Languages": ["Arts & Culture", "Education & Growth", "Social Impact & Justice"],
  "Law & Public Safety": ["Social Impact & Justice", "Education & Growth"],
  "Agriculture & Environment": ["Environment & Sustainability", "Science & Discovery"],
  "Trades & Applied": ["Technology", "Lifestyle & Culture"],
  "Other": [],
};

// 1. Search universities — typeahead with logo + city/state
export const searchUniversities = query({
  args: {
    query: v.string(),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    if (!args.query.trim()) return [];

    const results = await ctx.db
      .query("universities")
      .withSearchIndex("search_name", (q) => q.search("name", args.query))
      .take(args.limit ?? 10);

    return await Promise.all(
      results.map(async (u) => ({
        _id: u._id,
        name: u.name,
        shortName: u.shortName,
        city: u.city,
        state: u.state,
        logoUrl: u.logoStorageId
          ? await ctx.storage.getUrl(u.logoStorageId as any)
          : u.logoUrl ?? null,
      }))
    );
  },
});

// 2. Get majors for a university — grouped by credential level
export const getMajorsForUniversity = query({
  args: { universityId: v.id("universities") },
  handler: async (ctx, args) => {
    // Get all university-major links for this university
    const links = await ctx.db
      .query("universityMajors")
      .withIndex("by_university", (q) => q.eq("universityId", args.universityId))
      .collect();

    // Fetch the actual major records
    const majorsWithLevel = await Promise.all(
      links.map(async (link) => {
        const major = await ctx.db.get(link.majorId);
        if (!major) return null;
        return {
          _id: major._id,
          name: major.name,
          category: major.category,
          cipCode: major.cipCode,
          credentialLevel: link.credentialLevel,
          credentialTitle: link.credentialTitle,
        };
      })
    );

    // Filter nulls and group by credential level
    const valid = majorsWithLevel.filter(Boolean) as NonNullable<typeof majorsWithLevel[number]>[];

    // Sort within each group alphabetically
    valid.sort((a, b) => a.name.localeCompare(b.name));

    // Group by credential level
    const grouped: Record<string, typeof valid> = {};
    for (const m of valid) {
      const key = m.credentialTitle;
      if (!grouped[key]) grouped[key] = [];
      grouped[key].push(m);
    }

    return grouped;
  },
});

// 3. Get programs for a university (Raikes School, Catalyst, etc.)
export const getProgramsForUniversity = query({
  args: { universityId: v.id("universities") },
  handler: async (ctx, args) => {
    const university = await ctx.db.get(args.universityId);
    if (!university) return [];
    return university.programs ?? [];
  },
});

// 4. Get skills by category — with major-based suggestions first
export const getSkills = query({
  args: {
    majorCategory: v.optional(v.string()), // e.g. "Computing & IT" — used to prioritize categories
  },
  handler: async (ctx, args) => {
    const allSkills = await ctx.db.query("skills").collect();

    // Group by category
    const grouped: Record<string, { _id: string; name: string; category: string }[]> = {};
    for (const skill of allSkills) {
      if (!grouped[skill.category]) grouped[skill.category] = [];
      grouped[skill.category].push({
        _id: skill._id,
        name: skill.name,
        category: skill.category,
      });
    }

    // Sort each category alphabetically
    for (const cat of Object.keys(grouped)) {
      grouped[cat].sort((a, b) => a.name.localeCompare(b.name));
    }

    // If major category provided, return suggested categories first
    const suggestedCategories = args.majorCategory
      ? MAJOR_TO_SKILL_CATEGORIES[args.majorCategory] ?? []
      : [];

    const suggested = suggestedCategories.flatMap((cat) => grouped[cat] ?? []);
    const suggestedCatSet = new Set(suggestedCategories);

    return {
      suggested, // Flat list of skills from relevant categories (show these first)
      byCategory: grouped, // Full grouped list for browsing
    };
  },
});

// 5. Get interests by category — with major-based suggestions first
export const getInterests = query({
  args: {
    majorCategory: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const allInterests = await ctx.db.query("interests").collect();

    // Group by category
    const grouped: Record<string, { _id: string; name: string; category: string }[]> = {};
    for (const interest of allInterests) {
      if (!grouped[interest.category]) grouped[interest.category] = [];
      grouped[interest.category].push({
        _id: interest._id,
        name: interest.name,
        category: interest.category,
      });
    }

    // Sort each category alphabetically
    for (const cat of Object.keys(grouped)) {
      grouped[cat].sort((a, b) => a.name.localeCompare(b.name));
    }

    // If major category provided, return suggested categories first
    const suggestedCategories = args.majorCategory
      ? MAJOR_TO_INTEREST_CATEGORIES[args.majorCategory] ?? []
      : [];

    const suggested = suggestedCategories.flatMap((cat) => grouped[cat] ?? []);

    return {
      suggested,
      byCategory: grouped,
    };
  },
});

// 6. Get logo URL for a university (resolves storage ID to servable URL)
export const getUniversityLogo = query({
  args: { universityId: v.id("universities") },
  handler: async (ctx, args) => {
    const university = await ctx.db.get(args.universityId);
    if (!university) return null;

    if (university.logoStorageId) {
      return await ctx.storage.getUrl(university.logoStorageId as any);
    }
    return university.logoUrl ?? null;
  },
});

// 7. Search skills by name (for the search bar in the picker)
export const searchSkills = query({
  args: { query: v.string() },
  handler: async (ctx, args) => {
    if (!args.query.trim()) return [];
    return await ctx.db
      .query("skills")
      .withSearchIndex("search_name", (q) => q.search("name", args.query))
      .take(10);
  },
});

// 8. Search interests by name (for the search bar in the picker)
export const searchInterests = query({
  args: { query: v.string() },
  handler: async (ctx, args) => {
    if (!args.query.trim()) return [];
    return await ctx.db
      .query("interests")
      .withSearchIndex("search_name", (q) => q.search("name", args.query))
      .take(10);
  },
});

// 9. Search majors by name (for the search bar in the major picker)
export const searchMajors = query({
  args: {
    query: v.string(),
    universityId: v.optional(v.id("universities")),
  },
  handler: async (ctx, args) => {
    if (!args.query.trim()) return [];

    const results = await ctx.db
      .query("majors")
      .withSearchIndex("search_name", (q) => q.search("name", args.query))
      .take(20);

    // If universityId provided, filter to only majors this university offers
    if (args.universityId) {
      const filtered = await Promise.all(
        results.map(async (major) => {
          const link = await ctx.db
            .query("universityMajors")
            .withIndex("by_university_major", (q) =>
              q.eq("universityId", args.universityId!).eq("majorId", major._id)
            )
            .first();
          if (!link) return null;
          return {
            ...major,
            credentialLevel: link.credentialLevel,
            credentialTitle: link.credentialTitle,
          };
        })
      );
      return filtered.filter(Boolean);
    }

    return results;
  },
});

// 10. Suggested connections — score users at the same university
export const getSuggestedConnections = query({
  args: {
    universityId: v.id("universities"),
    excludeClerkId: v.string(),
    skills: v.optional(v.array(v.string())),
    interests: v.optional(v.array(v.string())),
    programs: v.optional(v.array(v.string())),
    graduationSemester: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    // Get all users at the same university (excluding current user)
    const users = await ctx.db
      .query("users")
      .withIndex("by_university", (q) => q.eq("universityId", args.universityId))
      .collect();

    const candidates = users.filter((u) => u.clerkId !== args.excludeClerkId && u.isOnboarded);

    const mySkills = new Set(args.skills ?? []);
    const myInterests = new Set(args.interests ?? []);
    const myPrograms = new Set(args.programs ?? []);

    // Score each candidate
    const scored = candidates.map((user) => {
      let score = 0;

      // +3 for each shared program
      for (const p of user.programs ?? []) {
        if (myPrograms.has(p)) score += 3;
      }

      // +2 for each shared skill
      for (const s of user.skills ?? []) {
        if (mySkills.has(s as string)) score += 2;
      }

      // +1 for each shared interest
      for (const i of user.interests ?? []) {
        if (myInterests.has(i as string)) score += 1;
      }

      // +1 for same grad semester
      if (args.graduationSemester && user.graduationSemester === args.graduationSemester) {
        score += 1;
      }

      return { user, score };
    });

    // Sort by score desc, take top 4
    scored.sort((a, b) => b.score - a.score);
    const top = scored.slice(0, 4);

    // Resolve avatar URLs
    return Promise.all(
      top.map(async ({ user, score }) => {
        let avatarUrl = user.avatarUrl;
        if (avatarUrl && !avatarUrl.startsWith("http")) {
          avatarUrl = await ctx.storage.getUrl(avatarUrl as any) ?? undefined;
        }
        return {
          _id: user._id,
          name: user.name,
          headline: user.headline ?? "",
          avatarUrl: avatarUrl ?? null,
          lookingFor: user.lookingFor ?? "",
          score,
        };
      })
    );
  },
});
