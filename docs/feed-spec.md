# Feed Algorithm

How content gets placed on the Junto feed. Implements the feed described in [junto-prd.md](./junto-prd.md).

## Philosophy

- **Opportunity over engagement.** The feed isn't content to scroll, it's opportunities to act on. Rank by "could you be the person for this?" not by clout. No memes, no generic posts.
- **Relevance is the product.** The point is surfacing the post/person you should see. A highly relevant Ask from a stranger is worth more than a stale Update from someone you already know.
- **Weekly tool, not daily habit.** Decay is gentle enough that you don't miss things between sessions, but Asks (time-sensitive) expire faster than Updates.
- **Never empty.** A new user on a 30-person campus still opens to Matches, an Opportunity, and a prompt.
- **Every card is actionable, no buttons in the row.** Tap a card → detail view → act there.

---

## The four cards (from the PRD)

| Card | Source | Action | Time display |
|---|---|---|---|
| **Ask** | A user posts a need ("need a dev for a feature") | Offer to help / reach out | recency ("2h") |
| **Opportunity** | An event / program / thing to apply for, usually from an org | RSVP / apply / show up | real date/time |
| **Match** | System-generated — Junto pairs your profile's "what I can help with" to someone's Ask | Connect | — |
| **Update** | A progress post | React | recency ("2h") |

There is **no Offer card.** "What I can help with" lives on the profile; the system turns it into **Matches** against open Asks, so offers arrive already targeted instead of as feed noise.

### How cards map to the backend

- **Ask** and **Update** are `posts`. They form the scored spine.
- **Opportunity** is an `events` record, injected into the feed.
- **Match** is an entry from this week's `weeklyMatchBatches`, injected.

### Schema mapping for posts

The `posts.category` enum (`asking | sharing | looking_for`) maps to the two user-creatable post cards:

| `category` | card |
|---|---|
| `asking` | **Ask** |
| `looking_for` | **Ask** (a "who can…" need) |
| `sharing` | **Update** |

> The composer creates only Ask or Update. `looking_for` is treated as an Ask for ranking. (Schema labels predate the locked taxonomy — reconcile separately; the algorithm only depends on this mapping.)

---

## Scoring the post spine (Asks + Updates)

Every component normalized to `0..1`, then weighted. Soft boosts, no hard gates.

```
score =  W_REL  · relevance
       + W_CONN · connection
       + W_REC  · recency
       + W_CAT  · categoryWeight
       + W_ENG  · engagement
       − P_ACTED · alreadyActed

exclude post if: authorId == me  OR  reported-by-me  OR  dismissed
```

### Starting weights (tunable)

| Constant | Value | Why |
|---|---|---|
| `W_REL` | 0.40 | Relevance is the product. |
| `W_CONN` | 0.25 | Connections matter, but soft — a fresh relevant stranger Ask can outrank a stale connection Update. |
| `W_REC` | 0.20 | Freshness, secondary to fit. |
| `W_CAT` | 0.10 | Nudge Asks above Updates (the feed is about acting). |
| `W_ENG` | 0.05 | Mild liveness signal, capped so it can't dominate. |
| `P_ACTED` | 0.50 | Sinks posts you already acted on without fully hiding them. |

### Components

**relevance** — complementary embedding pairing:
```
Ask    → sim = cosine(myProfileEmbedding /* what I offer */, post.embedding)   // can I help?
Update → sim = cosine(myNeedsEmbedding   /* what I seek  */, post.embedding)   // useful to me?
relevance = clamp((sim − 0.30) / 0.50, 0, 1)      // 0.30→0, 0.80→1
fallback (missing embedding) = 0.30               // neutral, don't zero it out
```
`needsEmbedding` already exists and is populated (built from `lookingFor`); `weeklyMatches.ts` already pairs it this way. The feed should too.

**recency** — per-card half-life (weekly-app gentle):
```
recency = 0.5 ^ (ageHours / HALF_LIFE[card])
HALF_LIFE = { Ask: 36h, Update: 96h }
```
Asks are time-sensitive (a hackathon next weekend dies after); Updates linger.

**connection** — `isConnection ? 1 : 0`.

**categoryWeight** — `{ Ask: 1.0, Update: 0.5 }`.

