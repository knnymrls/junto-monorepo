import { query } from "./_generated/server";
import type { Doc, Id } from "./_generated/dataModel";

// =====================================================================
// center.ts — queries for the Junto university web app (apps/dashboard).
// Built from scratch for the "Briefing" home; reads the real shared
// tables (users, connections, posts, events, askJuntoSignals). This is
// NOT the retired mkrs.world dashboard (dashboard.ts) — do not use that.
// =====================================================================

const DAY = 24 * 60 * 60 * 1000;
const WEEK = 7 * DAY;

async function onboarded(ctx: { db: any }): Promise<Doc<"users">[]> {
  const all = await ctx.db.query("users").collect();
  return all.filter((u: Doc<"users">) => u.isOnboarded);
}

async function connected(ctx: { db: any }): Promise<Doc<"connections">[]> {
  const all = await ctx.db.query("connections").collect();
  return all.filter((c: Doc<"connections">) => c.status === "connected");
}

function degrees(conns: Doc<"connections">[]): Map<string, number> {
  const m = new Map<string, number>();
  for (const c of conns) {
    m.set(c.requesterId, (m.get(c.requesterId) ?? 0) + 1);
    m.set(c.accepterId, (m.get(c.accepterId) ?? 0) + 1);
  }
  return m;
}

// ------------------------------------------------------------------
// briefing — the verdict numbers at the top of Home.
// ------------------------------------------------------------------
export const briefing = query({
  args: {},
  handler: async (ctx) => {
    const now = Date.now();
    const users = await onboarded(ctx);
    const conns = await connected(ctx);
    const deg = degrees(conns);

    const members = users.length;
    const connections = conns.length;
    const hasConnected = users.filter((u) => (deg.get(u._id) ?? 0) >= 1).length;
    const deeplyEngaged = users.filter((u) => (deg.get(u._id) ?? 0) >= 3).length; // "3 connections = value"
    const pctConnected = members ? Math.round((hasConnected / members) * 100) : 0;
    const newConnectionsThisWeek = conns.filter(
      (c) => (c.connectedAt ?? c.createdAt) >= now - WEEK
    ).length;
    const newMembersThisWeek = users.filter((u) => u.createdAt >= now - WEEK).length;

    // cross-discipline: a connection where the two students share no skill category
    const catOf = new Map<string, Set<string>>(
      users.map((u) => [u._id, new Set(u.skillCategories ?? [])])
    );
    let crossDiscipline = 0;
    for (const c of conns) {
      const a = catOf.get(c.requesterId);
      const b = catOf.get(c.accepterId);
      if (a && b && a.size && b.size) {
        let shared = false;
        for (const x of a) if (b.has(x)) { shared = true; break; }
        if (!shared) crossDiscipline++;
      }
    }

    const events = (await ctx.db.query("events").collect()).length;

    return {
      members,
      connections,
      hasConnected,
      pctConnected,
      deeplyEngaged,
      newConnectionsThisWeek,
      newMembersThisWeek,
      crossDiscipline,
      events,
    };
  },
});

// ------------------------------------------------------------------
// activity — the real "what happened" feed (most recent, mixed).
// ------------------------------------------------------------------
type Feed =
  | { kind: "connection"; ts: number; source: string; aName: string; aAvatar: string | null; bName: string; bAvatar: string | null }
  | { kind: "join" | "post" | "rsvp"; ts: number; source: string; title: string; aName: string; aAvatar: string | null };

export const activity = query({
  args: {},
  handler: async (ctx): Promise<Feed[]> => {
    const items: Feed[] = [];

    const conns = (await connected(ctx))
      .sort((a, b) => (b.connectedAt ?? b.createdAt) - (a.connectedAt ?? a.createdAt))
      .slice(0, 12);
    for (const c of conns) {
      const a = await ctx.db.get(c.requesterId);
      const b = await ctx.db.get(c.accepterId);
      if (!a || !b) continue;
      items.push({
        kind: "connection",
        ts: c.connectedAt ?? c.createdAt,
        source: c.source?.label ?? "connected",
        aName: a.name, aAvatar: a.avatarUrl ?? null,
        bName: b.name, bAvatar: b.avatarUrl ?? null,
      });
    }

    const posts = await ctx.db.query("posts").withIndex("by_created").order("desc").take(12);
    for (const p of posts) {
      if (p.category === "sharing") continue;
      const a = await ctx.db.get(p.authorId);
      if (!a) continue;
      const preview = p.content.length > 64 ? p.content.slice(0, 64) + "…" : p.content;
      items.push({
        kind: "post",
        ts: p.createdAt,
        source: p.category === "asking" ? "Ask" : "Looking for",
        title: `${a.name}: “${preview}”`,
        aName: a.name, aAvatar: a.avatarUrl ?? null,
      });
    }

    const recentUsers = (await ctx.db.query("users").order("desc").take(10)).filter(
      (u: Doc<"users">) => u.isOnboarded
    );
    for (const u of recentUsers) {
      items.push({ kind: "join", ts: u.createdAt, source: "New member", title: `${u.name} joined`, aName: u.name, aAvatar: u.avatarUrl ?? null });
    }

    const rsvps = await ctx.db.query("eventRsvps").order("desc").take(15);
    for (const r of rsvps) {
      if (r.status !== "going") continue;
      const u = await ctx.db.get(r.userId);
      const e = await ctx.db.get(r.eventId);
      if (!u || !e) continue;
      items.push({ kind: "rsvp", ts: r.createdAt, source: "RSVP", title: `${u.name} is going to ${e.title}`, aName: u.name, aAvatar: u.avatarUrl ?? null });
    }

    items.sort((a, b) => b.ts - a.ts);
    return items.slice(0, 8);
  },
});

