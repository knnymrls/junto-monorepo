import { v } from "convex/values";
import { internalAction, internalQuery } from "./_generated/server";
import { internal } from "./_generated/api";

// ── Internal query: distinct skill categories (the controlled tag vocabulary) ──
// Both post topics and match-card tags draw from the same set of skill categories
// so a single category→icon map on the client covers every feed card.
export const listSkillCategories = internalQuery({
  args: {},
  handler: async (ctx): Promise<string[]> => {
    const skills = await ctx.db.query("skills").collect();
    const categories = new Set<string>();
    for (const skill of skills) {
      if (skill.category) categories.add(skill.category);
    }
    return Array.from(categories).sort();
  },
});

// ── Internal action: pick 1-2 skill categories that describe a post ──
// Stored in post.topics; rendered as the tag pills on feed post cards.
export const generatePostTopics = internalAction({
  args: { postId: v.id("posts") },
  handler: async (ctx, args): Promise<void> => {
    const post = await ctx.runQuery(internal.posts.getPost, { postId: args.postId });
    if (!post) return;

    const categories = await ctx.runQuery(internal.topics.listSkillCategories, {});
    if (categories.length === 0) {
      // No taxonomy seeded yet — nothing to tag against.
      return;
    }

    const apiKey = process.env.OPENAI_API_KEY as string;
    if (!apiKey) {
      console.error("OPENAI_API_KEY not set — skipping topic tagging");
      return;
    }

    const categoryLabel =
      post.category === "looking_for"
        ? "Looking for"
        : post.category === "asking"
        ? "Asking"
        : "Sharing";

    try {
      const response = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: "gpt-5-nano",
          messages: [
            {
              role: "system",
              content: `You tag posts on Junto — a community app for college students building things (startups, side projects, creative work).

Pick the 1-2 skill categories that best describe what this post is ABOUT — the domain of work it touches. Choose ONLY from the provided category list. If only one clearly fits, return one. If none genuinely fit, return an empty list. Never invent a category that isn't in the list. Order by relevance (most relevant first).`,
            },
            {
              role: "user",
              content: `Available categories:\n${categories.join("\n")}\n\nPost (${categoryLabel}):\n${post.content}`,
            },
          ],
          response_format: {
            type: "json_schema",
            json_schema: {
              name: "post_topics",
              strict: true,
              schema: {
                type: "object",
                properties: {
                  topics: {
                    type: "array",
                    items: { type: "string", enum: categories },
                  },
                },
                required: ["topics"],
                additionalProperties: false,
              },
            },
          },
        }),
      });

      if (!response.ok) {
        console.error("OpenAI topic tagging error:", response.status, await response.text());
        return;
      }

      const data = await response.json();
      const parsed = JSON.parse(data.choices[0].message.content);

      // Keep only valid categories, dedupe, cap at 2.
      const valid = new Set(categories);
      const topics: string[] = [];
      for (const t of parsed.topics ?? []) {
        if (valid.has(t) && !topics.includes(t)) topics.push(t);
        if (topics.length >= 2) break;
      }

      await ctx.runMutation(internal.posts.updateTopics, {
        postId: args.postId,
        topics,
      });

      console.log(`Tagged post ${args.postId} with topics: ${topics.join(", ") || "(none)"}`);
    } catch (error) {
      console.error("Failed to tag post topics:", error);
    }
  },
});

// ── Internal action: backfill topics for existing posts (run once) ──
export const backfillTopics = internalAction({
  args: {},
  handler: async (ctx): Promise<{ processed: number }> => {
    const postIds = await ctx.runQuery(internal.posts.listPostsWithoutTopics, {});
    console.log(`Backfilling topics for ${postIds.length} posts`);

    for (const postId of postIds) {
      try {
        await ctx.runAction(internal.topics.generatePostTopics, { postId });
        // Small delay for rate-limit safety
        await new Promise((resolve) => setTimeout(resolve, 200));
      } catch (error) {
        console.error(`Failed to backfill topics for post ${postId}:`, error);
      }
    }

    return { processed: postIds.length };
  },
});