**engagement** — `min(1, log1p(responseCount) / log1p(8))`. Capped, mild. "Opportunity over engagement" means this never dominates.

**alreadyActed** — `1` if I responded (offered to help / reacted) or already connected with the author from this post; else `0`.

---

## Placement (interleaving)

The feed is one ordered list of typed cards. Asks + Updates are the spine. On **page 0**, the other two card types are injected:

| Card | Rule | Slot |
|---|---|---|
| **Match (hero)** | Fresh, unseen weekly-match batch exists | Top (slot 0–1). It's the push that opened the app. |
| **Opportunity** | Soonest upcoming event, university-scoped | Slot 2–3 if `<48h` away, else ~slot 6. |
| **Matches (rest)** | Remaining from this week's batch | Every `N=5` posts, capped at batch size. |
| **Prompt** | User hasn't posted in 7 days | ~slot 3, or as the lead card if the feed is sparse. Composer prompt: *"What do you need right now?"* |

**Never empty:** if spine posts `< 5`, fill with all Matches → Opportunity → prompt → "people you might know" suggestion cards.

**Pages 1+:** spine posts only, no injected cards (infinite scroll never repeats an Opportunity/Match). `offset` counts posts already loaded.

**Finite feed:** `caught_up` is appended only when the whole spine fits on page 0 (`scored.length <= offset + limit`) — otherwise it would strand mid-feed once load-more appends the next page.

---

## Card kinds & the iOS contract

`getFeed` returns one array of `{ kind, key, tags?, ...payload }`. Two families:

- **Taxonomy cards** (the PRD's four) carry a `FeedTypeLabel`: `post` → Ask, `event` → Opportunity, `match` → Match. (Update reuses the post card.)
- **House cards** keep a sparse feed full and read *quieter* (no type label): `digest`, `vouch`, `momentum`, `milestone`, `prompt`, and the `caught_up` sentinel. New makers / people-discovery ride `kind:"match"` so they need no new UI.

| kind | payload | iOS view |
|---|---|---|
| `post` | `post` | `FeedCard` (Ask) |
| `match` | `match` | `FeedCard` (Match) — also new-maker people |
| `event` | `event` | `FeedEventCard` |
| `digest` | `{ newMakers, newAsks, upcomingEvents }` | `FeedNoticeCard` |
| `momentum` | `{ connectionsThisWeek }` | `FeedNoticeCard` |
| `milestone` | `{ count }` | `FeedNoticeCard` |
| `prompt` | `{ text }` | `FeedNoticeCard` (taps composer) |
| `vouch` | `{ _id, reason, createdAt, fromUser }` | `FeedVouchCard` |
| `caught_up` | — | `FeedCaughtUpCard` |

The iOS decoder is resilient: an unrecognized `kind` decodes fine and renders nothing (no crash), so the backend can emit a new kind before its card exists. The house-card views (`FeedNoticeCard`, `FeedVouchCard`, `FeedCaughtUpCard`) are first-pass, modeled on the existing `FeedCard`/`FeedEventCard` design language — they're meant to be restyled once designed.

---

## Decisions to lock

| # | Fork | Recommendation |
|---|---|---|
| 1 | Connection weighting: **hard tier** (current code, connections always first) vs **soft boost** | **Soft.** Opportunity-first beats "connections first." The current `+10000` tier means a 3-week-old connection Update outranks a 2-hour relevant stranger Ask. Needs your call. |
| 2 | Complementary embedding pairing (offer↔Ask, needs↔Update) vs single embedding | **Yes, complementary.** Big quality win, no new data needed. |
| 3 | Category weighting (Ask > Update) | **Yes, mild** (`W_CAT = 0.10`). |
| 4 | Penalize already-acted + exclude own posts | **Yes.** |
| 5 | Hero Match card at the very top on app open | **Yes** — it's the primary re-engagement moment. |

---

## Scope notes

- Backend only (`feed.ts`). No UI generated — card rendering is Kenny's design.
- Current fetch window is `(offset+limit)·2` newest posts re-sorted. Fine at campus scale (30–200 users); revisit if a campus exceeds a few thousand active posters.
- "Already acted" needs a cheap per-page lookup (my responses on the post + connection source = this post). Computed per page.
