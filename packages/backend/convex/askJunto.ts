"use node";

// Ask Junto — the agent action. Runs the OpenAI Agents SDK in the Convex Node
// runtime. Tools call back into Convex; the SDK Session is backed by askJuntoItems;
// the final blocks land on the assistant render row; needs feed the university.

import { v } from "convex/values";
import { action } from "./_generated/server";
import { api, internal } from "./_generated/api";
import {
  AskJuntoOutputSchema,
  extractSignal,
  type ItemStore,
} from "./askJuntoCore";
import {
  runAskJunto,
  stripDashes,
  type AskJuntoTools,
  type PersonHit,
  type EventHit,
} from "./askJuntoAgent";

// Strip em/en dashes from any user-facing text inside a show block.
function cleanShowDashes(show: any): any {
  if (!show || typeof show !== "object") return show;
  switch (show.type) {
    case "draftIntro":
      return { ...show, message: stripDashes(show.message) };
    case "draftAsk":
      return { ...show, title: stripDashes(show.title), body: stripDashes(show.body) };
    case "people":
    case "opportunities":
      return show.note ? { ...show, note: stripDashes(show.note) } : show;
    case "action":
      return { ...show, label: stripDashes(show.label) };
    default:
      return show;
  }
}

export const run = action({
  args: {
    threadId: v.id("askJuntoThreads"),
    message: v.string(),
    currentUserId: v.id("users"),
  },
  handler: async (ctx, args) => {
    // 1. Show the user's message + an assistant placeholder immediately (reactive UI).
    await ctx.runMutation(internal.askJuntoData.appendUserMessage, {
      threadId: args.threadId,
      text: args.message,
    });
    const messageId = await ctx.runMutation(
      internal.askJuntoData.insertAssistantPlaceholder,
      { threadId: args.threadId }
    );
    // Initial thinking label — updated live as the agent calls its tools.
    await ctx.runMutation(internal.askJuntoData.setAssistantStep, {
      messageId,
      step: "Thinking...",
    });

    // 2. Resolve the student (for personalization + university tagging) and load
    // their durable memory (what Ask Junto already knows about them).
    const me = await ctx.runQuery(api.users.get, { id: args.currentUserId });
    const universityId = (me?.universityId as string | undefined) ?? null;
    const memoryDocs = await ctx.runQuery(internal.askJuntoData.listMemory, {
      userId: args.currentUserId,
    });
    const memory = memoryDocs.map((m: any) => m.text as string);

    // 3. Convex-backed SDK Session store.
    const store: ItemStore = {
      list: async () => {
        const strings = await ctx.runQuery(internal.askJuntoData.itemsList, {
          threadId: args.threadId,
        });
        return strings.map((s) => JSON.parse(s));
      },
      append: async (items) => {
        await ctx.runMutation(internal.askJuntoData.itemsAppend, {
          threadId: args.threadId,
          items: items.map((i) => JSON.stringify(i)),
        });
      },
      popLast: async () => {
        const s = await ctx.runMutation(internal.askJuntoData.itemsPopLast, {
          threadId: args.threadId,
        });
        return s ? JSON.parse(s) : undefined;
      },
      clear: async () => {
        await ctx.runMutation(internal.askJuntoData.itemsClear, {
          threadId: args.threadId,
        });
      },
    };

    // 4. Retrieval tools, wired to existing Convex functions.
    const tools: AskJuntoTools = {
      findPeople: async (need, limit): Promise<PersonHit[]> => {
        const lim = Math.max(1, limit);
        // Name matches first (so "intro to Marcus" actually finds Marcus by name),
        // then semantic vector matches for need-based searches ("a designer").
        const [byName, vec] = await Promise.all([
          ctx.runQuery(api.users.searchForCards, {
            query: need,
            currentUserId: args.currentUserId,
            limit: lim,
          }),
          ctx.runAction(api.search.vectorSearch, {
            query: need,
            currentUserId: args.currentUserId,
          }),
        ]);

        const hits: PersonHit[] = [];
        const seen = new Set<string>();
        for (const u of byName as any[]) {
          if (seen.has(u._id)) continue;
          seen.add(u._id);
          hits.push({ userId: u._id as string, name: u.name as string, label: (u.headline as string) ?? "" });
        }
        for (const r of vec.results) {
          if (hits.length >= lim) break;
          if (seen.has(r.userId)) continue;
          seen.add(r.userId);
          const u = await ctx.runQuery(api.users.get, { id: r.userId as any });
          hits.push({ userId: r.userId, name: ((u as any)?.name as string) ?? "A maker", label: r.explanation });
        }
        return hits.slice(0, lim);
      },
      findOpportunities: async (_interest, limit): Promise<EventHit[]> => {
        // Don't scope by universityId — events aren't tagged with one, so the
        // filter would drop every result. Single-campus for now.
        const events = await ctx.runQuery(api.events.listUpcoming, {
          limit: Math.max(1, limit),
        });
        return events.map((e: any) => ({
          eventId: e._id as string,
          title: e.title as string,
          startsAt: (e.date as number) ?? null,
        }));
      },
      getMyContext: async () => {
        if (!me) return null;
        return {
          name: me.name,
          headline: me.headline ?? null,
          skills: (me.skillCategories as string[] | undefined) ?? [],
          lookingFor: me.lookingFor ?? null,
          canHelpWith: me.canHelpWith ?? null,
        };
      },
      rsvp: async (eventId) => {
        await ctx.runMutation(api.events.rsvp, {
          eventId: eventId as any,
          userId: args.currentUserId,
          status: "going",
        });
        return { ok: true as const };
      },
      remember: async (facts) => {
        await ctx.runMutation(internal.askJuntoData.rememberFacts, {
          userId: args.currentUserId,
          facts,
        });
      },
    };

    // 5. Run the agent.
    try {
      const output = await runAskJunto({
        tools,
        store,
        message: args.message,
        memory,
        onStep: async (step) => {
          await ctx.runMutation(internal.askJuntoData.setAssistantStep, {
            messageId,
            step,
          });
        },
        onSayDelta: async (say) => {
          await ctx.runMutation(internal.askJuntoData.streamAssistantText, {
            messageId,
            text: say,
          });
        },
      });
      const parsed = AskJuntoOutputSchema.safeParse(output);
      if (!parsed.success) {
        await ctx.runMutation(internal.askJuntoData.failAssistantMessage, {
          messageId,
        });
        return { ok: false as const, error: "invalid_output" };
      }

      const { say, show, followUp } = parsed.data;
      // No em/en dashes anywhere user-facing (the model ignores the instruction).
      const cleanSay = stripDashes(say);
      const cleanFollowUp = followUp ? stripDashes(followUp) : followUp;
      const cleanShow = cleanShowDashes(show);

      await ctx.runMutation(internal.askJuntoData.finalizeAssistantMessage, {
        messageId,
        // One message = one thing: say line + a single show block + a follow-up nudge.
        blocks: JSON.stringify({ say: cleanSay, show: cleanShow, followUp: cleanFollowUp }),
        text: cleanSay || undefined,
      });

      // 6. Feed the university dashboard.
      const signal = extractSignal(parsed.data, {
        userId: args.currentUserId as string,
        universityId,
        threadId: args.threadId as string,
        now: Date.now(),
      });
      if (signal) {
        await ctx.runMutation(internal.askJuntoData.upsertSignal, {
          userId: args.currentUserId,
          universityId: universityId ? (universityId as any) : undefined,
          threadId: args.threadId,
          text: signal.text,
          category: signal.category,
          now: signal.createdAt,
        });
      }

      return { ok: true as const, hasBlock: show !== null };
    } catch (err) {
      await ctx.runMutation(internal.askJuntoData.failAssistantMessage, {
        messageId,
      });
      throw err;
    }
  },
});
