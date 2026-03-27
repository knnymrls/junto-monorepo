# mkrs.world MVP

## Find who you should know on campus. Build a reputation that follows you.

Not a social network. Not a community app. A **people-discovery engine** that turns "I know there's someone on this campus who..." into an actual introduction — and builds a reputation for you along the way.

---

## The Problem

Students are surrounded by talented people they'll never meet. Your future cofounder might be in the building next door. The photographer who'd nail your project is in a completely different major. The person who already solved the problem you're stuck on is three floors up.

But you'll never cross paths. Because campus social circles are defined by proximity — your major, your dorm, your org — not by what you're actually doing or what you actually need.

There's no place to say "I need someone who can do X" and find a real person on your campus who can. And there's no place where what you've actually done — your projects, your collaborations, what people say about working with you — lives in one place.

**For universities:** They talk about "fostering connections" and "interdisciplinary collaboration" in every brochure, but have zero way to measure whether it's happening. No data. No proof. Just vibes.

**For employers:** They get resumes that all say "results-driven self-starter." They have no way to see what students have actually done, who they've worked with, or what peers think of them.

---

## Core Philosophy

* **Opportunity over engagement** — The feed isn't content to scroll. It's opportunities to act on. Every post has an implicit "and you could be the one."
* **Connection over clout** — No public likes. No follower counts. Success = two people actually talking, working together, or helping each other.
* **Profiles that compound** — Your mkrs profile gets more valuable over time. More vouches, more projects, more signal. It becomes your identity — on campus and beyond.
* **Useful, not addictive** — This is a weekly tool, not a daily habit. You open it when there's something relevant. You close it when you're done. That's fine.

---

## Who This Is For

Anyone on campus who's **doing something beyond just going to class.** Not restricted by major. Not just for coders. The filter is curiosity and initiative, not discipline.

- A film student looking for a cinematographer
- A business student starting a campus clothing brand
- A pre-med organizing a health awareness campaign
- A music major looking for someone to shoot a music video
- A CS student building an app and needing a designer
- A marketing student freelancing and looking for clients

If you're doing something and you need someone — or you have skills someone else needs — this is for you. The app self-selects. You don't need to gatekeep.

---

## The Core Product: Your Profile

Everything in the app — connections, matching, the feed, collaborations, vouches — exists to build one thing: **your profile.**

Your mkrs profile is the core product. It's a living representation of what you do, what you've done, and what people say about working with you.

**Why the profile matters:**
- It's the **conversion moment** in every interaction. Someone sees your post, checks your profile, decides whether to connect. If the profile is weak, nothing converts.
- It **compounds over time.** More vouches, more projects, more collaboration history = better matches, higher visibility, more trust.
- It's **portable.** `mkrs.world/username` works outside the app. Put it on your resume, your LinkedIn, your email signature. It's the personal portfolio site you never had to build.
- It has **career value.** A profile with real projects, peer vouches, and collaboration history is more valuable to an employer than any resume. This isn't just a campus tool — it follows you.

**Profile structure (widget-based):**
- Photo, name, headline, what you're focused on, what you're looking for, what you can help with
- **Visual work** — photos, designs, art, film stills
- **Projects** — title, description, images, links
- **Technical** — GitHub repos, contributions
- **Links** — Figma, Notion, personal site, portfolio
- **Experience** — roles, organizations, what you did
- **Vouches** — what people say about working with you (see below)

**Shareable profile link:**
- `mkrs.world/username` — a clean, public-facing page
- Works outside the app — anyone can view it
- Every profile view from a non-user is a potential new signup
- Students share it because it makes them look good, not because the app asks them to

---

## Core Loop

