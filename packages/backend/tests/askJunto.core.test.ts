import { describe, it, expect } from "vitest";
import {
  AskJuntoOutputSchema,
  BlockSchema,
  extractSignal,
  topNeeds,
  makeItemStoreSession,
  InMemoryItemStore,
  type AskJuntoOutput,
} from "../convex/askJuntoCore";

const validOutput: AskJuntoOutput = {
  say: "Here are a few designers who could help.",
  show: { type: "people", userIds: ["u1", "u2"], note: null },
  followUp: "Want me to write an intro to any of them?",
  intent: { isNeed: true, category: "design", need: "needs a UI designer for an app" },
};

describe("block schema", () => {
  it("accepts a valid block", () => {
    expect(BlockSchema.safeParse({ type: "people", userIds: [], note: null }).success).toBe(true);
    expect(
      BlockSchema.safeParse({ type: "draftAsk", title: "t", body: "b" }).success
    ).toBe(true);
  });

  it("rejects an unknown block type", () => {
    expect(BlockSchema.safeParse({ type: "banana", body: "x" }).success).toBe(false);
  });

  it("rejects an action with an invalid kind", () => {
    expect(
      BlockSchema.safeParse({ type: "action", label: "x", kind: "explode" }).success
    ).toBe(false);
  });

  it("accepts the full agent output", () => {
    expect(AskJuntoOutputSchema.safeParse(validOutput).success).toBe(true);
  });

  it("rejects output missing intent", () => {
    expect(
      AskJuntoOutputSchema.safeParse({ say: "", show: null, followUp: null }).success
    ).toBe(false);
  });

  it("allows a null followUp (no useful next step)", () => {
    expect(AskJuntoOutputSchema.safeParse({ ...validOutput, followUp: null }).success).toBe(true);
  });
});

describe("one-thing-per-message rule (structural)", () => {
  it("allows a null show (just talking)", () => {
    const out = { ...validOutput, say: "Maya's the best fit.", show: null };
    expect(AskJuntoOutputSchema.safeParse(out).success).toBe(true);
  });

  it("show accepts exactly one block of any content type", () => {
    for (const block of [
      { type: "people", userIds: ["u1"], note: null },
      { type: "opportunities", eventIds: ["e1"], note: null },
      { type: "draftAsk", title: "t", body: "b" },
      { type: "draftIntro", targetUserId: "u1", message: "hi" },
      { type: "action", label: "Connect", kind: "connect" },
    ]) {
      expect(AskJuntoOutputSchema.safeParse({ ...validOutput, show: block }).success).toBe(true);
    }
  });

  it("cannot express two things — show is a single slot, not a list", () => {
    const twoThings = {
      ...validOutput,
      show: [
        { type: "people", userIds: ["u1"], note: null },
        { type: "draftIntro", targetUserId: "u1", message: "hi" },
      ],
    };
    expect(AskJuntoOutputSchema.safeParse(twoThings).success).toBe(false);
  });
});

describe("extractSignal", () => {
  const base = { userId: "u1", universityId: "univ1", threadId: "t1", now: 1000 };

  it("produces a signal for a real need", () => {
    const sig = extractSignal(validOutput, base);
    expect(sig).not.toBeNull();
    expect(sig).toMatchObject({
      userId: "u1",
      universityId: "univ1",
      threadId: "t1",
      category: "design",
      status: "open",
      createdAt: 1000,
    });
    expect(sig!.text).toContain("designer");
  });

  it("returns null when not a need", () => {
    const out = { ...validOutput, intent: { isNeed: false, category: "other" as const, need: "" } };
    expect(extractSignal(out, base)).toBeNull();
  });

  it("returns null when need text is empty/whitespace", () => {
    const out = { ...validOutput, intent: { isNeed: true, category: "design" as const, need: "   " } };
    expect(extractSignal(out, base)).toBeNull();
  });

  it("carries a null universityId through", () => {
    const sig = extractSignal(validOutput, { ...base, universityId: null });
    expect(sig!.universityId).toBeNull();
  });
});

describe("topNeeds", () => {
  it("counts and sorts by frequency, then name", () => {
    const result = topNeeds([
      { category: "design" },
      { category: "technical" },
      { category: "design" },
      { category: "advice" },
      { category: "technical" },
      { category: "design" },
    ]);
    expect(result[0]).toEqual({ category: "design", count: 3 });
    expect(result[1]).toEqual({ category: "technical", count: 2 });
    expect(result[2]).toEqual({ category: "advice", count: 1 });
  });

  it("handles empty input", () => {
    expect(topNeeds([])).toEqual([]);
  });
});

describe("item-store session (SDK Session backing)", () => {
  it("round-trips items in order and slices by limit", async () => {
    const session = makeItemStoreSession(new InMemoryItemStore());
    await session.addItems([{ id: 1 }, { id: 2 }]);
    await session.addItems([{ id: 3 }]);

    expect(await session.getItems()).toEqual([{ id: 1 }, { id: 2 }, { id: 3 }]);
    expect(await session.getItems(2)).toEqual([{ id: 2 }, { id: 3 }]);
  });

  it("popItem removes and returns the last item", async () => {
    const session = makeItemStoreSession(new InMemoryItemStore());
    await session.addItems([{ id: 1 }, { id: 2 }]);
    expect(await session.popItem()).toEqual({ id: 2 });
    expect(await session.getItems()).toEqual([{ id: 1 }]);
  });

  it("clearSession empties the store", async () => {
    const session = makeItemStoreSession(new InMemoryItemStore());
    await session.addItems([{ id: 1 }]);
    await session.clearSession();
    expect(await session.getItems()).toEqual([]);
  });

  it("addItems ignores empty arrays", async () => {
    const session = makeItemStoreSession(new InMemoryItemStore());
    await session.addItems([]);
    expect(await session.getItems()).toEqual([]);
  });
});
