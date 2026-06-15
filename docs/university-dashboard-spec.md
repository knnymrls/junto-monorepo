# Junto for Universities — Build Spec

> The university-facing web app. What Amanda (and centers like hers) see.
> Status: locked 2026-06-14. Supersedes the "Dashboard (UNL)" section of [junto-prd.md](./junto-prd.md).
> Hard deadline: first version by Wed 2026-06-17.

## One line

A cockpit that watches a campus entrepreneurship ecosystem build itself, proves it is working, and tells the director what to do next, all from data she never has to touch.

## Who it is for

The program manager / assistant director who actually runs the center day to day. At UNL that is **Amanda Metcalf** (Center for Entrepreneurship, processes the $10K pilot, sole university contact now that Mallory has left). Not the tenured faculty director who teaches. The person who plans the events, chases the turnout, manages mentors, and has to report impact upward.

## Her dream outcome (the north star)

> "I want to walk into the dean's office and the donor meeting with undeniable, beautiful proof that my program changes students' lives, without spending a single hour building it."

Her real win is not "more startups." It is security and recognition for work she already does well, with the busywork erased. The single thing she would pay almost anything to kill is not running the program, it is **proving** it. Today that means twice-a-year "impact archaeology": rebuilding attendance from sign-in sheets, chasing alumni who never reply, copying numbers between spreadsheets, then walking into the board room with a deck she is not even sure is true.

## The strategy (why this wins)

Hormozi value equation: Value = (Dream Outcome x Perceived Likelihood) / (Time Delay x Effort). The leverage is in the **denominator**. Drive Time and Effort toward zero and value approaches infinity.

- Every incumbent (StartupTree, Anthology, Suitable, Mentor Collective, PeopleGrove) competes on the numerator: more features, more dashboards. They all fail her because proving impact still costs hundreds of manual hours and she still does not trust the output. High effort, high time delay, low trust. 87 of 140 centers track impact in Excel. Directors openly distrust their own data.
- They also churn because their student-facing surfaces are chores students refuse to do, so adoption dies (the orientation-download-then-delete death), so no data, so no provable ROI, so non-renewal.

**Junto's unfair, structural advantage:** because students use the app for themselves (find the right people), the proof builds itself. Every connection, ask, match, and event check-in is captured automatically as a byproduct of students doing what they already want to do. Amanda lifts zero fingers and the impact picture accumulates live. No competitor can copy this, because their student surfaces are not things students actually want.

## Design principles (derived from the equation)

1. **Instant (Time -> 0):** value on first login, live not batched. Pre-seed her account by importing her existing roster so it is never an empty grid.
2. **Effortless (Effort -> 0):** she never enters data, never chases an alum, never reconciles a sheet. The data captures itself and the report writes itself.
3. **Trustworthy (Likelihood -> max):** every number is clickable down to its source row (this connection, this event, this student). Provenance kills the distrust that haunts her spreadsheets. Connections are observed, not assumed.
4. **Powerful and calm:** lead with the outcome, not a wall of widgets. It should feel like a precise instrument, not a noisy analytics page.

## The product — five surfaces

### 1. Home — "Is it working?" (proof at a glance)
Opens to a verdict, not charts. Example: "142 students active. 318 connections made. 61% cross-discipline. +12% this month." A few impact tiles, each clickable to source: students engaged (% of cohort), connections this week, % of newcomers who connected in their first week, event attendance. Then a short "what needs you" list of live, actionable nudges (isolated newcomers, a top connector graduating, a cluster of students all needing the same thing).

### 2. The Map — the living graph (the wow, proof made visible)
The real network of who is connecting with whom. Students as nodes (color by major or cohort), connections as edges (with source and timestamp). Interactions: click a student to see just their ego network, toggle a view that lights up only cross-discipline bridges, size nodes by influence (connector / broker), time-scrubber to watch the graph grow after an event, filter to isolates and newcomers. This is the thing no competitor has and the reason the room goes "whoa."

### 3. Needs — what students need right now (act on it)
The live feed of student asks (from Ask Junto signals): top needs, by cohort, open / matched / resolved. Tap an ask to see the students who could help and the shortest path to reach them. A warm-intro machine.

### 4. The Report that writes itself (the dream delivered)
One button generates a clean, board- and donor-ready impact one-pager from live data, with presets for who is asking (dean / provost / donor). Export or copy. This is the surface that kills her worst recurring pain.

### 5. Ask it anything (never caught not knowing)
A plain-English box over her data: "how many first-gen students connected this month?" returns the answer plus where it came from. The natural-language / Claude layer. The "biggest unlock" Amanda named. Insurance against the surprise question from the provost.

### Cohort lens (across everything)
A global filter to flip between Accelerator / Catalyst / Raikes (and All). Everything re-scopes. Amanda's explicit ask.

## Build order

Two co-heroes first, because they are the wow and the dream and both run off data that already exists:
1. **The Map** — wins the room, proves the collisions are real.
2. **Home / proof surface** — the live "it is working" verdict she can trust.

Then:
3. **Needs** — close third, the Ask Junto signals backend already exists (`pulse`, `listAsks`, `updateSignalStatus`).
4. **Report + Ask box** — immediate fast-follow that completes the dream.

## Data feasibility (it is buildable from what we already capture)

- `users` carry `programs` (["Raikes School","Accelerator","Catalyst"]), `majors`, `skills`, embeddings, `createdAt` -> cohort segmentation, cross-discipline analysis, % first-week-connect.
- `connections` carry `source` (match / event / post / profile / search) and timestamps -> the graph, attribution, growth over time.
- `events` / `eventRsvps` / `eventFeedback` -> attendance, event impact.
- `askJuntoSignals` -> the Needs feed (Pulse + Asks).

## Locked decisions

- **Scope:** UNL only for now. Data model stays multi-tenant-ready (signals and users are keyed by `universityId`) at no extra cost.
- **Home:** new app in the `junto` monorepo (`apps/dashboard`), rebuilt from scratch, sharing the Convex backend and types. The old mkrs.world social-analytics dashboard is retired.
- **UI:** shadcn. Live reactive Convex queries (`useQuery`), not one-shot HTTP fetch.
- **Auth:** simple shared-password gate for the MVP. Real per-admin auth (Clerk) is a later step.
- **Process:** architecture -> design (design language before layout) -> build.

## Deliberately deferred

- Longitudinal alumni venture outcomes (capital raised, jobs). Highest-value to leadership, but Junto has no venture/funding data yet. Foundation only.
- Predictive "you should meet X", churn prediction, event simulation. Needs more data / ML.
- Alumni-as-offers and external-mentor search. Later.
