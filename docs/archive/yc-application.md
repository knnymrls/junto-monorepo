# YC Application — mkrs.world

---

## Company name
mkrs

## Company URL
mkrs.world

## Describe what your company does in 50 characters or less.
Shows you who you should know in your community.

## What is your company going to make? Please describe your product and what it does or will do.

mkrs is a people-discovery platform for communities. You tell it who you are, what you're working on, and what you need. It uses AI matching to find people with complementary skills and needs — and tells you why you should meet them.

The core product is an iOS app with AI-powered matching, an opportunity-based feed, 1-1 messaging, and widget-based profiles. Every connection, collaboration, and peer vouch compounds on your profile, turning it into a portable professional identity.

We're starting with college campuses. A student posts "need a designer for my startup" — the AI matches them with a design student who's looking for a founding team. Someone comments "@sarah would be perfect for this" and Sarah gets introduced to someone she never would have met. After they work together, they vouch for each other. Both profiles get stronger. Better matches follow.

Community organizers (program directors, accelerator leads, coworking managers) pay for the data: connections made, cross-discipline interactions, engagement metrics. Students use it for free.

## Why did you pick this idea to work on? Do you have domain expertise in this area? How do you know people need what you're making?

I'm a college student at UNL and I lived this problem. I spent two years trying to find the right people to build with and realized the infrastructure doesn't exist. You either get lucky at an event or you don't. There's no system for it.

I started running events on campus to test the hypothesis. Our first event had 55 students from every college — not just CS or business. Film students, designers, pre-law, music majors. All of them said the same thing: "I didn't know anyone doing this on campus."

The university feels it too. We're starting a paid pilot with UNL's Center for Entrepreneurship because their program directors can't prove students are actually connecting. They spend money on programming with no data on whether it works.

I've been building products and running ventures since high school. I know this campus, I know these students, and I've already built the product.

## What is new about what you are making? What substitutes do people resort to today?

Today students use Instagram DMs, GroupMe chats, Discord servers, or they walk up to someone after class. None of these answer "who on this campus can help me with X?" You either already know the person or you don't find them.

LinkedIn exists but it's for professionals performing for recruiters. College students don't use it for actual connection — they use it as a resume. Handshake connects students to employers, not to each other. Fizz and Yik Yak are anonymous gossip. None of them build a reputation.

What's new about mkrs:

1. **AI matching with reasons.** Not "here's a list of people." It's "meet Sarah — she's looking for a developer, you're a CS student looking for a startup to join." The match has context.

2. **The profile compounds.** Every vouch, project, and connection makes your profile more valuable. This creates switching cost that no other campus app has — and gives the profile career value beyond college.

3. **The data layer.** Every interaction generates data that community organizers will pay for. We're not monetizing attention. We're monetizing connection outcomes.

## Who are your competitors, and who might become competitors? Who do you fear most?

**Direct:** Loper (swipe-based college discovery — no structured data or matching). CollegeVine (admissions-focused, not connection). Bumble BFF (generic friend-finding, not skill/need based).

**Adjacent:** LinkedIn (professional network, but students don't use it for real connection). Handshake (student-to-employer, not student-to-student). Fizz (anonymous campus social, opposite of what we're building).

**Who I fear most:** Honestly, not another app. I fear GroupMe and Instagram DMs. Not because they're better — they're worse at this — but because they're already installed and students default to what's familiar. Our biggest competitor is inertia.

What protects us: none of those tools can answer "who on campus can help me with X?" or build a compounding reputation. They're communication tools. We're a discovery tool.

## How do or will you make money? How much could you make?

**Now:** Paid pilots with community organizers (university programs, accelerators, coworking spaces). $1-5k per pilot. We're starting our first with UNL's Center for Entrepreneurship.

**6-12 months:** Community subscriptions. Self-serve onboarding, community dashboard, engagement analytics. $100-500/month per community.

**12-24 months:** University-wide licenses. Campus-level data on cross-discipline connections, collaboration rates, engagement. $10-50k/year per university.

**24+ months:** Employer talent pipeline. Companies pay to search student profiles with real projects, peer vouches, and collaboration history. This is the big market.

**TAM:** ~4,000 US colleges, ~2,000 accelerators/incubators, ~20,000 coworking spaces, millions of employers. The community layer alone is a large SaaS market. The employer talent pipeline competes in a multi-billion dollar recruiting market. But right now I care about proving it at one campus.

## How will you get users? If your strategy is marketing related, how will you stand out from competitors with more money?

Community by community, not campus by campus. Every community has a gatekeeper — a program director, a club president, a community manager. One conversation gets the entire group onboarded.

