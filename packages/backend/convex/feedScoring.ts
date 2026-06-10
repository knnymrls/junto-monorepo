import { Doc } from "./_generated/dataModel";

// ── Feed scoring (shared by feed.ts and posts.ts so the two feeds can't drift) ──
//
// Score is a weighted sum of components, each normalized to 0..1. Soft boosts,
// no hard gates: a fresh, highly relevant Ask from a stranger can outrank a
// stale Update from a connection. See docs/feed-spec.md for the rationale.

export const WEIGHTS = {
  relevance: 0.4,
  connection: 0.25,
  recency: 0.2,
  category: 0.1,
  engagement: 0.05,
} as const;

export const PENALTY_ACTED = 0.5;

// The two user-creatable post cards. `looking_for` ("who can…") is an Ask.
export type FeedCardKind = "ask" | "update";

export function cardForCategory(category: string): FeedCardKind {
  return category === "sharing" ? "update" : "ask";
}

// Time-sensitivity differs by card: Asks expire (a hackathon next weekend dies
// after), Updates linger. Values are half-lives in hours.
const HALF_LIFE_HOURS: Record<FeedCardKind, number> = {
  ask: 36,
  update: 96,
};

// Asks are the point of an opportunity engine; nudge them above Updates.
const CATEGORY_WEIGHT: Record<FeedCardKind, number> = {
  ask: 1.0,
  update: 0.5,
};

export function cosineSimilarity(a: number[], b: number[]): number {
  let dot = 0;
  let normA = 0;
  let normB = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA === 0 || normB === 0) return 0;
  return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}

function clamp01(x: number): number {
  return Math.max(0, Math.min(1, x));
}

// Relevance with COMPLEMENTARY embedding pairing:
//   Ask    → "can I help?"      → my profileEmbedding (what I offer) × post
//   Update → "useful to me?"    → my needsEmbedding   (what I seek)  × post
// Missing embeddings → 0.30 neutral (don't zero out, just don't boost).
export function relevanceFor(
  post: Doc<"posts">,
  profileEmbedding: number[] | null | undefined,
  needsEmbedding: number[] | null | undefined
): number {
  if (!post.embedding) return 0.3;
  const card = cardForCategory(post.category);
  const userVec = card === "ask" ? profileEmbedding : needsEmbedding;
  if (!userVec || userVec.length === 0) return 0.3;
  const sim = cosineSimilarity(userVec, post.embedding);
  // Map sim 0.30→0, 0.80→1; below 0.30 is noise.
  return clamp01((sim - 0.3) / 0.5);
}

export function recencyFor(card: FeedCardKind, ageHours: number): number {
  return Math.pow(0.5, Math.max(0, ageHours) / HALF_LIFE_HOURS[card]);
}

export function categoryWeight(card: FeedCardKind): number {
  return CATEGORY_WEIGHT[card];
}

// Mild liveness signal, capped so it can never dominate (opportunity > engagement).
export function engagementScore(responseCount: number): number {
  return Math.min(1, Math.log1p(Math.max(0, responseCount)) / Math.log1p(8));
}

// The full weighted score for a post in a given user's feed.
export function scorePost(args: {
  post: Doc<"posts">;
  isConnection: boolean;
  profileEmbedding: number[] | null | undefined;
  needsEmbedding: number[] | null | undefined;
  responseCount: number;
  alreadyActed: boolean;
  now: number;
}): number {
  const card = cardForCategory(args.post.category);
  const ageHours = (args.now - args.post.createdAt) / (1000 * 60 * 60);

  const relevance = relevanceFor(
    args.post,
    args.profileEmbedding,
    args.needsEmbedding
  );
  const recency = recencyFor(card, ageHours);
  const connection = args.isConnection ? 1 : 0;
  const category = categoryWeight(card);
  const engagement = engagementScore(args.responseCount);

  const score =
    WEIGHTS.relevance * relevance +
    WEIGHTS.connection * connection +
    WEIGHTS.recency * recency +
    WEIGHTS.category * category +
    WEIGHTS.engagement * engagement -
    (args.alreadyActed ? PENALTY_ACTED : 0);

  return score;
}
