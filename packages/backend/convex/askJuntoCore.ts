// Ask Junto — pure core logic. Depends only on zod.
// No Convex, no @openai/agents imports here, so it runs in plain Node for tests
// and can be reused by both the agent module and the data/dashboard modules.

import { z } from "zod";

// === Need categories (the university dashboard groups asks by these) ===
export const NEED_CATEGORIES = [
  "collaborator",
  "technical",
  "design",
  "creative",
  "business",
  "funding",
  "advice",
  "events",
  "academic",
  "other",
] as const;

export type NeedCategory = (typeof NEED_CATEGORIES)[number];

// === Block schema — the agent's structured output contract ===
// Every assistant reply is a list of these. The iOS app maps block.type -> a component.
// Note: avoid `.optional()` so the schema stays strict-mode friendly for structured
// outputs; use `.nullable()` where a field may be absent.

const PeopleBlock = z.object({
  type: z.literal("people"),
  userIds: z.array(z.string()),
  note: z.string().nullable(),
});

const OpportunitiesBlock = z.object({
  type: z.literal("opportunities"),
  eventIds: z.array(z.string()),
  note: z.string().nullable(),
});

const DraftAskBlock = z.object({
  type: z.literal("draftAsk"),
  title: z.string(),
  body: z.string(),
});

const DraftIntroBlock = z.object({
  type: z.literal("draftIntro"),
  targetUserId: z.string(),
  message: z.string(),
});

const ButtonBlock = z.object({
  type: z.literal("action"),
  label: z.string(),
  kind: z.enum(["connect", "post_ask", "rsvp", "view_profile"]),
});

// NOTE: z.union (not discriminatedUnion) on purpose — it serializes to `anyOf`,
// which OpenAI structured outputs accept. discriminatedUnion emits `oneOf`, which
// the Responses API rejects ("'oneOf' is not permitted"). Each member still carries
// a literal `type`, so TS narrowing on block.type keeps working.

// A content block is THE one thing a message shows: people, opportunities, a draft,
// or an action. One per message — never a stack.
export const BlockSchema = z.union([
  PeopleBlock,
  OpportunitiesBlock,
  DraftAskBlock,
  DraftIntroBlock,
  ButtonBlock,
]);
export type Block = z.infer<typeof BlockSchema>;

// The agent's output. One message does ONE thing: a short `say` line plus a single
// `show` block (or null when it's just talking). Stepwise and reactive — it never
// stacks people + a draft; the student drives the next step. Enforced by shape:
// `show` is one object or null, not a list. `intent` feeds the university dashboard.
export const AskJuntoOutputSchema = z.object({
  say: z.string(),
  show: BlockSchema.nullable(),
  // A predicted next step, phrased as a short offer/question ("Want me to write an
  // intro to any of them?"). NOT a second action — a nudge the student can accept.
  // In iOS this renders as a tappable suggestion chip. null when there's no obvious next step.
  followUp: z.string().nullable(),
  intent: z.object({
    isNeed: z.boolean(),
    category: z.enum(NEED_CATEGORIES),
    need: z.string(),
  }),
});

export type AskJuntoOutput = z.infer<typeof AskJuntoOutputSchema>;

// === Signal extraction (what the university sees) ===
export type SignalDraft = {
  userId: string;
  universityId: string | null;
  threadId: string;
  text: string;
  category: NeedCategory;
  status: "open";
  createdAt: number;
};

export function extractSignal(
  output: AskJuntoOutput,
  ctx: { userId: string; universityId: string | null; threadId: string; now: number }
): SignalDraft | null {
  const intent = output?.intent;
  if (!intent || !intent.isNeed) return null;
  const text = (intent.need ?? "").trim();
  if (!text) return null;
  return {
    userId: ctx.userId,
    universityId: ctx.universityId,
    threadId: ctx.threadId,
    text,
    category: intent.category,
    status: "open",
    createdAt: ctx.now,
  };
}

// === Dashboard aggregation (pure) ===
export function topNeeds(
  signals: { category: string }[]
): { category: string; count: number }[] {
  const counts = new Map<string, number>();
  for (const s of signals) {
    counts.set(s.category, (counts.get(s.category) ?? 0) + 1);
  }
  return [...counts.entries()]
    .map(([category, count]) => ({ category, count }))
    .sort((a, b) => b.count - a.count || a.category.localeCompare(b.category));
}

// === Session store factory ===
// Backs the @openai/agents Session interface with any async item store.
// Items are opaque here (the SDK owns their shape); we just persist/retrieve order.
export interface ItemStore {
  list(): Promise<unknown[]>;
  append(items: unknown[]): Promise<void>;
  popLast(): Promise<unknown | undefined>;
  clear(): Promise<void>;
}

export function makeItemStoreSession(store: ItemStore) {
  return {
    async getItems(limit?: number): Promise<unknown[]> {
      const all = await store.list();
      return typeof limit === "number" && limit >= 0 ? all.slice(-limit) : all;
    },
    async addItems(items: unknown[]): Promise<void> {
      if (items && items.length) await store.append(items);
    },
    async popItem(): Promise<unknown | undefined> {
      return store.popLast();
    },
    async clearSession(): Promise<void> {
      await store.clear();
    },
  };
}

// In-memory store — used by tests and the offline smoke harness.
export class InMemoryItemStore implements ItemStore {
  private items: unknown[] = [];
  async list() {
    return [...this.items];
  }
  async append(items: unknown[]) {
    this.items.push(...items);
  }
  async popLast() {
    return this.items.pop();
  }
  async clear() {
    this.items = [];
  }
}
