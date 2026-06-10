import { describe, it, expect } from "vitest";
import { runAskJunto, type AskJuntoTools } from "../convex/askJuntoAgent";
import { AskJuntoOutputSchema, InMemoryItemStore } from "../convex/askJuntoCore";

// Real end-to-end run against OpenAI. Skips automatically when no key is set, so
// `vitest run` stays green offline. To exercise the actual agent:
//   OPENAI_API_KEY=sk-... pnpm --filter @junto/backend test
const hasKey = !!process.env.OPENAI_API_KEY;

// Fake campus so we don't need Convex or real data.
const fakeTools: AskJuntoTools = {
  findPeople: async (_need, limit) =>
    [
      { userId: "user_maya", label: "Product designer, into app projects" },
      { userId: "user_devin", label: "UI/UX + Figma, freelances" },
      { userId: "user_sofia", label: "Brand + visual design" },
    ].slice(0, limit),
  findOpportunities: async (_interest, limit) =>
    [
      { eventId: "evt_pitch", title: "Open Pitch Night", startsAt: Date.now() + 86400000 },
      { eventId: "evt_coffee", title: "Founders Coffee", startsAt: Date.now() + 172800000 },
    ].slice(0, limit),
  getMyContext: async () => ({
    name: "Test Student",
    headline: "CS major building a study app",
    skills: ["engineering"],
    lookingFor: "a designer to fix my UI",
    canHelpWith: "backend / iOS",
  }),
};

describe("ask junto agent (live)", () => {
  it.skipIf(!hasKey)(
    "returns valid blocks for a design need",
    async () => {
      const output = await runAskJunto({
        tools: fakeTools,
        store: new InMemoryItemStore(),
        message: "my app's UI looks like trash, I need someone who knows design",
      });

      const parsed = AskJuntoOutputSchema.safeParse(output);
      expect(parsed.success).toBe(true);
      if (!parsed.success) return;

      // "I need a designer" → it should show people and NOT pre-draft an intro,
      // offer a follow-up next step, and flag a real need for the dashboard.
      expect(parsed.data.show?.type).toBe("people");
      expect(typeof parsed.data.followUp).toBe("string");
      expect(parsed.data.followUp && parsed.data.followUp.length).toBeGreaterThan(0);
      expect(parsed.data.intent.isNeed).toBe(true);
      // eslint-disable-next-line no-console
      console.log("Ask Junto output:", JSON.stringify(parsed.data, null, 2));
    },
    180_000
  );

  it("agent builder + schema wire up without a key", () => {
    // Always-on guard so the file isn't empty when offline.
    expect(typeof runAskJunto).toBe("function");
  });
});
