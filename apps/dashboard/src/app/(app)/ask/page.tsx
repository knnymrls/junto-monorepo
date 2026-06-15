"use client";

import { useState } from "react";
import { ArrowUp, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useDash } from "@/hooks/use-dash";

type Report = {
  members: number;
  connections: number;
  pctConnected: number;
  deeplyEngaged: number;
  crossDiscipline: number;
  crossPct: number;
  disciplines: { name: string; count: number }[];
  events: number;
  attendance: number;
};

const SUGGESTIONS = [
  "How many connections are cross-discipline?",
  "How many students have three or more connections?",
  "Which disciplines are biggest?",
  "How many students have we engaged?",
];

type Turn = { q: string; a: string; grounded: boolean };

function answer(q: string, d: Report): { a: string; grounded: boolean } {
  const s = q.toLowerCase();
  if (/(cross|discipline.*bridge|bridge)/.test(s) && /(connect|bridge|cross)/.test(s))
    return { a: `${d.crossPct}% of connections (${d.crossDiscipline} of ${d.connections}) bridge different disciplines.`, grounded: true };
  if (/(three|3\+|3 or more|deeply|lasting)/.test(s))
    return { a: `${d.deeplyEngaged} students have built three or more connections, the point where the network sticks.`, grounded: true };
  if (/discipline|major|college|field/.test(s)) {
    const top = d.disciplines.slice(0, 4).map((x) => `${x.name} (${x.count})`).join(", ");
    return { a: `Biggest disciplines: ${top || "no data yet"}.`, grounded: true };
  }
  if (/event|attend|rsvp|turnout/.test(s))
    return { a: `${d.events} events held, ${d.attendance} total check-ins.`, grounded: true };
  if (/engage|how many students|active|members|joined/.test(s))
    return { a: `${d.members} students engaged. ${d.pctConnected}% have connected with at least one other, ${d.deeplyEngaged} have three or more.`, grounded: true };
  return {
    a: "I can answer that from your live data once the natural-language layer is wired (the next build). For now, try one of the suggested questions, which read straight from the graph.",
    grounded: false,
  };
}

export default function AskPage() {
  const d = useDash<Report>("center:report");
  const [input, setInput] = useState("");
  const [turns, setTurns] = useState<Turn[]>([]);

  function submit(q: string) {
    const query = q.trim();
    if (!query || !d) return;
    const { a, grounded } = answer(query, d);
    setTurns((t) => [...t, { q: query, a, grounded }]);
    setInput("");
  }

  return (
    <div className="mx-auto flex h-full w-full max-w-2xl flex-col">
      <div className="flex flex-1 flex-col justify-end gap-6 overflow-y-auto pb-6">
        {turns.length === 0 ? (
          <div className="flex flex-col items-center gap-3 py-10 text-center">
            <span className="flex size-11 items-center justify-center rounded-full bg-muted">
              <Sparkles className="size-5 text-muted-foreground" />
            </span>
            <h1 className="text-xl font-semibold tracking-tight">Ask anything about your ecosystem</h1>
            <p className="max-w-md text-sm text-muted-foreground">
              Plain-English questions over your live data, so you are never caught not knowing the number.
            </p>
          </div>
        ) : (
          turns.map((t, i) => (
            <div key={i} className="flex flex-col gap-3">
              <p className="self-end max-w-[80%] rounded-2xl bg-primary px-4 py-2.5 text-sm text-primary-foreground">{t.q}</p>
              <div className="max-w-[85%] self-start">
                <p className="rounded-2xl bg-muted px-4 py-2.5 text-sm">{t.a}</p>
                {t.grounded && <p className="mt-1 px-1 text-xs text-muted-foreground">from your live data</p>}
              </div>
            </div>
          ))
        )}
      </div>

      <div className="flex flex-col gap-3 pb-2">
        <div className="flex flex-wrap gap-2">
          {SUGGESTIONS.map((s) => (
            <button
              key={s}
              onClick={() => submit(s)}
              className="rounded-full border border-border px-3 py-1.5 text-xs text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
            >
              {s}
            </button>
          ))}
        </div>

        <form
          onSubmit={(e) => {
            e.preventDefault();
            submit(input);
          }}
          className="flex items-center gap-2 rounded-full bg-muted py-2 pr-2 pl-3"
        >
          <Sparkles className="size-4 shrink-0 text-muted-foreground" />
          <input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Ask any question…"
            className="min-w-0 flex-1 bg-transparent text-sm outline-none placeholder:text-muted-foreground"
          />
          <Button type="submit" size="icon-sm" className="shrink-0 rounded-full" disabled={!input.trim()}>
            <ArrowUp className="size-4" />
          </Button>
        </form>
      </div>
    </div>
  );
}
