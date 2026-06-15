"use client";

import { useState } from "react";
import { Search, ArrowUpRight, Plus, X, SunMedium, Moon } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Toggle } from "@/components/ui/toggle";
import { cn } from "@/lib/utils";

/* solid icons (used inside buttons / frames) */
function StarSolid({ className }: { className?: string }) {
  return <svg viewBox="0 0 16 16" className={className} aria-hidden><path fill="currentColor" d="M8 1l1.9 4 4.1.6-3 2.9.7 4L8 10.6 4.3 12.5l.7-4-3-2.9 4.1-.6z" /></svg>;
}
function PlusSolid({ className }: { className?: string }) {
  return <svg viewBox="0 0 16 16" className={className} aria-hidden><path fill="currentColor" d="M7 7V2h2v5h5v2H9v5H7V9H2V7z" /></svg>;
}
function GridSolid({ className }: { className?: string }) {
  return <svg viewBox="0 0 16 16" className={className} aria-hidden><path fill="currentColor" d="M2 3a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1H3a1 1 0 01-1-1zm6 6a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1H9a1 1 0 01-1-1z" /></svg>;
}

type Status = "open" | "matched" | "resolved";
const STATUS_FG: Record<Status, string> = { open: "var(--open-fg)", matched: "var(--matched-fg)", resolved: "var(--resolved-fg)" };

function StatusPill({ status, count }: { status: Status; count?: number }) {
  const label = status[0].toUpperCase() + status.slice(1);
  return (
    <Badge variant={status} className="h-6 gap-1.5 px-2.5 text-xs">
      <span className="size-1.5 rounded-full" style={{ background: STATUS_FG[status] }} />
      {label}{count != null ? ` ${count}` : ""}
    </Badge>
  );
}

function MetricTile({ label, value, delta, src }: { label: string; value: string; delta?: string; src: string }) {
  return (
    <Card className="gap-0 py-5">
      <div className="px-5">
        <div className="text-xs text-muted-foreground">{label}</div>
        <div className="mt-1.5 flex items-baseline gap-2">
          <span className="text-3xl font-bold tracking-tight tabular-nums">{value}</span>
          {delta && <span className="text-xs font-semibold" style={{ color: "var(--resolved-fg)" }}>{delta}</span>}
        </div>
        <button className="mt-2.5 inline-flex items-center gap-1 text-[11px] text-muted-foreground transition-colors hover:text-foreground">
          {src} <ArrowUpRight className="size-3" />
        </button>
      </div>
    </Card>
  );
}

function PersonRow({ initials, name, meta, strength }: { initials: string; name: string; meta: string; strength: string }) {
  return (
    <div className="flex items-center gap-3 border-b border-border px-3 py-4 last:border-0">
      <Avatar className="size-11"><AvatarFallback className="text-base">{initials}</AvatarFallback></Avatar>
      <div className="min-w-0 flex-1">
        <div className="text-sm font-semibold">{name}</div>
        <div className="text-xs text-muted-foreground">{meta}</div>
      </div>
      <span className="text-[11px] font-semibold" style={{ color: strength === "New" ? "var(--muted-foreground)" : "var(--resolved-fg)" }}>{strength}</span>
    </div>
  );
}

function AskRow({ status, text, meta }: { status: Status; text: string; meta: string }) {
  return (
    <div className="flex items-center gap-3 border-b border-border px-3 py-4 last:border-0">
      <span className="size-2 shrink-0 rounded-full" style={{ background: STATUS_FG[status] }} />
      <div className="min-w-0 flex-1">
        <div className="text-sm">{text}</div>
        <div className="mt-0.5 text-xs text-muted-foreground">{meta}</div>
      </div>
      <StatusPill status={status} />
    </div>
  );
}

const NODES: [number, number, number, number][] = [
  [120, 160, 16, 0], [210, 90, 9, 0], [195, 235, 10, 1], [300, 150, 22, 1],
  [400, 80, 11, 2], [430, 220, 9, 2], [520, 150, 14, 0], [360, 250, 7, 3],
  [610, 90, 10, 1], [640, 210, 13, 2], [730, 150, 18, 1], [820, 90, 9, 0],
  [840, 230, 8, 3], [930, 160, 12, 2], [700, 260, 7, 3], [260, 300, 7, 3],
  [980, 100, 9, 1], [540, 40, 7, 0],
];
const EDGES: [number, number][] = [
  [0, 1], [0, 2], [2, 3], [3, 4], [3, 5], [4, 6], [5, 7], [3, 7], [1, 3],
  [6, 8], [6, 9], [8, 10], [9, 10], [10, 11], [10, 12], [11, 13], [12, 13],
  [13, 16], [10, 14], [9, 14], [0, 15], [2, 15], [4, 17], [6, 10],
];
const CO = ["--co-accel", "--co-cat", "--co-raikes", "--co-other"];
const COHORT_LABELS = [["Accelerator", "--co-accel"], ["Catalyst", "--co-cat"], ["Raikes", "--co-raikes"], ["Unaffiliated", "--co-other"]];