```
Opportunity appears
     Post: "Need a photographer for a campus event"
     Match: "Meet Jordan — she does video work, looking for directing experience"
     Search: "Who on campus knows After Effects?"
              |
You respond
     Comment: "I can help with this — check my profile"
     Comment: "@sarah would be perfect for this"
     Connect directly from the post
              |
They see your profile
     Your work. Your vouches. Your story.
     This is the conversion moment.
              |
Connect → Chat
     First real conversation.
     Suggested starters based on why you matched.
              |
Collaborate on something real
     A project, a favor, a skill exchange, a study session.
              |
Vouch
     One tap + optional note.
     "Great collaborator." "Super creative." "Reliable."
              |
Your profile gets stronger
     Better matches. Higher visibility. More trust.
     Repeat.
```

---

## Features

### Feed

The feed is where campus opportunity lives. Not a discussion forum — a place where needs meet people.

**Post types:**
- **"I need..."** — Looking for help, collaborators, teammates. ("Need a developer for a hackathon this weekend")
- **"I made..."** — Sharing work, projects, learnings. ("Just launched a campus clothing brand — here's the story")
- **"Who can..."** — Open questions, specific asks. ("Who on campus knows Figma well enough to teach me?")

**Comments are the public layer:**
- Comments aren't a discussion thread. They're **public responses** to an opportunity.
- "I can help with this — check my profile" → poster sees the comment and your profile
- "@jordan would be perfect for this" → Jordan gets notified, sees the post, connects with the poster
- Comments enable **recommendations** — the most powerful connection mechanic. Someone tags a friend, that friend gets introduced to someone they never would have met. This can't happen in DMs.

**Post-aware connections:**
- When you connect with someone from their post, the connection request carries context: "Kenny wants to connect — from your post: 'Need a photographer for a campus event'"
- The poster knows WHY you're reaching out. Not a random request — a specific, relevant one.

**Feed ranking:**
1. Posts from your connections
2. Posts relevant to your skills + what you're looking for (AI-ranked via embeddings)
3. Recent / chronological

**Weekly prompt:**
- Every week, everyone gets prompted: "What are you working on this week?"
- Creates content rhythm without pressure
- Keeps the feed alive and profiles fresh

### AI Matching

The hero feature. Works from day one with as few as 30 people.

- You fill out your profile: who you are, what you're focused on, what you need, what you can offer
- AI generates matches based on **complementary needs** — not just shared interests, but "you need what they have, they need what you have"
- **2-3 suggested matches per week**, pushed via notification
- Each match comes with a reason: "She's looking for a videographer — you do video work and are looking for creative projects"
- Matches are the **primary re-engagement mechanism.** Not "open the app and scroll." It's "we found someone you should meet."

### Events

Campus events — clubs, orgs, meetups, workshops. The growth wedge for new campuses.

**How events drive growth:**
1. Partner with one club/org at a new campus
2. Students download at the event
3. They fill out profiles (onboarding optimized for this moment)
4. AI matching kicks in immediately — value before they leave the room
5. Feed fills with people they just met IRL + new opportunities

**Post-event:**
- "Who did you enjoy meeting?" → Connection suggestions from attendees
- "What could be better?" → Data for event organizers
- Attendees who connected become the seed community

Events are a **growth wedge**, not a core feature. The app should be valuable on a Tuesday with no events happening. Events just accelerate adoption.

### Search

Natural language search for when you need someone specific.

- "Who on campus knows machine learning?"
- "Anyone here done consulting work?"
- "Looking for someone who can shoot 16mm film"

LLM-powered. Returns people with explanations of why they match, mutual connections, and relevance scores. Utility feature — not daily use, but high-value when you need it.

### Chat

Opens when you connect. The first conversation space.

- Low-friction intro messages
- Suggested conversation starters based on why you matched
- Typing indicators, read receipts
- Message requests for non-connections (anyone can reach out, but you control who gets through)

Chat doesn't need to be the long-term platform. If it moves to iMessage after the first conversation, that's a win — the connection was made. But conversations that stay in-app generate richer data and enable vouch prompts.

### Vouches

Lightweight endorsements that actually happen.

