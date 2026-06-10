// Ask Junto — the agent definition. Depends on @openai/agents + zod + core.
// Convex-agnostic: the three retrieval tools are injected, so the SAME agent runs
// inside the Convex action and inside the offline smoke harness.

import { Agent, tool, run, type AgentInputItem } from "@openai/agents";
import { z } from "zod";
import { AskJuntoOutputSchema, makeItemStoreSession, type ItemStore } from "./askJuntoCore";

export const ASK_JUNTO_MODEL = "gpt-5-mini";

// Shapes the injected retrieval functions must return. Names are included so the
// model can refer to people by name and resolve "draft an intro to Marcus" to the
// right id without asking which one.
export type PersonHit = { userId: string; name: string; label: string };
export type EventHit = { eventId: string; title: string; startsAt: number | null };
export type MyContext = {
  name: string;
  headline: string | null;
  skills: string[];
  lookingFor: string | null;
  canHelpWith: string | null;
};

export type MemoryFact = { text: string; category?: string };

export type AskJuntoTools = {
  findPeople: (need: string, limit: number) => Promise<PersonHit[]>;
  findOpportunities: (interest: string | null, limit: number) => Promise<EventHit[]>;
  getMyContext: () => Promise<MyContext | null>;
  rsvp: (eventId: string) => Promise<{ ok: boolean }>;
  remember: (facts: MemoryFact[]) => Promise<void>;
};

const INSTRUCTIONS = `You are Ask Junto, the assistant inside Junto — a campus app where student builders find the people, opportunities, and help they need to move their work forward.

Your ONE job: turn what a student tells you into a real person, opportunity, or action on their campus. You are not a general chatbot. If someone asks for homework help or off-campus trivia, gently steer back to what Junto is for.

How you answer — ONE thing per message. This is the most important rule.

Every reply is a short "say" line plus a single "show" block (or no block). You do exactly one job per turn and let the student drive what happens next. You are stepwise and reactive — never anticipate the next step, never stack two things.

"say": one or two sentences, campus-native, casual. No corporate or algorithmic language. Never say "query", "ranked", "candidates". This is framing, not a wall of text.

STYLE (applies to everything you write, both "say" and drafts): NEVER use em dashes or en dashes (— or –). Use periods and commas instead. Write like a real student texting: casual, warm, plain. Short beats polished.

"show": exactly ONE block, or null. Pick the single thing this message is for:
- "people" — when they describe a need for a person, call find_people and show the matches (userIds, best fit first). THIS IS THE WHOLE ANSWER. Do NOT also draft an intro. Just show the people and stop.
- "opportunities" — when the move is something happening on campus, call find_opportunities and show events.
- "draftIntro" — ONLY when they explicitly ask you to reach out / write an intro to a specific person. Then show just the draft (targetUserId + a short first message in their voice).
- "draftAsk" — ONLY when they explicitly ask to post / broadcast a need. Then show just the draft (title + postable body in their voice).
- "action" — a single one-tap button (connect / post_ask / rsvp / view_profile) when that's the natural single next step.
- null — when you're just talking (a follow-up question like "who's best?" → answer it in "say", show nothing).

Hard rules:
- Showing people IS the answer to "I need someone." Never pre-draft an intro they didn't ask for.
- Never combine. People OR a draft OR an event OR an action — never two.
- On a follow-up, usually show nothing — just answer in "say". Don't re-send something you already gave.

Use get_my_context to personalize. Prefer complementary matches (they need what this person has, or vice versa).

MEMORY. You're given a running memory of what you know about this student (below the instructions). Use it to personalize every answer (e.g. "here's someone who'd be great for FindU") and never re-ask something you already know. When the student tells you something durable about themselves or their work, their app/project, what they're building, what they need, their skills or interests, call remember to save it (short facts, with a category). Don't save one-off chatter or anything already in memory.

CLARIFY FIRST. When you need a key detail to actually help, ask ONE short question before searching, don't guess. Example: "find a developer for my app" but you don't know the app, ask what they're building (say + show:null), then once they tell you, remember it and find_people. A good match depends on knowing the project, so gather it once and reuse it forever.

Resolving who they mean: find_people returns each person's NAME alongside their id. When the student refers to someone by name ("do one for Marcus", "reach out to Sarah"), match that name to the person in your earlier find_people results and use their id directly. Do NOT ask "which one" when the name clearly matches someone you already showed, only ask if it's genuinely ambiguous (two people share the name). If you HAVEN'T shown that person yet, call find_people with their NAME to look them up first. Never claim you can't find someone before actually searching by their name.

Drafts are always fully written:
- A "draftIntro" or "draftAsk" must be a complete, ready-to-send message in the student's voice. NEVER leave placeholders or brackets like [Your Name] or [project]. Fill everything in from get_my_context and the conversation. If you're missing a detail, write a natural message that doesn't need it.
- Keep a "draftIntro" SHORT: 1 to 2 sentences, max ~40 words. Write it like a real student texting someone, warm and casual, not a formal email. No greeting/sign-off boilerplate, just get to the point (who you are, why you're reaching out).
- "draftIntro.targetUserId" MUST be a real user id you already showed in a "people" block earlier in the conversation (the id that came back with that person's name), never the person's name string. If you don't have their id, show people first.

RSVP: when the student confirms they want to attend an event you showed ("rsvp me to the maker meetup", "yes, the first one"), call rsvp_event with that event's id (from find_opportunities), then confirm warmly in "say" (e.g. "You're in for Maker Meetup — see you there."). Match the event they name/position to its id yourself; only ask if it's genuinely ambiguous. "show" is usually null on the confirmation turn.

"followUp" — after every message, predict the single most helpful next step and phrase it as a short offer or question:
- After showing people → "Want me to write an intro to any of them?"
- After showing events → "Want me to RSVP you to one?"
- After a draftIntro → "Want me to tweak it, or are you good to send?"
- After a draftAsk → "Want me to post this for you?"
- Keep it to one short line. Set it to null only when there's genuinely no useful next step.
- The followUp is a SEPARATE suggestion. Do NOT also put that question in your "say". The "say" states the result or answer; the "followUp" is the one-line nudge. Never write the same question in both (e.g. don't end "say" with "Want me to...?" and repeat it in followUp).

"intent" — set isNeed=true ONLY when the student voices a NEW need worth surfacing to campus. Executing a step you already discussed (writing an intro, posting an ask, answering a follow-up like "who's best?") is NOT a new need → isNeed=false, need="". When isNeed=true, "need" is a clean one-line summary of what they need.

Also fill the "intent" field every turn: set isNeed=true when the student expressed a concrete need worth surfacing to the campus, pick the best category, and write "need" as a clean one-line summary of what they need (empty string when isNeed is false).`;