// ------------------------------------------------------------------
// network — the real connection graph for the Home map sliver.
// Nodes carry degree so the sliver can size by connector/broker.
// ------------------------------------------------------------------
export const network = query({
  args: {},
  handler: async (ctx) => {
    const users = await onboarded(ctx);
    const conns = await connected(ctx);
    const deg = degrees(conns);
    const groupOf = new Map<string, string>(
      users.map((u) => [u._id, u.skillCategories?.[0] ?? "Other"])
    );
    return {
      nodes: users.map((u) => ({
        id: u._id as string,
        degree: deg.get(u._id) ?? 0,
        group: groupOf.get(u._id) ?? "Other",
        name: u.name,
        avatar: u.avatarUrl ?? null,
      })),
      edges: conns.map((c) => ({
        source: c.requesterId as string,
        target: c.accepterId as string,
        cross: groupOf.get(c.requesterId) !== groupOf.get(c.accepterId),
      })),
      totalMembers: users.length,
      totalConnections: conns.length,
    };
  },
});

// ------------------------------------------------------------------
// needs — "what needs you": the few human actions only Amanda can do.
// ------------------------------------------------------------------
export const needs = query({
  args: {},
  handler: async (ctx) => {
    const now = Date.now();
    const users = await onboarded(ctx);
    const conns = await connected(ctx);
    const deg = degrees(conns);

    const out: { key: string; title: string; desc: string; action: string }[] = [];

    // 1. Isolated students (no connections yet)
    const isolated = users.filter((u) => (deg.get(u._id) ?? 0) === 0);
    const isolatedRecent = isolated.filter((u) => u.createdAt >= now - 30 * DAY);
    if (isolated.length) {
      out.push({
        key: "isolated",
        title: `${isolated.length} student${isolated.length > 1 ? "s" : ""} with no connections yet`,
        desc: isolatedRecent.length ? `${isolatedRecent.length} joined in the last month` : "help them meet someone",
        action: "Invite",
      });
    }

    // 2. Top open student need (the "if one asks, five have it" signal)
    const signals = await ctx.db.query("askJuntoSignals").collect();
    const open = signals.filter((s: Doc<"askJuntoSignals">) => s.status === "open");
    if (open.length) {
      const byCat = new Map<string, number>();
      for (const s of open) byCat.set(s.category, (byCat.get(s.category) ?? 0) + 1);
      const [cat, n] = [...byCat.entries()].sort((a, b) => b[1] - a[1])[0];
      out.push({ key: "need", title: `${n} student${n > 1 ? "s" : ""} asking about ${cat}`, desc: "recurring need this term", action: "Match" });
    } else {
      const posts = await ctx.db.query("posts").withIndex("by_created").order("desc").take(40);
      const asks = posts.filter((p: Doc<"posts">) => p.category === "looking_for" || p.category === "asking");
      if (asks.length) out.push({ key: "need", title: `${asks.length} open ask${asks.length > 1 ? "s" : ""} this month`, desc: "students looking for help", action: "Review" });
    }

    // 3. Students who haven't posted yet (activation nudge)
    const authors = new Set((await ctx.db.query("posts").collect()).map((p: Doc<"posts">) => p.authorId as string));
    const silent = users.filter((u) => !authors.has(u._id)).length;
    if (silent) out.push({ key: "silent", title: `${silent} student${silent > 1 ? "s" : ""} haven’t posted yet`, desc: "never shared an update or ask", action: "Nudge" });

    // 4. Next upcoming event
    const events = (await ctx.db.query("events").withIndex("by_date").collect())
      .filter((e: Doc<"events">) => e.date >= now)
      .sort((a: Doc<"events">, b: Doc<"events">) => a.date - b.date);
    if (events.length) {
      const e = events[0];
      const rsvps = await ctx.db
        .query("eventRsvps")
        .withIndex("by_event", (q: any) => q.eq("eventId", e._id as Id<"events">))
        .collect();
      const going = rsvps.filter((r: Doc<"eventRsvps">) => r.status === "going").length;
      out.push({ key: "event", title: e.title, desc: `${going} going so far`, action: "Promote" });
    }

    return out.slice(0, 4);
  },
});

