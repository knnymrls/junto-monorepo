/**
 * Interactive Ask Junto REPL — talk to the real agent from the terminal.
 *
 *   pnpm --filter @junto/backend ask              # interactive chat
 *   pnpm --filter @junto/backend ask "your msg"   # one-shot
 *
 * Runs the actual OpenAI Agents SDK with a fake-but-realistic campus, so you can
 * feel the agent + blocks without needing Convex, iOS, or real data. Conversation
 * memory persists across turns via an in-memory SDK Session.
 */

import readline from "node:readline";
import { runAskJunto, type AskJuntoTools } from "../convex/askJuntoAgent";
import { AskJuntoOutputSchema, InMemoryItemStore, type Block } from "../convex/askJuntoCore";

// ── Fake campus ────────────────────────────────────────────────────────────
const PEOPLE = [
  { userId: "u_maya", label: "Product designer, into app projects" },
  { userId: "u_devin", label: "UI/UX + Figma, freelances" },
  { userId: "u_sofia", label: "Brand + visual design" },
  { userId: "u_marcus", label: "Video/motion, building a reel" },
  { userId: "u_priya", label: "Backend dev, APIs + databases" },
  { userId: "u_jordan", label: "Filmmaker, shoots short docs" },
  { userId: "u_alex", label: "Growth marketing, ran a campus brand" },
];
const EVENTS = [
  { eventId: "e_pitch", title: "Open Pitch Night", startsAt: Date.now() + 86400000 },
  { eventId: "e_hack", title: "HackUNL Weekend", startsAt: Date.now() + 3 * 86400000 },
  { eventId: "e_coffee", title: "Founders Coffee w/ NMotion", startsAt: Date.now() + 2 * 86400000 },
];

const tools: AskJuntoTools = {
  findPeople: async (need, limit) => {
    // naive keyword bias so results feel responsive to the query
    const n = need.toLowerCase();
    const scored = PEOPLE.map((p) => ({
      p,
      hit: p.label.toLowerCase().split(/\W+/).some((w) => w && n.includes(w)) ? 1 : 0,
    }));
    return scored.sort((a, b) => b.hit - a.hit).slice(0, Math.max(1, limit)).map((s) => s.p);
  },
  findOpportunities: async (_interest, limit) => EVENTS.slice(0, Math.max(1, limit)),
  getMyContext: async () => ({
    name: "You",
    headline: "CS major building a study app",
    skills: ["engineering"],
    lookingFor: "a designer to fix my UI",
    canHelpWith: "backend / iOS",
  }),
};

// ── Pretty printer ─────────────────────────────────────────────────────────
const c = {
  dim: (s: string) => `\x1b[2m${s}\x1b[0m`,
  bold: (s: string) => `\x1b[1m${s}\x1b[0m`,
  cyan: (s: string) => `\x1b[36m${s}\x1b[0m`,
  green: (s: string) => `\x1b[32m${s}\x1b[0m`,
  yellow: (s: string) => `\x1b[33m${s}\x1b[0m`,
  magenta: (s: string) => `\x1b[35m${s}\x1b[0m`,
};

function printBlock(b: Block) {
  switch (b.type) {
    case "people":
      console.log("  " + c.cyan("◇ people"));
      b.userIds.forEach((id) => {
        const label = PEOPLE.find((p) => p.userId === id)?.label ?? "";
        console.log("    • " + c.bold(id) + (label ? c.dim("  " + label) : ""));
      });
      if (b.note) console.log("    " + c.dim(b.note));
      return;
    case "opportunities":
      console.log("  " + c.magenta("◇ opportunities"));
      b.eventIds.forEach((id) => {
        const title = EVENTS.find((e) => e.eventId === id)?.title ?? id;
        console.log("    • " + c.bold(title) + c.dim("  " + id));
      });
      if (b.note) console.log("    " + c.dim(b.note));
      return;
    case "draftAsk":
      console.log("  " + c.yellow("◇ draft ask") + "  " + c.bold(b.title));
      return console.log("    " + b.body);
    case "draftIntro":
      console.log("  " + c.yellow("◇ draft intro") + c.dim(" → " + b.targetUserId));
      return console.log("    " + b.message);
    case "action":
      return console.log("  " + c.green("◇ action") + `  [${b.kind}] ${b.label}`);
  }
}

async function ask(message: string, store: InMemoryItemStore) {
  process.stdout.write(c.dim("  thinking…\n"));
  const output = await runAskJunto({ tools, store, message });
  const parsed = AskJuntoOutputSchema.safeParse(output);
  if (!parsed.success) {
    console.log(c.dim("  (agent returned an unparseable response)"));
    return;
  }
  console.log();
  if (parsed.data.say) console.log("  " + parsed.data.say);
  if (parsed.data.show) printBlock(parsed.data.show);
  if (parsed.data.followUp) console.log("\n  " + c.cyan("↻ " + parsed.data.followUp));
  const intent = parsed.data.intent;
  console.log(
    "\n  " +
      c.dim(
        intent.isNeed
          ? `↳ signal: [${intent.category}] "${intent.need}"  → goes to the UNL dashboard`
          : "↳ no campus need flagged this turn"
      ) +
      "\n"
  );
}

async function main() {
  if (!process.env.OPENAI_API_KEY) {
    console.error(c.yellow("OPENAI_API_KEY not set in this shell. export it and retry."));
    process.exit(1);
  }

  const store = new InMemoryItemStore();
  const oneShot = process.argv.slice(2).join(" ").trim();
  if (oneShot) {
    await ask(oneShot, store);
    return;
  }

  console.log(c.bold("\n  Ask Junto") + c.dim("  — real agent, fake campus. Ctrl+C to quit.\n"));
  console.log(c.dim('  try: "I need a designer for my app" · "what\'s happening this week" · "find me a cofounder"\n'));

  const rl = readline.createInterface({ input: process.stdin, output: process.stdout, prompt: c.green("you ▸ ") });
  rl.prompt();
  rl.on("line", async (line) => {
    const msg = line.trim();
    if (!msg) return rl.prompt();
    rl.pause();
    try {
      await ask(msg, store);
    } catch (e) {
      console.error(c.yellow("  error: " + (e as Error).message));
    }
    rl.resume();
    rl.prompt();
  });
}

main();