- **One-tap vouch** + optional short note: "Great to work with" / "Super creative" / "Really reliable" / custom
- Not a written essay. Not a star rating. Low friction = people actually do it.
- Prompted after real interaction — post-event, after sustained chat activity, after collaboration
- **Positive-only** by design. No negative reviews. No ratings.
- Vouch count is visible on profiles. More vouches = more trust in matches and search results.
- Vouches are **public** — visible on the vouch recipient's profile. Other people can see who vouched and what they said.

---

## Onboarding

The onboarding has ONE job: collect enough data to generate a match before you put the phone down. Every screen serves matching. Nothing is decorative.

**Screen 1: The hook**
> "Find the people you should know on campus."

Sign in with Apple. One tap. No friction.

**Screen 2: Photo + Name + Headline**
- Pre-filled from Apple ID where possible
- Headline prompt: "What would you tell someone at a party when they ask what you do?"
- Rotating examples show range: "Film student making documentaries" / "Starting a campus clothing brand" / "Pre-law, obsessed with mock trial" / "Graphic designer, freelancing on the side"

**Screen 3: What are you focused on?**
> "What are you working on or into right now?"

Free text, 2-3 sentences. This is the primary embedding input. Rotating examples: "Making a short doc about immigrant families" / "Trying to grow my photography Instagram" / "Building an app that helps students find textbooks" / "Training for a half marathon, looking for running partners"

**Screen 4: What do you need? What can you offer?**
- "What are you looking for?" — tag selection + free text
- "What can you help others with?" — tag selection + free text
- Tags span disciplines: Collaborator, Designer, Developer, Photographer, Videographer, Editor, Writer, Study partner, Mentor, Business advice, Creative partner, Feedback...

**Screen 5: Interests**
Quick multi-select grid. Not just tech: Film, Photography, Music, Design, Startups, AI/ML, Marketing, Writing, Fashion, Health/Fitness, Business, Engineering, Art, Gaming, Podcasting, Research, Social Impact...

**Screen 6: First matches (the aha moment)**
> "We found people you should know."

2-3 match cards with photos, headlines, and **why you matched.** Connect button right there. If they connect with even one person during onboarding, retention doubles.

**Cold start fallback** (< 30 users on campus):
> "You're early to mkrs at [campus]. We'll notify you when we find someone who matches what you're looking for. In the meantime, check out what people are posting."

Drop them into the feed. Set the expectation: value comes via notification, not scrolling.

---

## First 48 Hours

This is where you win or lose the user.

**Hour 0-1:** They connected with someone during onboarding (or browsed the feed). They close the app.

**Hour 6:** If they connected and neither has chatted:
> Push: "You and Jordan connected — say hey." + AI-generated conversation starter: "Saw you're working on a short film — what's it about?"

**Hour 24:** First match push:
> "We found someone you should know — Marcus, graphic design, looking for creative collaborators"

**Hour 36:** If they haven't posted:
> "What are you working on this week?" → Opens composer pre-filled.

**Goal:** At least one real connection and one chat started within 48 hours. If that doesn't happen, they're probably gone.

---

## Weekly Usage Pattern

This is NOT a daily app. It's a **weekly tool with notification-driven touchpoints.**

| Day | Touchpoint |
|---|---|
| **Monday** | Match notification: "We found 2 people you should know this week" |
| **Midweek** | Opportunity alert (if relevant): "Someone posted looking for [your skill]" |
| **Thursday** | Weekly prompt: "What are you working on this week?" |
| **Anytime** | Comment/mention/connection notifications |

**Typical week:** 2-3 app opens, 1-2 new connections, maybe 1 post, 3-5 minutes per session. That's enough to generate data, build connections, and compound profiles over a semester.

---

## How It Spreads

Virality comes from **specific moments where sharing is the natural thing to do**, not a "share this app" button.

### 1. The recommendation invite
Someone posts "looking for a photographer." You comment "@sarah" but she's not on the app. The app says:
> "Sarah isn't on mkrs yet. Send her this?"