**Specific playbook:**
1. Partner with one program/org — get 30-50 students to sign up
2. AI matching activates immediately — value on day one
3. Events create download bursts — 55 showed up to our first one
4. Recommendation mentions drive organic invites — someone tags a friend who isn't on the app, the app prompts an invite with context
5. Shareable profile links (mkrs.world/username) — students put them in bios, every view from a non-user is a potential signup

We don't compete on marketing spend. We compete on density. Get 30 people in a community and matching works. That's our minimum viable launch. Events and community gatekeepers get us there without ads.

## How far along are you? If you've already started working on it, how long have you been working and how many lines of code (or equivalent) have you written?

Product is live. iOS app built in SwiftUI with a Convex backend. ~85 Swift files, ~23 TypeScript backend files. Features shipped:

- AI-powered matching (OpenAI embeddings, vector similarity)
- Feed with post types and AI-ranked sorting
- 1-1 real-time messaging with message requests
- Events with RSVPs, calendar integration, post-event feedback
- Natural language AI search (GPT-powered)
- Widget-based profiles (GitHub, gallery, links, experience)
- Push notifications (APNs)
- Full analytics pipeline (PostHog)
- Re-engagement system (weekly digests, match reminders, content prompts)

250 users. 55 students at first event across every college. Paid pilot starting with UNL Center for Entrepreneurship (Catalysts program + Accelerator).

Been working on this for ~6 months. Building full-time.

## How many founders are on the team? Who are they and what do they do?

Two founders.

**Kenny Morales** — CEO. Product, design, engineering, sales. Built the entire product. Runs the events. Doing the university sales conversations. Based in Lincoln, NE. Student at UNL, in the Accelerator program.

**Wilson Overfield** — Co-founder. Everything except design. Engineering, ops, strategy.

## Please tell us about the time you, Kenny, most successfully hacked some (non-computer) system to your advantage.

Built FindU — a college decision platform — from nothing while still in school. Indexed every accredited US university, curated 10,000+ short-form campus videos, and hit 500,000+ organic views on TikTok/Instagram without spending a dollar on ads. Got a pilot with the University of Nebraska-Lincoln and 250 active users through high school workshops and distribution partnerships.

No connections in tech. No CS degree. From Grand Island, Nebraska. Figured it out by doing the thing nobody wanted to do: personally reaching out to every high school counselor, every college admissions office, every student org, one by one. That grind is the same thing driving mkrs — showing up where the students are, not waiting for them to find us.

## What convinced you this idea is worth pursuing? What evidence do you have that people want it?

Three things:

1. **55 students from every college showed up to our first event.** Not just CS and business — film, music, design, pre-law. Every single one said some version of "I didn't know anyone doing this on campus." The demand for cross-discipline connection is real and unmet.

2. **UNL's Center for Entrepreneurship is paying us to pilot this.** Their program directors can't prove their students are connecting. They need the data. When the customer offers to pay before you ask, the problem is real.

3. **The recommendation behavior happened organically.** In the app, students started tagging friends in posts: "@sarah would be perfect for this." That's unprompted, organic viral behavior. People want to connect others — they just need a place to do it.

## What do you understand about your business that other companies in it just don't get?

Every campus social app tries to be a daily-use engagement product and fails because there's no lasting value. They optimize for screen time. We optimize for connections that actually happen.

mkrs is a weekly tool, not a daily habit. Students open it 2-3 times a week when we send them a match or someone posts an opportunity that matches their skills. That looks bad on a DAU chart but it's the right design — because the thing that makes people stay isn't engagement, it's that their profile gets more valuable every week. Vouches, projects, connections. That's an asset they built. That's switching cost.

The other thing: this isn't a campus product. It's a community product. Every accelerator, coworking space, bootcamp, and professional org has the same problem — people in the same room who don't know what the person next to them can do. Campuses are our wedge because of built-in density. But the model works anywhere there's a community with a gatekeeper.

## If you had any other ideas you considered applying with, please list them.

FindU — college decision platform for high school students. Built it, launched it, it works. But mkrs is the bigger opportunity because the TAM expands beyond campuses and the data business has stronger recurring revenue. FindU is a transaction (pick a college). mkrs is a network that compounds.

## Is there anything else we should know about your company?

We're not trying to build the next social network. We're building infrastructure that helps communities prove their people are actually connecting. The students get a tool that finds them the right people. The community organizers get data they can't get anywhere else. The profile becomes a career asset that outlasts any single community.

We know the graveyard of campus apps is massive. We're not building a campus app. We're building a reputation layer that starts on campus.