// ------------------------------------------------------------------
// needsList — the Needs surface: the live queue of student asks.
// ------------------------------------------------------------------
export const needsList = query({
  args: {},
  handler: async (ctx) => {
    const signals = await ctx.db.query("askJuntoSignals").collect();
    signals.sort((a: Doc<"askJuntoSignals">, b: Doc<"askJuntoSignals">) => b.createdAt - a.createdAt);

    const rows = await Promise.all(
      signals.slice(0, 60).map(async (s: Doc<"askJuntoSignals">) => {
        const u = await ctx.db.get(s.userId);
        return {
          id: s._id as string,
          text: s.text,
          category: s.category,
          status: s.status,
          userName: u?.name ?? "A student",
          userAvatar: u?.avatarUrl ?? null,
          createdAt: s.createdAt,
        };
      })
    );

    const counts = { open: 0, matched: 0, resolved: 0 };
    for (const s of signals) counts[s.status as "open" | "matched" | "resolved"]++;

    const byCat = new Map<string, number>();
    for (const s of signals) if (s.status === "open") byCat.set(s.category, (byCat.get(s.category) ?? 0) + 1);
    const topCategories = [...byCat.entries()]
      .map(([category, count]) => ({ category, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 8);

    return { rows, counts, topCategories };
  },
});

// ------------------------------------------------------------------
// eventsList — the Events surface: events with turnout + impact.
// ------------------------------------------------------------------
export const eventsList = query({
  args: {},
  handler: async (ctx) => {
    const events = await ctx.db.query("events").withIndex("by_date").collect();
    const rsvps = await ctx.db.query("eventRsvps").collect();
    const feedback = await ctx.db.query("eventFeedback").collect();

    const going = new Map<string, number>();
    const interested = new Map<string, number>();
    for (const r of rsvps) {
      if (r.status === "going") going.set(r.eventId, (going.get(r.eventId) ?? 0) + 1);
      if (r.status === "interested") interested.set(r.eventId, (interested.get(r.eventId) ?? 0) + 1);
    }
    const ratingsBy = new Map<string, number[]>();
    for (const f of feedback) {
      const a = ratingsBy.get(f.eventId) ?? [];
      a.push(f.rating);
      ratingsBy.set(f.eventId, a);
    }

    return events
      .sort((a: Doc<"events">, b: Doc<"events">) => b.date - a.date)
      .map((e: Doc<"events">) => {
        const ratings = ratingsBy.get(e._id) ?? [];
        const avg = ratings.length
          ? Math.round((ratings.reduce((s, r) => s + r, 0) / ratings.length) * 10) / 10
          : null;
        return {
          id: e._id as string,
          title: e.title,
          date: e.date,
          location: e.location ?? null,
          type: e.type,
          host: e.hostName ?? null,
          category: e.category ?? null,
          going: going.get(e._id) ?? 0,
          interested: interested.get(e._id) ?? 0,
          rating: avg,
          feedbackCount: ratings.length,
        };
      });
  },
});

// ------------------------------------------------------------------
// report — the self-writing impact one-pager (board / donor ready).
// ------------------------------------------------------------------
export const report = query({
  args: {},
  handler: async (ctx) => {
    const users = await onboarded(ctx);
    const conns = await connected(ctx);
    const deg = degrees(conns);

    const members = users.length;
    const connections = conns.length;
    const hasConnected = users.filter((u) => (deg.get(u._id) ?? 0) >= 1).length;
    const deeplyEngaged = users.filter((u) => (deg.get(u._id) ?? 0) >= 3).length;
    const pctConnected = members ? Math.round((hasConnected / members) * 100) : 0;

    const catOf = new Map<string, Set<string>>(users.map((u) => [u._id, new Set(u.skillCategories ?? [])]));
    let cross = 0;
    for (const c of conns) {
      const a = catOf.get(c.requesterId);
      const b = catOf.get(c.accepterId);
      if (a && b && a.size && b.size) {
        let shared = false;
        for (const x of a) if (b.has(x)) { shared = true; break; }
        if (!shared) cross++;
      }
    }

    const discCount = new Map<string, number>();
    for (const u of users) {
      const g = u.skillCategories?.[0];
      if (g) discCount.set(g, (discCount.get(g) ?? 0) + 1);
    }
    const disciplines = [...discCount.entries()]
      .map(([name, count]) => ({ name, count }))
      .sort((a, b) => b.count - a.count);

    const progCount = new Map<string, number>();
    for (const u of users) for (const p of u.programs ?? []) progCount.set(p, (progCount.get(p) ?? 0) + 1);
    const programs = [...progCount.entries()]
      .map(([name, count]) => ({ name, count }))
      .sort((a, b) => b.count - a.count);

    const events = (await ctx.db.query("events").collect()).length;
    const rsvps = await ctx.db.query("eventRsvps").collect();
    const attendance = rsvps.filter((r: Doc<"eventRsvps">) => r.status === "going").length;

    return {
      members,
      connections,
      pctConnected,
      deeplyEngaged,
      crossDiscipline: cross,
      crossPct: connections ? Math.round((cross / connections) * 100) : 0,
      disciplines,
      programs,
      events,
      attendance,
    };
  },
});