function ConnectionGraph() {
  return (
    <Card className="gap-0 p-0 py-0">
      <div className="flex flex-wrap gap-4 px-4 pt-3">
        {COHORT_LABELS.map(([label, v]) => (
          <span key={label} className="inline-flex items-center gap-1.5 text-xs text-muted-foreground">
            <span className="size-2.5 rounded-full" style={{ background: `var(${v})` }} />{label}
          </span>
        ))}
      </div>
      <svg viewBox="0 0 1100 320" className="h-[340px] w-full" preserveAspectRatio="xMidYMid meet">
        <g opacity={0.85}>{EDGES.map(([a, b], i) => (
          <line key={i} x1={NODES[a][0]} y1={NODES[a][1]} x2={NODES[b][0]} y2={NODES[b][1]} stroke="var(--border)" strokeWidth={1.4} />
        ))}</g>
        {NODES.map(([x, y, r, c], i) => <circle key={i} cx={x} cy={y} r={r} fill={`var(${CO[c]})`} />)}
      </svg>
    </Card>
  );
}

function Section({ title, children, full }: { title: string; children: React.ReactNode; full?: boolean }) {
  return (
    <section className="mb-12">
      <h2 className="mb-4 text-xs font-semibold uppercase tracking-[0.1em] text-muted-foreground">{title}</h2>
      <div className={full ? "" : "max-w-3xl"}>{children}</div>
    </section>
  );
}

function AiComposer({ value = "", className }: { value?: string; className?: string }) {
  return (
    <div className={cn("relative", className)}>
      <span className="absolute left-2 top-1/2 flex size-8 -translate-y-1/2 items-center justify-center rounded-full bg-white dark:bg-[#3a3a3a]">
        <StarSolid className="size-5 text-foreground" />
      </span>
      <Input defaultValue={value} placeholder="Ask any question…" className="h-12 rounded-full bg-[#e5e5e5] pl-12 text-[16px] dark:bg-[#262626]" />
    </div>
  );
}

