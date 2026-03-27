import { v } from "convex/values";
import { mutation, query } from "./_generated/server";

// CIP code prefix → category mapping
const CIP_CATEGORIES: Record<string, string> = {
  "01": "Agriculture",
  "03": "Natural Resources",
  "04": "Architecture",
  "05": "Area Studies",
  "09": "Communication",
  "10": "Communications Tech",
  "11": "Computing & IT",
  "12": "Culinary & Personal Services",
  "13": "Education",
  "14": "Engineering",
  "15": "Engineering Tech",
  "16": "Foreign Languages",
  "19": "Family & Consumer Sciences",
  "22": "Legal Studies",
  "23": "English",
  "24": "Liberal Arts",
  "25": "Library Science",
  "26": "Biology",
  "27": "Mathematics",
  "28": "Military Science",
  "29": "Military Tech",
  "30": "Interdisciplinary",
  "31": "Parks & Recreation",
  "38": "Philosophy & Religion",
  "39": "Theology",
  "40": "Physical Sciences",
  "41": "Science Tech",
  "42": "Psychology",
  "43": "Security & Law Enforcement",
  "44": "Public Administration",
  "45": "Social Sciences",
  "46": "Construction",
  "47": "Mechanic & Repair",
  "48": "Precision Production",
  "49": "Transportation",
  "50": "Visual & Performing Arts",
  "51": "Health Professions",
  "52": "Business",
  "54": "History",
};

// Cache majors from College Scorecard API — called once per university
// Swift fetches from Scorecard, cleans names via CIP mapping, then caches here
export const cacheMajorsForUniversity = mutation({
  args: {
    universityId: v.id("universities"),
    programs: v.array(
      v.object({
        cipCode: v.string(),
        name: v.string(),
        credentialLevel: v.number(),
        credentialTitle: v.string(),
      })
    ),
  },
  handler: async (ctx, args) => {
    let majorsCreated = 0;
    let linksCreated = 0;

    for (const program of args.programs) {
      // Find or create the major by CIP code
      const existing = await ctx.db
        .query("majors")
        .withSearchIndex("search_name", (q) => q.search("name", program.name))
        .collect();

      // Match by exact CIP code
      let major = existing.find((m) => m.cipCode === program.cipCode);

      if (!major) {
        // Create the major
        const category =
          CIP_CATEGORIES[program.cipCode.substring(0, 2)] ?? "Other";
        const majorId = await ctx.db.insert("majors", {
          name: program.name,
          cipCode: program.cipCode,
          category,
        });
        const newMajor = await ctx.db.get(majorId);
        major = newMajor!;
        majorsCreated++;
      }

      // Check if link already exists
      const currentMajor = major!;
      const existingLinks = await ctx.db
        .query("universityMajors")
        .withIndex("by_university_major", (q) =>
          q.eq("universityId", args.universityId).eq("majorId", currentMajor._id)
        )
        .collect();

      const alreadyHasLevel = existingLinks.some(
        (l) => l.credentialLevel === program.credentialLevel
      );

      if (!alreadyHasLevel) {
        await ctx.db.insert("universityMajors", {
          universityId: args.universityId,
          majorId: currentMajor._id,
          credentialLevel: program.credentialLevel,
          credentialTitle: program.credentialTitle,
        });
        linksCreated++;
      }
    }

    return { majorsCreated, linksCreated };
  },
});

// Check if we already have cached majors for a university
export const hasCachedMajors = query({
  args: { universityId: v.id("universities") },
  handler: async (ctx, args) => {
    const first = await ctx.db
      .query("universityMajors")
      .withIndex("by_university", (q) => q.eq("universityId", args.universityId))
      .first();
    return first !== null;
  },
});
