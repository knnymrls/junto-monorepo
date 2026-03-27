import { v } from "convex/values";
import { internalAction, internalMutation, internalQuery } from "./_generated/server";
import { internal } from "./_generated/api";
import { Doc } from "./_generated/dataModel";

// === INTERNAL HELPERS ===

// Get user by ID (internal)
export const getUser = internalQuery({
  args: { id: v.id("users") },
  handler: async (ctx, args): Promise<Doc<"users"> | null> => {
    return await ctx.db.get(args.id);
  },
});

// Update user profileEmbedding (internal)
export const updateEmbedding = internalMutation({
  args: {
    userId: v.id("users"),
    embedding: v.array(v.float64()),
  },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.userId, {
      profileEmbedding: args.embedding,
      updatedAt: Date.now(),
    });
  },
});

// === EMBEDDING GENERATION ===

// Build the text to embed from a user profile
function buildEmbeddingText(user: {
  name: string;
  headline?: string;
  currentProject?: string;
  lookingFor?: string;
  canHelpWith?: string;
}): string {
  const parts: string[] = [];

  if (user.headline) parts.push(`Headline: ${user.headline}`);
  if (user.currentProject) parts.push(`Currently building: ${user.currentProject}`);
  if (user.lookingFor) parts.push(`Looking for: ${user.lookingFor}`);
  if (user.canHelpWith) parts.push(`Can help with: ${user.canHelpWith}`);

  return parts.join("\n");
}

// Generate embedding for a user profile (internal - called by scheduler)
export const generateEmbedding = internalAction({
  args: { userId: v.id("users") },
  handler: async (ctx, args): Promise<number[] | null> => {
    // Get the user
    const user = await ctx.runQuery(internal.embeddings.getUser, { id: args.userId });
    if (!user) throw new Error("User not found");

    // Build text to embed
    const text = buildEmbeddingText(user);
    if (!text.trim()) {
      console.log("No content to embed for user", args.userId);
      return null;
    }

    // Call OpenAI (env vars accessed directly in Convex actions)
    const apiKey = process.env.OPENAI_API_KEY as string;
    if (!apiKey) throw new Error("OPENAI_API_KEY not set in Convex environment");

    const response = await fetch("https://api.openai.com/v1/embeddings", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: "text-embedding-3-small",
        input: text,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`OpenAI API error: ${error}`);
    }

    const data = await response.json();
    const embedding = data.data[0].embedding as number[];

    // Save embedding
    await ctx.runMutation(internal.embeddings.updateEmbedding, {
      userId: args.userId,
      embedding,
    });

    console.log(`Generated embedding for user ${user.name}`);
    return embedding;
  },
});

// Batch generate embeddings for all users without one (internal)
export const generateAllEmbeddings = internalAction({
  args: {},
  handler: async (ctx): Promise<{ processed: number }> => {
    const users = await ctx.runQuery(internal.embeddings.listUsersWithoutEmbedding, {});

    console.log(`Found ${users.length} users without embeddings`);

    for (const user of users) {
      try {
        await ctx.runAction(internal.embeddings.generateEmbedding, { userId: user._id });
        // Small delay to avoid rate limits
        await new Promise(resolve => setTimeout(resolve, 200));
      } catch (error) {
        console.error(`Failed to generate embedding for ${user.name}:`, error);
      }
    }

    return { processed: users.length };
  },
});

// Get users without embeddings
export const listUsersWithoutEmbedding = internalQuery({
  args: {},
  handler: async (ctx): Promise<Doc<"users">[]> => {
    const users = await ctx.db.query("users").collect();
    return users.filter(m => !m.profileEmbedding || m.profileEmbedding.length === 0);
  },
});

// === POST EMBEDDINGS ===

// Generate embedding for a post
export const generatePostEmbedding = internalAction({
  args: { postId: v.id("posts") },
  handler: async (ctx, args): Promise<number[] | null> => {
    // Get the post
    const post = await ctx.runQuery(internal.posts.getPost, { postId: args.postId });
    if (!post) throw new Error("Post not found");

    // Build text: category + content
    const categoryLabel = post.category === "looking_for" ? "Looking for" :
                          post.category === "asking" ? "Asking" : "Sharing";
    const text = `${categoryLabel}: ${post.content}`;

    // Call OpenAI
    const apiKey = process.env.OPENAI_API_KEY as string;
    if (!apiKey) throw new Error("OPENAI_API_KEY not set in Convex environment");

    const response = await fetch("https://api.openai.com/v1/embeddings", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: "text-embedding-3-small",
        input: text,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`OpenAI API error: ${error}`);
    }

    const data = await response.json();
    const embedding = data.data[0].embedding as number[];

    // Save embedding
    await ctx.runMutation(internal.posts.updateEmbedding, {
      postId: args.postId,
      embedding,
    });

    console.log(`Generated embedding for post ${args.postId}`);
    return embedding;
  },
});