export default function ComponentsPage() {
  const [dark, setDark] = useState(false);
  const [chips, setChips] = useState<Record<string, boolean>>({ Cofounder: true, Designer: false });
  const [improve, setImprove] = useState<Record<string, boolean>>({ "More time": true, "Smaller group": false });
  const setMode = (d: boolean) => { setDark(d); document.documentElement.classList.toggle("dark", d); };

  return (
    <div className="min-h-screen bg-background text-foreground">
      <header className="sticky top-0 z-10 flex items-center gap-3 border-b border-border bg-background px-7 py-4">
        <span className="text-xl font-extrabold tracking-tight" style={{ fontFamily: "var(--font-display)" }}>Junto</span>
        <span className="text-xs text-muted-foreground">Component Canvas · UNL</span>
        <div className="flex-1" />
        <div className="inline-flex rounded-full border border-border p-0.5">
          <button onClick={() => setMode(false)} className={cn("inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-semibold", !dark ? "bg-primary text-primary-foreground" : "text-muted-foreground")}><SunMedium className="size-3.5" /> Light</button>
          <button onClick={() => setMode(true)} className={cn("inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-semibold", dark ? "bg-primary text-primary-foreground" : "text-muted-foreground")}><Moon className="size-3.5" /> Dark</button>
        </div>
      </header>

      <main className="mx-auto max-w-5xl px-7 py-10">
        {/* Buttons */}
        <Section title="Buttons">
          <div className="flex flex-wrap items-center gap-3">
            <Button size="pill"><StarSolid className="size-4" /> Generate report</Button>
            <Button size="pill" variant="outline">Ask anything</Button>
            <Button size="pill" variant="ghost">View all</Button>
            <Button size="icon" variant="ghost" className="size-10 rounded-full bg-muted active:scale-[0.9]"><GridSolid className="size-[18px]" /></Button>
            <Button size="fab"><PlusSolid className="size-5" /></Button>
          </div>
          <div className="mt-3 flex flex-wrap items-center gap-3">
            <Button className="px-5">Connect</Button>
            <Button variant="outline" className="px-5 text-muted-foreground">Connected</Button>
          </div>
          <p className="mt-3 text-xs text-muted-foreground">All shadcn <code>Button</code>. Primary CTA = <code>size=&quot;pill&quot;</code> (53px). Connect = default (8px). Icon = circle. <code>size=&quot;fab&quot;</code> = 16px. Press-scale baked into the primitive.</p>
        </Section>

        {/* Ask Junto AI input */}
        <Section title="Ask Junto · AI input">
          <AiComposer className="max-w-xl" />
          <p className="mt-3 text-xs text-muted-foreground">A shadcn <code>Input</code> (now filled, borderless) styled as the composer: capsule, grey fill, Junto mark on the left, <b>no send button</b> (Return sends).</p>
        </Section>

        {/* Inputs */}
        <Section title="Inputs (filled, no border, 53px)">
          <div className="flex flex-wrap items-end gap-4">
            <div>
              <Label className="mb-2 block text-[15px] font-semibold">Search students</Label>
              <div className="relative w-80">
                <Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
                <Input placeholder="Name, major, skill…" className="pl-9 text-[16px]" />
              </div>
            </div>
            <div className="relative w-64">
              <Search className="absolute left-3.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
              <Input placeholder="Search" className="h-[37px] rounded-full bg-muted pl-9 text-[15px]" />
            </div>
          </div>
          <p className="mt-3 text-xs text-muted-foreground">shadcn <code>Input</code>, edited to be filled + borderless + 16px radius. Search bar = same Input, capsule + 37px.</p>
        </Section>

        {/* Chips / tags / status */}
        <Section title="Chips · Tags · Status">
          <div className="mb-4 flex flex-wrap items-center gap-3">
            <span className="inline-flex items-center gap-1.5 text-sm text-muted-foreground"><span className="size-1.5 rounded-full bg-muted-foreground" /> Software</span>
            <Badge variant="outline" className="h-8 gap-2 rounded-xl px-3 text-sm font-medium"><span className="size-2.5 rounded-full" style={{ background: "var(--co-cat)" }} /> Design</Badge>
            {(["Cofounder", "Designer"] as const).map((c) => (
              <Toggle key={c} pressed={chips[c]} onPressedChange={(v) => setChips((s) => ({ ...s, [c]: v }))}
                className="h-auto gap-1.5 rounded-2xl bg-input px-3 py-2 text-[15px] font-medium aria-pressed:scale-[1.03] aria-pressed:bg-primary aria-pressed:text-primary-foreground">
                {c}{chips[c] ? <X className="size-3" /> : <Plus className="size-3 -rotate-45" />}
              </Toggle>
            ))}
          </div>
          <div className="mb-4 flex flex-wrap items-center gap-3">
            <Badge variant="matched" className="h-7 px-2.5 text-xs">Looking For</Badge>
            {(["More time", "Smaller group"] as const).map((c) => (
              <Toggle key={c} variant="outline" pressed={improve[c]} onPressedChange={(v) => setImprove((s) => ({ ...s, [c]: v }))}
                className="h-auto rounded-full px-3 py-2 text-sm font-medium aria-pressed:border-transparent aria-pressed:bg-primary aria-pressed:text-primary-foreground">
                {c}
              </Toggle>
            ))}
          </div>
          <div className="flex flex-wrap gap-2.5">
            <StatusPill status="open" count={24} />
            <StatusPill status="matched" count={11} />
            <StatusPill status="resolved" count={7} />
          </div>
          <p className="mt-3 text-xs text-muted-foreground">TopicTag (text) · CategoryChip (<code>Badge</code> outline) · SelectableChip + FeedbackChip (<code>Toggle</code>) · status pills (<code>Badge</code> variants open/matched/resolved).</p>
        </Section>

        {/* Cohort lens */}
        <Section title="Cohort lens (global filter)">
          <Tabs defaultValue="All">
            <TabsList className="rounded-full">
              {["All", "Accelerator", "Catalyst", "Raikes"].map((t) => (
                <TabsTrigger key={t} value={t} className="rounded-full px-4">{t}</TabsTrigger>
              ))}
            </TabsList>
          </Tabs>
          <p className="mt-3 text-xs text-muted-foreground">shadcn <code>Tabs</code> as the pill segmented control.</p>
        </Section>

        {/* Verdict + metrics */}
        <Section title="Verdict + Metric tiles" full>
          <Card className="mb-4 max-w-3xl gap-0 py-5">
            <div className="px-5">
              <div className="text-[13px] text-muted-foreground">Your ecosystem is growing</div>
              <div className="mt-1 flex items-baseline gap-2.5">
                <span className="text-4xl font-bold tracking-tight tabular-nums">318</span>
                <span className="text-sm font-semibold" style={{ color: "var(--resolved-fg)" }}>+12% this month</span>
              </div>
            </div>
          </Card>
          <div className="grid max-w-4xl grid-cols-2 gap-4 md:grid-cols-4">
            <MetricTile label="Students active" value="142" src="59% of cohort" />
            <MetricTile label="Cross-discipline" value="61%" delta="+5%" src="view 38 bridges" />
            <MetricTile label="Connected wk 1" value="73%" src="of newcomers" />
            <MetricTile label="Event attendance" value="208" src="across 4 events" />
          </div>
        </Section>

        {/* The Map */}
        <Section title="The Map · connection graph (the hero)" full>
          <ConnectionGraph />
        </Section>

        {/* Lists */}
        <Section title="Lists · flat rows + dividers" full>
          <div className="grid gap-6 lg:grid-cols-2">
            <div>
              <Card className="gap-0 p-0 py-0">
                <PersonRow initials="MR" name="Maya Rodriguez" meta="CS · connected to 9 · via Pitch Night" strength="Strong" />
                <PersonRow initials="JT" name="Justin Tran" meta="Business · connected to 4 · via daily match" strength="New" />
                <PersonRow initials="PK" name="Priya Kapoor" meta="Design · connected to 6 · via a post" strength="Strong" />
              </Card>
            </div>
            <div>
              <Card className="gap-0 p-0 py-0">
                <AskRow status="open" text="Need a React dev for my climate app" meta="Dev · Maya R. · 2h" />
                <AskRow status="matched" text="Looking for a cofounder, B2B SaaS" meta="Cofounder · Justin T. · 5h" />
                <AskRow status="resolved" text="Need a logo before launch" meta="Design · Priya K. · 1d" />
              </Card>
            </div>
          </div>
        </Section>

        {/* Message bubbles */}
        <Section title="Message bubbles (18px)">
          <div className="max-w-md space-y-2">
            <div className="flex justify-end"><div className="max-w-[80%] rounded-[18px] bg-primary px-4 py-3 text-[16px] text-primary-foreground">Can you intro me to a designer?</div></div>
            <div className="flex justify-start"><div className="max-w-[80%] rounded-[18px] bg-muted px-4 py-3 text-[16px] text-foreground">Maya Rodriguez is a great fit — she&apos;s done 3 student projects.</div></div>
          </div>
        </Section>

        {/* Ask anything (answer + sources) */}
        <Section title="Ask anything (answer + sources)">
          <Card className="gap-0 py-5">
            <div className="px-5">
              <AiComposer value="How many first-gen students connected this month?" />
              <div className="mt-3 text-[15px] leading-relaxed"><span className="font-bold">23 first-gen students</span> made at least one connection this month, up from 14 in February.</div>
              <div className="mt-3 flex flex-wrap gap-2">
                {["connections · 23 rows", "filter: first-gen", "window: this month"].map((s) => (
                  <Badge key={s} variant="outline" className="rounded-lg text-[11px] font-normal text-muted-foreground">{s}</Badge>
                ))}
              </div>
            </div>
          </Card>
        </Section>

        {/* Empty + skeleton */}
        <Section title="Empty state + Skeleton" full>
          <div className="grid max-w-3xl gap-6 lg:grid-cols-2">
            <Card className="gap-0 py-10">
              <div className="flex flex-col items-center px-5 text-center">
                <Search className="size-12 text-muted-foreground" strokeWidth={1.4} />
                <div className="mt-3.5 text-lg">No asks yet this week</div>
                <div className="mt-1.5 text-sm text-muted-foreground">When students post a need, it shows up here ready to triage.</div>
              </div>
            </Card>
            <Card className="gap-0 py-5">
              <div className="px-5">
                <div className="mb-3.5 flex items-center gap-3">
                  <Skeleton className="size-11 rounded-full" />
                  <div className="flex-1"><Skeleton className="mb-2 h-3 w-28" /><Skeleton className="h-2.5 w-20" /></div>
                </div>
                <Skeleton className="mb-2 h-3 w-full" />
                <Skeleton className="h-3 w-2/3" />
              </div>
            </Card>
          </div>
        </Section>
      </main>
    </div>
  );
}