Pre-written message: "Hey Sarah, someone on campus is looking for a photographer and I thought of you: [link]"

Sarah downloads because there's a specific, real opportunity waiting. Highest-converting invite possible.

### 2. Shareable profiles
`mkrs.world/username` in your LinkedIn bio, email signature, Instagram bio. Every view from a non-user shows the profile + "Create yours" CTA. Passive, ongoing, scalable.

### 3. Post sharing
Someone posts something great or useful. They share the link on Instagram stories or a group chat. The link shows the post + poster's profile + "Join to connect" CTA.

### 4. Event bursts
QR code at any event: "Connect with everyone here on mkrs." 20 people download at once, fill profiles, get matched with each other and existing users. The campus just hit critical mass from one event.

### 5. Word of mouth (can't be engineered)
> "Did you see someone on mkrs was looking for a videographer?"
> "No what's mkrs?"
> "Download it, people post stuff like that all the time"

Happens once the feed has enough activity that people regularly see relevant things. ~100+ active users per campus.

---

## Cold Start Playbook

How mkrs.world launches at a new campus with zero existing users:

1. **Partner with one org/club/class** — Get 30-50 students to sign up and fill profiles
2. **AI matching activates immediately** — Matches generated from the first batch. Value on day one.
3. **Seed the feed** — Weekly prompt goes out: "What are you working on?" Even 10 responses creates a living feed.
4. **First event** — Co-host with the partner org. Attendees download, onboard, get matched with each other and existing users.
5. **Matches drive retention** — Weekly push notifications: "We found someone you should meet."
6. **Recommendation invites kick in** — "Someone on mkrs was looking for a designer, you should be on there."
7. **Profiles start getting shared** — Students put mkrs.world/name in their bios. Passive growth.

**Minimum viable campus: 30 profiles.** That's enough for meaningful AI matches. Everything else grows from there.

**Long-term expansion:** The playbook should be repeatable by a campus ambassador — a student who can execute steps 1-4 at any campus without the founding team being there. If expansion requires Kenny personally showing up, it doesn't scale.

---

## Nudges & Prompts

* **Post-connection silence:** "You connected with Sarah 3 days ago — say hey." + suggested conversation starter (if no chat started)
* **Post-event:** "Who did you enjoy meeting at [event]?" → Connection suggestions from attendees
* **Post-collaboration:** "You and Alex have been chatting — vouch for them?" (after sustained chat activity)
* **Weekly prompt:** "What are you working on this week?" (content generation + profile freshness)
* **Match notification:** "We found someone you should know." (2-3x/week, primary re-engagement driver)
* **Opportunity alert:** "Someone is looking for [your skill]. Check it out." (when a post matches your profile)
* **Profile incomplete:** "Add your work to your profile — people with portfolios get 3x more connections." (if profile has no widgets)

---

## The Business

### Phase 1: Campus value (now)

The product is free for students. Value = connections, collaborations, and a compounding profile. Growth comes from events, recommendation invites, and shareable profiles. Revenue comes later.

### Phase 2: University data (when there's proof)

Once a campus has 500+ active users with real data:
- Connections made across disciplines
- Collaborations formed from introductions
- Cross-major interaction rates
- Event attendance and impact

Universities pay for this data because it proves community impact to donors, supports accreditation, and justifies programming budgets. Sell it manually first. Build a dashboard when there's demand.

### Phase 3: Employer value (when profiles are rich)

This is the bigger play. When mkrs profiles have real projects, peer vouches, and collaboration history, they become **more valuable than resumes.**

- An employer sees `mkrs.world/sarah` on a job application
- They see her actual work, who vouched for her, what she's collaborated on
- That's better signal than "results-driven self-starter" on a PDF

You don't need to build an employer product. You need profiles to be so good that employers start paying attention. Then:
- Companies pay for access to talent pipelines ("show me students with design portfolios and 5+ vouches in Lincoln")
- Career services offices buy licenses
- Students on the platform already have a career advantage — that drives adoption