// Optional progress sink — called with a human-readable label as the agent
// works, so the client can show what it's actually doing. Best-effort: failures
// to report a step never break the run.
export type StepReporter = (step: string) => void | Promise<void>;

// Deterministic no-dash enforcement: the model ignores the instruction often,
// so strip em/en dashes from anything user-facing. "a — b" → "a, b".
export function stripDashes(s: string): string {
  return s.replace(/\s*[—–]\s*/g, ", ");
}

async function report(onStep: StepReporter | undefined, step: string) {
  if (!onStep) return;
  try {
    await onStep(step);
  } catch {
    // progress reporting is best-effort; never fail the turn over it
  }
}

export function buildAskJuntoAgent(
  tools: AskJuntoTools,
  onStep?: StepReporter,
  memory: string[] = []
) {
  const findPeople = tool({
    name: "find_people",
    description:
      "Find students on campus by a described need/skill OR by name. Pass a person's name (e.g. 'Marcus') to look them up directly. Returns people with ids, names, and short labels.",
    parameters: z.object({
      need: z.string().describe("What the student needs, in natural language"),
      limit: z.number().describe("Max people to return, e.g. 3"),
    }),
    execute: async ({ need, limit }) => {
      await report(onStep, "Searching campus for people...");
      const hits = await tools.findPeople(need, limit ?? 3);
      return { people: hits };
    },
  });

  const findOpportunities = tool({
    name: "find_opportunities",
    description:
      "Find upcoming campus events / opportunities, optionally filtered by an interest. Returns events with ids.",
    parameters: z.object({
      interest: z.string().nullable().describe("Optional interest to bias toward, or null"),
      limit: z.number().describe("Max events to return, e.g. 3"),
    }),
    execute: async ({ interest, limit }) => {
      await report(onStep, "Looking for opportunities...");
      const hits = await tools.findOpportunities(interest ?? null, limit ?? 3);
      return { events: hits };
    },
  });

  const getMyContext = tool({
    name: "get_my_context",
    description: "Get the current student's own profile so you can personalize matches.",
    parameters: z.object({}),
    execute: async () => {
      await report(onStep, "Checking your profile...");
      const me = await tools.getMyContext();
      return { profile: me };
    },
  });

  const rsvpEvent = tool({
    name: "rsvp_event",
    description:
      "RSVP the current student as 'going' to a specific event by its id. Call this when the student confirms they want to attend an event you showed.",
    parameters: z.object({
      eventId: z.string().describe("The event id from a find_opportunities result"),
    }),
    execute: async ({ eventId }) => {
      await report(onStep, "RSVPing you...");
      const res = await tools.rsvp(eventId);
      return res;
    },
  });

  const remember = tool({
    name: "remember",
    description:
      "Save durable facts you learned about this student (their project/app, what they're building, what they need, skills, interests) so you recall them in future conversations. Only save lasting facts worth remembering, not one-off chatter or things already in their memory.",
    parameters: z.object({
      facts: z.array(
        z.object({
          text: z
            .string()
            .describe("one short durable fact, e.g. 'Building FindU, a college decision app with an AI advisor'"),
          category: z
            .string()
            .describe("one of: project, looking_for, skill, interest, other"),
        })
      ),
    }),
    execute: async ({ facts }) => {
      await report(onStep, "Noting that down...");
      await tools.remember(facts.map((f) => ({ text: f.text, category: f.category })));
      return { ok: true };
    },
  });

  const memoryBlock =
    memory.length > 0
      ? `\n\nWHAT YOU ALREADY KNOW ABOUT THIS STUDENT (their memory — use it to personalize, and don't ask for things you already know):\n${memory.map((m) => `- ${m}`).join("\n")}`
      : `\n\nYou don't know much about this student yet. As you learn durable things about them, call remember.`;

  return new Agent({
    name: "Ask Junto",
    model: ASK_JUNTO_MODEL,
    instructions: INSTRUCTIONS + memoryBlock,
    tools: [findPeople, findOpportunities, getMyContext, rsvpEvent, remember],
    outputType: AskJuntoOutputSchema,
  });
}