**The profile IS the product.** Campus connections are the engine that makes profiles rich. Rich profiles have career value. Career value means graduates don't delete the app. The network compounds instead of churning.

---

## Data Priorities

Track everything from day 1. This data serves the university pitch, the employer pitch, and product decisions.

**Connection data:**
* Connections made (count, source, conversion to chat)
* Match acceptance rate
* Cross-discipline connections (are people meeting outside their bubble?)
* Connection-to-collaboration conversion

**Engagement data:**
* Post views, comments, connections initiated from posts
* Chat activity (conversations started, messages sent, response rates)
* Vouch frequency and patterns
* Recommendation mentions (@someone in comments)

**Retention data:**
* WAU (weekly active users — primary metric, not DAU)
* Match notification open rate
* Time to first connection
* Time to first vouch
* 30-day retention by cohort

**Growth data:**
* Invite sends and conversion
* Profile link views (from outside the app)
* Campus-by-campus growth curves
* Event-to-retained-user conversion

---

## Tech Stack

* **Frontend:** iOS (SwiftUI)
* **Backend:** Convex (real-time, serverless)
* **Auth:** Clerk
* **Analytics:** PostHog
* **AI:** OpenAI embeddings (text-embedding-3-small) for matching + feed ranking, GPT for search
* **Web (needed):** Public profile pages at mkrs.world/username — lightweight, could be static or Convex HTTP routes

---

## What's NOT in MVP

* University admin dashboard — sell the data manually first
* Employer-facing features — let profiles do the work
* Group conversations — 1-1 only
* Android — iOS first, campus by campus
* Public feed outside the app — profiles are shareable, feed is not
* Algorithmic "For You" page — connections first, relevant second, recent third

---

## What Needs to Be Built (Delta from Current App)

The existing app has: feed, events, chat, profiles with widgets, AI matching, search, notifications, analytics, and re-engagement crons. ~70% of what's needed is already built.

**New features needed:**

- [ ] **Vouches** — new `vouches` table, one-tap + optional note, display on profiles, vouch prompts
- [ ] **Scheduled match push** — cron that generates 2-3 matches/user/week and sends push notifications
- [ ] **Post-aware connections** — add `sourcePostId` to connection requests so recipients know why you're reaching out
- [ ] **Opportunity alerts** — when a post matches your skills/canHelpWith, send push notification
- [ ] **Shareable profile links** — `username` field on makers, public web page at mkrs.world/username
- [ ] **Recommendation invite flow** — when you @mention someone not on the app, prompt to invite with context
- [ ] **Post-event connection suggestions** — surface "people at this event you should connect with" from feedback data
- [ ] **Connection source tracking** — add `source` field to connections table for data story

**UX reframes (minimal code):**

- [ ] Post category display labels: "asking" → "I need..." / "sharing" → "I made..." / "looking_for" → "Who can..."
- [ ] Onboarding copy: "What are you building?" → "What are you focused on right now?"
- [ ] Expand suggested skills/interests beyond tech (photography, film, music, business, health, writing, etc.)
- [ ] Profile label: `currentProject` → "Currently focused on" in the UI
- [ ] Ensure match reason generation doesn't assume everyone is a builder

**Priority order:**

| # | Feature | Why first |
|---|---|---|
| 1 | Scheduled match push | Primary retention mechanism — "we found someone" |
| 2 | Vouches | Closes the loop — profiles compound, creates career value |
| 3 | Post-aware connections | Makes every connection feel intentional, not random |
| 4 | UX reframes (labels, onboarding, multi-disciplinary) | Quick wins that change how the whole app feels |
| 5 | Opportunity alerts | Makes the app feel alive even when you're not in it |
| 6 | Connection source tracking | Data play for university pitch |
| 7 | Shareable profile links | Biggest long-term growth lever, but needs web work |
| 8 | Recommendation invite flow | Growth mechanic, depends on having enough users first |
| 9 | Post-event connection suggestions | Nice-to-have, events already work |