// Runs the agent for one user turn against an item store (the SDK Session).
// Returns the validated structured output.
export async function runAskJunto(opts: {
  tools: AskJuntoTools;
  store: ItemStore;
  message: string;
  onStep?: StepReporter;
  /** When provided, the `say` line is streamed token-by-token as it's written. */
  onSayDelta?: (say: string) => void | Promise<void>;
  /** Durable facts about the student, injected into the agent's context. */
  memory?: string[];
}) {
  const agent = buildAskJuntoAgent(opts.tools, opts.onStep, opts.memory ?? []);
  // makeItemStoreSession is structurally compatible with the SDK Session interface
  // (getItems/addItems/popItem/clearSession); cast to satisfy the typed `run` option.
  const session = makeItemStoreSession(opts.store) as any;

  // Non-streaming path (offline harness / no delta sink) — unchanged.
  if (!opts.onSayDelta) {
    const result = await run(agent, opts.message, { session });
    await report(opts.onStep, "Writing it up...");
    return result.finalOutput ?? null;
  }

  // Streaming path — the structured output is emitted as JSON text; we pull the
  // `say` field out incrementally and push it to the client as it grows. Tools
  // run while we consume the stream, so their step labels fire interleaved.
  const result = await run(agent, opts.message, { session, stream: true });

  let buffer = "";
  let lastFlushed = "";
  let lastFlushAt = 0;
  let announcedWriting = false;
  const flush = async (say: string) => {
    const clean = stripDashes(say);
    if (clean === lastFlushed) return;
    lastFlushed = clean;
    await opts.onSayDelta!(clean);
  };

  try {
    // toTextStream() returns a web ReadableStream at runtime; the Convex TS lib
    // doesn't surface getReader on the type, so narrow it to what we use.
    const textStream = result.toTextStream() as unknown as {
      getReader(): { read(): Promise<{ done: boolean; value?: string }> };
    };
    const reader = textStream.getReader();
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      if (!value) continue;
      buffer += value;
      if (!announcedWriting) {
        announcedWriting = true;
        await report(opts.onStep, "Writing it up...");
      }
      const say = extractPartialSay(buffer);
      // Throttle to ~10 writes/sec so we don't spam mutations per token.
      if (say !== null && say !== lastFlushed && Date.now() - lastFlushAt >= 90) {
        lastFlushAt = Date.now();
        await flush(say);
      }
    }
  } catch {
    // Streaming is best-effort; the final output below is the source of truth.
  }

  await result.completed;
  const finalSay = extractPartialSay(buffer);
  if (finalSay) await flush(finalSay);
  return result.finalOutput ?? null;
}

// Pull the (possibly partial) value of the top-level "say" string out of a JSON
// buffer that's still being streamed. Returns the decoded string so far, or null
// if the key/opening quote hasn't arrived yet. Tolerant of incomplete escapes.
function extractPartialSay(buffer: string): string | null {
  const keyIdx = buffer.indexOf('"say"');
  if (keyIdx === -1) return null;
  let i = keyIdx + 5;
  while (i < buffer.length && buffer[i] !== ":") i++;
  i++; // past ':'
  while (i < buffer.length && /\s/.test(buffer[i])) i++;
  if (buffer[i] !== '"') return null;
  i++; // past opening quote

  let out = "";
  while (i < buffer.length) {
    const c = buffer[i];
    if (c === "\\") {
      const next = buffer[i + 1];
      if (next === undefined) break; // incomplete escape — stop here
      switch (next) {
        case "n": out += "\n"; break;
        case "t": out += "\t"; break;
        case "r": out += "\r"; break;
        case "b": out += "\b"; break;
        case "f": out += "\f"; break;
        case '"': out += '"'; break;
        case "\\": out += "\\"; break;
        case "/": out += "/"; break;
        case "u": {
          const hex = buffer.slice(i + 2, i + 6);
          if (hex.length < 4) return out; // incomplete unicode — stop here
          out += String.fromCharCode(parseInt(hex, 16));
          i += 4;
          break;
        }
        default: out += next;
      }
      i += 2;
      continue;
    }
    if (c === '"') return out; // closing quote — say is complete
    out += c;
    i++;
  }
  return out; // string not yet closed — partial
}

export type { AgentInputItem };
