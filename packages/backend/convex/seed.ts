import { internalMutation, internalAction } from "./_generated/server";
import { internal } from "./_generated/api";
import { Id } from "./_generated/dataModel";

// ============================================================
// CLEAR ALL — wipe everything for a fresh demo seed
// ============================================================
export const clearAll = internalMutation({
  args: {},
  handler: async (ctx) => {
    const tables = [
      "posts", "comments", "events", "eventRsvps", "eventFeedback",
      "connections", "conversations", "messages", "typingIndicators",
      "notifications", "searchSessions", "searchChats", "searchMessages",
      "weeklyMatchBatches", "portfolioItems", "deviceTokens",
      "inviteLinks", "inviteRedemptions",
    ] as const;

    let total = 0;
    for (const table of tables) {
      const docs = await ctx.db.query(table as any).collect();
      for (const doc of docs) {
        await ctx.db.delete(doc._id);
      }
      total += docs.length;
    }

    // Clear test users (keep Kenny's real account)
    const users = await ctx.db.query("users").collect();
    for (const user of users) {
      if (user.clerkId.startsWith("test_")) {
        await ctx.db.delete(user._id);
        total++;
      }
    }

    return { cleared: total };
  },
});

// ============================================================
// SEED USERS — 20 UNL students, realistic and diverse
// ============================================================
export const seedUsers = internalMutation({
  args: {},
  handler: async (ctx) => {
    const now = Date.now();
    const day = 86400000;

    const users = [
      {
        clerkId: "test_sarah",
        email: "schen4@huskers.unl.edu",
        name: "Sarah Chen",
        headline: "CS Junior — building a campus lost-and-found app",
        avatarUrl: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&h=200&fit=crop&crop=face",
        currentProject: "LostHusker — a lost-and-found app for UNL campus. Students post lost items, others can claim them. Trying to replace those sad flyers on bulletin boards.",
        lookingFor: "A designer who can make the UI not look like a homework assignment, and someone to help me pitch this to UNL admin",
        canHelpWith: "Full-stack development, React, Node, iOS development, debugging your code at 2am",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: { github: "https://github.com/sarahchen", linkedin: "https://linkedin.com/in/sarahchen" },
        isOnboarded: true,
        createdAt: now - 14 * day,
        updatedAt: now - 2 * day,
      },
      {
        clerkId: "test_marcus",
        email: "mwilliams22@huskers.unl.edu",
        name: "Marcus Williams",
        headline: "Graphic Design Senior — branding & UI",
        avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&crop=face",
        currentProject: "Redesigning the branding for 3 student orgs this semester. Also building a design system template that any student startup can use for free.",
        lookingFor: "Developers who actually care about design. Tired of seeing good ideas ruined by bad UI.",
        canHelpWith: "Logo design, branding, UI/UX, Figma, pitch deck design, making your app look legit",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: { instagram: "https://instagram.com/marcus.designs", linkedin: "https://linkedin.com/in/marcuswilliams" },
        isOnboarded: true,
        createdAt: now - 12 * day,
        updatedAt: now - 1 * day,
      },
      {
        clerkId: "test_emily",
        email: "erodriguez5@huskers.unl.edu",
        name: "Emily Rodriguez",
        headline: "Data Science + Econ — making sense of messy data",
        avatarUrl: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&h=200&fit=crop&crop=face",
        currentProject: "Building a dashboard that tracks student org engagement across campus — which clubs are growing, which are dying, and why.",
        lookingFor: "Frontend dev to build the dashboard UI, and student org leaders who want to beta test",
        canHelpWith: "Data analysis, Python, SQL, Tableau, survey design, statistical modeling",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: { github: "https://github.com/emilyrodriguez", linkedin: "https://linkedin.com/in/emilyrodriguez" },
        isOnboarded: true,
        createdAt: now - 11 * day,
        updatedAt: now - 3 * day,
      },
      {
        clerkId: "test_jake",
        email: "jthompson8@huskers.unl.edu",
        name: "Jake Thompson",
        headline: "CS + Entrepreneurship — iOS dev & indie hacker",
        avatarUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&h=200&fit=crop&crop=face",
        currentProject: "StudyPulse — a focus timer app with social accountability. Your friends can see when you're studying and nudge you when you're not.",
        lookingFor: "Someone who gets marketing — I can build anything but I can't get anyone to download it",
        canHelpWith: "iOS development, SwiftUI, shipping fast, App Store stuff, Xcode debugging",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: { github: "https://github.com/jakethompson", twitter: "https://twitter.com/jakethompson" },
        isOnboarded: true,
        createdAt: now - 10 * day,
        updatedAt: now - 1 * day,
      },
      {
        clerkId: "test_alex",
        email: "arivera3@huskers.unl.edu",
        name: "Alex Rivera",
        headline: "Marketing Major — growth & content strategy",
        avatarUrl: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&h=200&fit=crop&crop=face",
        currentProject: "Writing a playbook for student startup marketing — all the tactics I've learned, open-sourced for anyone.",
        lookingFor: "Technical co-founder for a social commerce idea I've been sitting on. Need someone who builds.",
        canHelpWith: "Social media strategy, TikTok/Reels, content creation, growth hacking, go-to-market",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: { instagram: "https://instagram.com/alexrivera", linkedin: "https://linkedin.com/in/alexrivera" },
        isOnboarded: true,
        createdAt: now - 9 * day,
        updatedAt: now - 2 * day,
      },
      {
        clerkId: "test_jordan",
        email: "jkim12@huskers.unl.edu",
        name: "Jordan Kim",
        headline: "Software Engineering Senior — backend & infrastructure",
        avatarUrl: "https://images.unsplash.com/photo-1519345182560-3f2917c472ef?w=200&h=200&fit=crop&crop=face",
        currentProject: "Open-source API boilerplate for student projects — auth, payments, email all pre-wired so you can skip the boring stuff.",
        lookingFor: "Frontend devs to build example apps on top of it, and feedback from student founders who'd use it",
        canHelpWith: "Backend dev, API design, databases, deployment, system architecture, code reviews",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: { github: "https://github.com/jordankim" },
        isOnboarded: true,
        createdAt: now - 8 * day,
        updatedAt: now - 1 * day,
      },
      {
        clerkId: "test_maya",
        email: "mpatel7@huskers.unl.edu",
        name: "Maya Patel",
        headline: "Business + CS — product & fintech",
        avatarUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop&crop=face",
        currentProject: "PennyWise — a micro-savings app that rounds up student purchases and invests the spare change. Like Acorns but designed for broke college students.",
        lookingFor: "iOS developer who wants to build the app, and someone who understands financial compliance",
        canHelpWith: "Product management, user research, business strategy, financial modeling, pitch decks",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: { linkedin: "https://linkedin.com/in/mayapatel" },
        isOnboarded: true,
        createdAt: now - 7 * day,
        updatedAt: now - 2 * day,
      },
      {
        clerkId: "test_chris",
        email: "canderson15@huskers.unl.edu",
        name: "Chris Anderson",
        headline: "Entrepreneurship Senior — 2x founder, still learning",
        avatarUrl: "https://images.unsplash.com/photo-1560250097-0b93528c311a?w=200&h=200&fit=crop&crop=face",
        currentProject: "Helping 3 freshman teams prep for Big Red Ventures pitch competition. Also writing about what I've learned failing.",
        lookingFor: "Technical people who want business guidance. I can't code but I can sell, pitch, and figure out the money side.",
        canHelpWith: "Pitching, fundraising, business plans, sales, networking, not quitting when it gets hard",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: { linkedin: "https://linkedin.com/in/chrisanderson", twitter: "https://twitter.com/chrisanderson" },
        isOnboarded: true,
        createdAt: now - 13 * day,
        updatedAt: now - 1 * day,
      },
      {
        clerkId: "test_lisa",
        email: "lnguyen9@huskers.unl.edu",
        name: "Lisa Nguyen",
        headline: "CS + Math — AI/ML research, LLM projects",
        avatarUrl: "https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=200&h=200&fit=crop&crop=face",
        currentProject: "Building an AI study buddy that reads your course syllabus and generates practice problems. Testing with CSCE 310 students.",
        lookingFor: "Someone to help with the frontend and a business person to figure out if this could be a real product",
        canHelpWith: "Machine learning, NLP, Python, LLM prompt engineering, research methodology",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: { github: "https://github.com/lisanguyen" },
        isOnboarded: true,
        createdAt: now - 6 * day,
        updatedAt: now - 1 * day,
      },
      {
        clerkId: "test_david",
        email: "dpark2@huskers.unl.edu",
        name: "David Park",
        headline: "CS Sophomore — mobile dev, cross-platform",
        avatarUrl: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200&h=200&fit=crop&crop=face",
        currentProject: "EventPulse — a local events app for college students in Nebraska. Aggregates events from all the different campus calendars into one feed.",
        lookingFor: "Backend developer to help scale the event scraping, and someone at UNO/Creighton to expand beyond UNL",
        canHelpWith: "Mobile development, Flutter, React Native, Firebase, shipping apps fast",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: { github: "https://github.com/davidpark" },
        isOnboarded: true,
        createdAt: now - 5 * day,
        updatedAt: now - 2 * day,
      },
      // --- 10 NEW USERS ---
      {
        clerkId: "test_priya",
        email: "psharma6@huskers.unl.edu",
        name: "Priya Sharma",
        headline: "Supply Chain Management — ops & logistics nerd",
        avatarUrl: "https://images.unsplash.com/photo-1580489944761-15a19d654956?w=200&h=200&fit=crop&crop=face",
        currentProject: "Researching last-mile delivery optimization for rural Nebraska. It's wild how much money is wasted getting packages to small towns.",
        lookingFor: "Developer who can build a route optimization prototype, and connections to small logistics companies for interviews",
        canHelpWith: "Operations strategy, supply chain analysis, Excel modeling, process optimization",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: { linkedin: "https://linkedin.com/in/priyasharma" },
        isOnboarded: true,
        createdAt: now - 4 * day,
        updatedAt: now - 1 * day,
      },
      {
        clerkId: "test_ethan",
        email: "ebrooks3@huskers.unl.edu",
        name: "Ethan Brooks",
        headline: "Film & New Media — video, storytelling, content",
        avatarUrl: "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200&h=200&fit=crop&crop=face",
        currentProject: "Filming a 6-part docuseries on student entrepreneurs at UNL. Following 3 teams from idea to launch.",
        lookingFor: "Founders who want to be featured, and someone who can build a simple website to host the series",
        canHelpWith: "Video production, storytelling, content strategy, social media video, brand videos",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: { instagram: "https://instagram.com/ethanbrooks", website: "https://ethanbrooks.com" },
        isOnboarded: true,
        createdAt: now - 4 * day,
        updatedAt: now - 1 * day,
      },
      {
        clerkId: "test_olivia",
        email: "omartinez8@huskers.unl.edu",
        name: "Olivia Martinez",
        headline: "Architecture + Design Computing — spatial & 3D",
        avatarUrl: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&h=200&fit=crop&crop=face",
        currentProject: "Generative floor plan tool — input constraints (sq ft, rooms, sun direction) and it generates optimized layouts. Using Python and Grasshopper.",
        lookingFor: "Web developer to make it browser-based, and anyone interested in generative design",
        canHelpWith: "3D modeling, Rhino, Grasshopper, spatial design thinking, physical prototyping",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: { instagram: "https://instagram.com/olivia.builds" },
        isOnboarded: true,
        createdAt: now - 3 * day,
        updatedAt: now - 1 * day,
      },
      {
        clerkId: "test_tyler",
        email: "treed7@huskers.unl.edu",
        name: "Tyler Reed",
        headline: "Ag Science + CS Minor — agtech & IoT",
        avatarUrl: "https://images.unsplash.com/photo-1504257432389-52343af06ae3?w=200&h=200&fit=crop&crop=face",
        currentProject: "SmartIrrigate — low-cost soil moisture sensors that connect to your phone. Helps small farms save water without expensive enterprise systems.",
        lookingFor: "Mobile developer to build the companion app, and someone who knows hardware manufacturing",
        canHelpWith: "Agriculture knowledge, IoT hardware, Arduino/Raspberry Pi, field testing, rural market validation",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: { github: "https://github.com/tylerreed" },
        isOnboarded: true,
        createdAt: now - 8 * day,
        updatedAt: now - 1 * day,
      },
      {
        clerkId: "test_ava",
        email: "awashington4@huskers.unl.edu",
        name: "Ava Washington",
        headline: "Psychology + HCI — user research & UX",
        avatarUrl: "https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=200&h=200&fit=crop&crop=face",
        currentProject: "Running a UX research study on how UNL students actually choose classes. The current system is broken and I have data to prove it.",
        lookingFor: "Developer to prototype the class planning tool, and professors who'd let me test with their students",
        canHelpWith: "User interviews, usability testing, survey design, research synthesis, persona development",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: { linkedin: "https://linkedin.com/in/avawashington" },
        isOnboarded: true,
        createdAt: now - 7 * day,
        updatedAt: now - 2 * day,
      },
      {
        clerkId: "test_noah",
        email: "nkessler2@huskers.unl.edu",
        name: "Noah Kessler",
        headline: "Finance + Entrepreneurship — numbers & pitch decks",
        avatarUrl: "https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=200&h=200&fit=crop&crop=face",
        currentProject: "Building a financial model template library specifically for student startups — pre-revenue, early-stage, different business models.",
        lookingFor: "Web developer to build a simple site to host the templates, and student founders to test them with",
        canHelpWith: "Financial modeling, pitch deck feedback, fundraising strategy, investor intros, Excel/Sheets sorcery",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: { linkedin: "https://linkedin.com/in/noahkessler" },
        isOnboarded: true,
        createdAt: now - 6 * day,
        updatedAt: now - 1 * day,
      },
      {
        clerkId: "test_mia",
        email: "mchang5@huskers.unl.edu",
        name: "Mia Chang",
        headline: "Journalism + Digital Media — writing, PR, social",
        avatarUrl: "https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=200&h=200&fit=crop&crop=face",
        currentProject: "Writing a long-form piece on why Lincoln could become the next Midwest tech hub. Interviewing founders, investors, and UNL faculty.",
        lookingFor: "Student founders to interview for the piece, and someone who wants a communications co-founder",
        canHelpWith: "Writing, PR, press pitches, social media copy, storytelling, brand voice",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: { twitter: "https://twitter.com/miachang", website: "https://miachang.substack.com" },
        isOnboarded: true,
        createdAt: now - 5 * day,
        updatedAt: now - 1 * day,
      },
      {
        clerkId: "test_caleb",
        email: "cokafor6@huskers.unl.edu",
        name: "Caleb Okafor",
        headline: "Mechanical Engineering — prototyping & hardware",
        avatarUrl: "https://images.unsplash.com/photo-1463453091185-61582044d556?w=200&h=200&fit=crop&crop=face",
        currentProject: "Smart bike lock with GPS tracking — designed for campus bikes that keep getting stolen. Working prototype, need the software side.",
        lookingFor: "Software developer to build the companion app (BLE + GPS), and someone to help with crowdfunding",
        canHelpWith: "CAD modeling, 3D printing, prototyping, mechanical design, hardware debugging",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: { instagram: "https://instagram.com/caleb.makes" },
        isOnboarded: true,
        createdAt: now - 3 * day,
        updatedAt: now - 1 * day,
      },
      {
        clerkId: "test_sophie",
        email: "sbennett4@huskers.unl.edu",
        name: "Sophie Bennett",
        headline: "Graphic Design — brand identity & packaging",
        avatarUrl: "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&h=200&fit=crop&crop=face",
        currentProject: "Designing brand identities for 2 student startups this semester. Also working on my portfolio site.",
        lookingFor: "Developers who need branding, and student startups that want to look professional early",
        canHelpWith: "Brand identity, logo design, packaging, typography, print design, brand guidelines",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: { instagram: "https://instagram.com/sophie.designs", website: "https://sophiebennett.design" },
        isOnboarded: true,
        createdAt: now - 2 * day,
        updatedAt: now - 1 * day,
      },
      {
        clerkId: "test_daniel",
        email: "dherrera3@huskers.unl.edu",
        name: "Daniel Herrera",
        headline: "CS + Music Tech — creative coding & audio",
        avatarUrl: "https://images.unsplash.com/photo-1531384441138-2736e62e0919?w=200&h=200&fit=crop&crop=face",
        currentProject: "BeatRoom — a web app where multiple people can make music together in real-time. Like Google Docs but for beats.",
        lookingFor: "Frontend developer who knows Web Audio API, and musicians who want to beta test",
        canHelpWith: "Creative coding, Web Audio, p5.js, music production, making your hackathon project actually fun",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: { github: "https://github.com/danielherrera", instagram: "https://instagram.com/djdaniel" },
        isOnboarded: true,
        createdAt: now - 2 * day,
        updatedAt: now - 1 * day,
      },
    ];

    const insertedIds: Id<"users">[] = [];
    const userMap: Record<string, Id<"users">> = {};

    for (const user of users) {
      const existing = await ctx.db
        .query("users")
        .filter((q) => q.eq(q.field("clerkId"), user.clerkId))
        .first();

      if (!existing) {
        const id = await ctx.db.insert("users", user);
        insertedIds.push(id);
        userMap[user.clerkId] = id;
      } else {
        userMap[user.clerkId] = existing._id;
      }
    }

    return { inserted: insertedIds.length, userMap };
  },
});

// ============================================================
// HELPER: get user ID by clerkId
// ============================================================
async function getUser(ctx: any, clerkId: string): Promise<Id<"users"> | null> {
  const user = await ctx.db
    .query("users")
    .filter((q: any) => q.eq(q.field("clerkId"), clerkId))
    .first();
  return user?._id ?? null;
}

// ============================================================
// SEED POSTS — 12 realistic posts from different users
// ============================================================
export const seedPosts = internalMutation({
  args: {},
  handler: async (ctx) => {
    const now = Date.now();
    const hour = 3600000;

    const sarah = await getUser(ctx, "test_sarah");
    const marcus = await getUser(ctx, "test_marcus");
    const emily = await getUser(ctx, "test_emily");
    const jake = await getUser(ctx, "test_jake");
    const alex = await getUser(ctx, "test_alex");
    const jordan = await getUser(ctx, "test_jordan");
    const maya = await getUser(ctx, "test_maya");
    const chris = await getUser(ctx, "test_chris");
    const lisa = await getUser(ctx, "test_lisa");
    const tyler = await getUser(ctx, "test_tyler");
    const ava = await getUser(ctx, "test_ava");
    const noah = await getUser(ctx, "test_noah");
    const caleb = await getUser(ctx, "test_caleb");
    const priya = await getUser(ctx, "test_priya");
    const ethan = await getUser(ctx, "test_ethan");
    const mia = await getUser(ctx, "test_mia");

    if (!sarah || !marcus || !emily || !jake || !alex || !jordan || !maya || !chris || !lisa || !tyler || !ava || !noah || !caleb || !priya || !ethan || !mia) {
      return "Missing users — run seedUsers first";
    }

    const posts: Array<{
      authorId: Id<"users">;
      content: string;
      category: "asking" | "sharing" | "looking_for";
      createdAt: number;
      updatedAt: number;
    }> = [
      {
        authorId: sarah,
        content: "Just submitted LostHusker to the App Store!! 🎉 It's a lost-and-found app for campus — students can post lost items with photos and location, and others can claim them. No more sad flyers on bulletin boards. If you've lost anything on campus recently, DM me and I'll send you the TestFlight link!",
        category: "sharing",
        createdAt: now - 2 * hour,
        updatedAt: now - 2 * hour,
      },
      {
        authorId: tyler,
        content: "Looking for a mobile developer to help build the companion app for SmartIrrigate. I've got working soil moisture sensors (Arduino + LoRa) and they're collecting real data from a test plot near Grand Island. Need someone who can build a clean iOS/Android app to display the readings and send alerts. Paying gig if it goes well — we're applying for an USDA grant.",
        category: "looking_for",
        createdAt: now - 6 * hour,
        updatedAt: now - 6 * hour,
      },
      {
        authorId: chris,
        content: "Pitched at Big Red Ventures last week and didn't win, but honestly learned more in that 10-minute Q&A than I did in a whole semester of entrepreneurship classes. The judges ripped our business model apart and they were right. If you're thinking about entering next round — do it. The feedback alone is worth it. Happy to help anyone prep their pitch.",
        category: "sharing",
        createdAt: now - 12 * hour,
        updatedAt: now - 12 * hour,
      },
      {
        authorId: maya,
        content: "Has anyone here done user interviews for a fintech product? Working on PennyWise (micro-savings for students) and I need to talk to 10 students about how they think about money. I have $5 Starbucks gift cards for anyone willing to do a 15-min interview. DM me!",
        category: "asking",
        createdAt: now - 18 * hour,
        updatedAt: now - 18 * hour,
      },
      {
        authorId: ethan,
        content: "Just wrapped filming on episode 2 of the UNL founder docuseries. This one follows a sophomore who started a tutoring marketplace from his dorm room and now has 30 tutors. His story is wild. Series drops next month — who wants a sneak peek?",
        category: "sharing",
        createdAt: now - 24 * hour,
        updatedAt: now - 24 * hour,
      },
      {
        authorId: alex,
        content: "Alright I'm just going to say it — I have a social commerce idea that I think could be huge for college campuses. I've got the growth plan, the marketing strategy, and the market research. What I DON'T have is someone who can build it. Looking for a technical co-founder who wants to go all in. Not a class project. A real company. DM me if you're serious.",
        category: "looking_for",
        createdAt: now - 30 * hour,
        updatedAt: now - 30 * hour,
      },
      {
        authorId: ava,
        content: "Ran 15 user interviews this week on how students pick their classes. The findings are honestly shocking — 73% said they choose classes based on what their FRIENDS are taking, not what aligns with their degree. Only 2 out of 15 had ever looked at their degree audit before registration. If anyone's building tools for students, your biggest competitor isn't another app — it's group chats and word of mouth.",
        category: "sharing",
        createdAt: now - 36 * hour,
        updatedAt: now - 36 * hour,
      },
      {
        authorId: marcus,
        content: "Just finished the new brand identity for the UNL Entrepreneurship Club. New logo, color system, social templates, the works. Honestly proud of this one — went from looking like a PowerPoint clip art situation to something that actually feels professional. If your student org needs branding help, I'm taking on 2 more projects this semester.",
        category: "sharing",
        createdAt: now - 42 * hour,
        updatedAt: now - 42 * hour,
      },
      {
        authorId: lisa,
        content: "Anyone else at UNL working with LLMs? I'm in Dr. Xu's NLP lab and building an AI study buddy for CSCE 310. Looking to start a casual study group / hack group for people interested in AI/ML. Nothing formal — just weekly meetups to share what we're building and learn from each other. Drop a comment if you're interested.",
        category: "asking",
        createdAt: now - 48 * hour,
        updatedAt: now - 48 * hour,
      },
      {
        authorId: noah,
        content: "Just finished a financial model template for student startups. It covers pre-revenue projections, unit economics, and fundraising scenarios. Free for anyone on Junto. I built it because I was tired of seeing founders pitch with made-up numbers. DM me and I'll send you the Google Sheet link.",
        category: "sharing",
        createdAt: now - 54 * hour,
        updatedAt: now - 54 * hour,
      },
      {
        authorId: caleb,
        content: "Need a software developer ASAP! Built a working smart bike lock prototype — GPS tracking, BLE unlock from your phone, tamper alerts. The hardware works. I need someone who can build the iOS app (BLE pairing, GPS display, push notifications for alerts). I'm in the NIC user space every day if you want to see the prototype. Campus bike theft is a real problem and this solves it.",
        category: "looking_for",
        createdAt: now - 60 * hour,
        updatedAt: now - 60 * hour,
      },
      {
        authorId: priya,
        content: "What's the best way to validate a startup idea if your market is small-town logistics companies? I'm researching last-mile delivery in rural Nebraska and I think there's a software opportunity, but I don't know how to reach these companies for interviews. They're not exactly on LinkedIn. Anyone have experience with rural/agricultural market research?",
        category: "asking",
        createdAt: now - 66 * hour,
        updatedAt: now - 66 * hour,
      },
    ];

    const postIds: Id<"posts">[] = [];
    for (const post of posts) {
      const id = await ctx.db.insert("posts", post);
      postIds.push(id);
    }

    return { inserted: postIds.length, postIds };
  },
});

// ============================================================
// SEED COMMENTS — realistic replies with @mentions
// ============================================================
export const seedComments = internalMutation({
  args: {},
  handler: async (ctx) => {
    const now = Date.now();
    const hour = 3600000;

    // Get users
    const sarah = await getUser(ctx, "test_sarah");
    const marcus = await getUser(ctx, "test_marcus");
    const jake = await getUser(ctx, "test_jake");
    const alex = await getUser(ctx, "test_alex");
    const jordan = await getUser(ctx, "test_jordan");
    const maya = await getUser(ctx, "test_maya");
    const chris = await getUser(ctx, "test_chris");
    const lisa = await getUser(ctx, "test_lisa");
    const david = await getUser(ctx, "test_david");
    const tyler = await getUser(ctx, "test_tyler");
    const ava = await getUser(ctx, "test_ava");
    const noah = await getUser(ctx, "test_noah");
    const caleb = await getUser(ctx, "test_caleb");
    const ethan = await getUser(ctx, "test_ethan");
    const sophie = await getUser(ctx, "test_sophie");
    const mia = await getUser(ctx, "test_mia");
    const daniel = await getUser(ctx, "test_daniel");

    if (!sarah || !marcus || !jake || !alex || !jordan || !maya || !chris || !lisa || !david || !tyler || !ava || !noah || !caleb || !ethan || !sophie || !mia || !daniel) {
      return "Missing users";
    }

    // Get posts in order (by createdAt desc)
    const posts = await ctx.db.query("posts").withIndex("by_created").order("desc").collect();
    if (posts.length < 12) return "Not enough posts — run seedPosts first";

    // Post 0 = Sarah's LostHusker launch (newest)
    // Post 1 = Tyler's SmartIrrigate looking_for
    // Post 2 = Chris's Big Red Ventures pitch
    // Post 3 = Maya's fintech interviews
    // Post 4 = Ethan's docuseries
    // Post 5 = Alex's co-founder search
    // Post 6 = Ava's class selection research
    // Post 7 = Marcus's branding
    // Post 8 = Lisa's AI/ML study group
    // Post 9 = Noah's financial model
    // Post 10 = Caleb's bike lock
    // Post 11 = Priya's rural logistics

    let count = 0;

    // Comments on Sarah's LostHusker (post 0)
    await ctx.db.insert("comments", {
      postId: posts[0]._id, authorId: marcus,
      content: "The UI looks so clean!! Did you design this yourself? If you need help polishing the brand I'm down 🔥",
      createdAt: now - 1.5 * hour,
    });
    await ctx.db.insert("comments", {
      postId: posts[0]._id, authorId: jake,
      content: "Congrats on shipping! SwiftUI? I'd love to see how you handled the image upload flow. Also @marcuswilliams is right the design is legit",
      mentions: [marcus],
      createdAt: now - 1 * hour,
    });
    await ctx.db.insert("comments", {
      postId: posts[0]._id, authorId: chris,
      content: "This is exactly the kind of thing UNL admin should be funding. Have you talked to anyone at housing? They'd probably promote this.",
      createdAt: now - 0.5 * hour,
    });
    count += 3;

    // Comments on Tyler's SmartIrrigate (post 1)
    await ctx.db.insert("comments", {
      postId: posts[1]._id, authorId: jake,
      content: "This is sick. I could build the iOS app — I've done BLE stuff before with Core Bluetooth. DM me?",
      createdAt: now - 5 * hour,
    });
    await ctx.db.insert("comments", {
      postId: posts[1]._id, authorId: david,
      content: "Would you be open to Flutter instead of native? I could build it cross-platform so Android farmers aren't left out. @jakethompson we could team up on this",
      mentions: [jake],
      createdAt: now - 4.5 * hour,
    });
    await ctx.db.insert("comments", {
      postId: posts[1]._id, authorId: chris,
      content: "The USDA grant angle is smart. I helped a team apply for SBIR last year — happy to review your application if you want a second pair of eyes.",
      createdAt: now - 4 * hour,
    });
    count += 3;

    // Comments on Chris's pitch experience (post 2)
    await ctx.db.insert("comments", {
      postId: posts[2]._id, authorId: noah,
      content: "This is so real. The financial questions are always what trips people up. @mayapatel and I have been working on templates to help with exactly this.",
      mentions: [maya],
      createdAt: now - 11 * hour,
    });
    await ctx.db.insert("comments", {
      postId: posts[2]._id, authorId: maya,
      content: "100%. The judges asked me about unit economics and I just froze. @noahkessler literally saved my pitch prep after that 😂",
      mentions: [noah],
      createdAt: now - 10 * hour,
    });
    count += 2;

    // Comments on Ava's research (post 6)
    await ctx.db.insert("comments", {
      postId: posts[6]._id, authorId: lisa,
      content: "73% based on friends?? That's wild but also makes total sense. Would love to see the full data if you're sharing. Could be useful for an AI advisor tool I'm thinking about.",
      createdAt: now - 34 * hour,
    });
    await ctx.db.insert("comments", {
      postId: posts[6]._id, authorId: maya,
      content: "This is gold. How did you recruit participants? I need to do something similar for PennyWise and I'm struggling to get people to sign up for interviews.",
      createdAt: now - 33 * hour,
    });
    await ctx.db.insert("comments", {
      postId: posts[6]._id, authorId: ava,
      content: "@mayapatel DM me! I have a whole system for recruiting. Short version: go to the Union during lunch, offer coffee, bring a sign. Works every time.",
      mentions: [maya],
      createdAt: now - 32 * hour,
    });
    count += 3;

    // Comments on Lisa's AI/ML study group (post 8)
    await ctx.db.insert("comments", {
      postId: posts[8]._id, authorId: jordan,
      content: "I'm in. I've been messing with fine-tuning small models for code review. Weekly meetups sound perfect.",
      createdAt: now - 46 * hour,
    });
    await ctx.db.insert("comments", {
      postId: posts[8]._id, authorId: sarah,
      content: "Yes! I've been wanting to add AI matching to LostHusker (match lost items to found items). Would love to learn more about embeddings.",
      createdAt: now - 45 * hour,
    });
    await ctx.db.insert("comments", {
      postId: posts[8]._id, authorId: daniel,
      content: "Can we include creative AI stuff too? I'm using ML for music generation and it'd be cool to share what I'm learning. Different use case but same fundamentals.",
      createdAt: now - 44 * hour,
    });
    count += 3;

    // Comments on Caleb's bike lock (post 10)
    await ctx.db.insert("comments", {
      postId: posts[10]._id, authorId: jake,
      content: "BLE + GPS on iOS? I literally just did this for another project. I'm in. When can I come see the prototype?",
      createdAt: now - 58 * hour,
    });
    await ctx.db.insert("comments", {
      postId: posts[10]._id, authorId: sophie,
      content: "If you need product branding for when you launch, I'd love to help. This has serious Kickstarter potential and good design would make it pop.",
      createdAt: now - 57 * hour,
    });
    await ctx.db.insert("comments", {
      postId: posts[10]._id, authorId: mia,
      content: "I could write a piece about this for the Daily Nebraskan. Campus bike theft is a hot topic and this is actually a real solution. DM me?",
      createdAt: now - 56 * hour,
    });
    count += 3;

    // Comments on Priya's logistics question (post 11)
    await ctx.db.insert("comments", {
      postId: posts[11]._id, authorId: tyler,
      content: "I grew up in Grand Island — I might know some people. A lot of these companies are family-run and you literally just have to call them or show up. DM me and I can connect you.",
      createdAt: now - 64 * hour,
    });
    await ctx.db.insert("comments", {
      postId: posts[11]._id, authorId: chris,
      content: "For rural market validation, forget digital outreach. Go to the Nebraska State Fair, farm equipment shows, co-op meetings. That's where these people are. @tylerreed is right — in-person is the only way.",
      mentions: [tyler],
      createdAt: now - 63 * hour,
    });
    count += 2;

    return { inserted: count };
  },
});

// ============================================================
// SEED CONNECTIONS — cross-discipline, realistic
// ============================================================
export const seedConnections = internalMutation({
  args: {},
  handler: async (ctx) => {
    const now = Date.now();
    const day = 86400000;

    const pairs: Array<[string, string, number, { type: string; label: string; referenceId?: string }]> = [
      // designer + developers
      ["test_marcus", "test_sarah", 10, { type: "post", label: "from their post about LostHusker" }],
      ["test_marcus", "test_jake", 8, { type: "match", label: "from your daily match" }],
      ["test_sophie", "test_caleb", 3, { type: "profile", label: "from their profile" }],
      // business + tech
      ["test_chris", "test_maya", 7, { type: "event", label: "from Pitch Night" }],
      ["test_noah", "test_maya", 5, { type: "match", label: "from your daily match" }],
      ["test_alex", "test_jordan", 4, { type: "search", label: "from search" }],
      // research + builders
      ["test_ava", "test_lisa", 6, { type: "profile", label: "from their profile" }],
      ["test_emily", "test_sarah", 9, { type: "post", label: "from their post about needing a designer" }],
      // agtech connections
      ["test_tyler", "test_jake", 3, { type: "match", label: "from your daily match" }],
      ["test_tyler", "test_priya", 2, { type: "event", label: "from AgTech Demo Day" }],
    ];

    let count = 0;
    for (const [requesterClerk, accepterClerk, daysAgo, source] of pairs) {
      const requester = await getUser(ctx, requesterClerk);
      const accepter = await getUser(ctx, accepterClerk);
      if (!requester || !accepter) continue;

      // Check if already exists
      const existing = await ctx.db
        .query("connections")
        .withIndex("by_requester", (q) => q.eq("requesterId", requester))
        .filter((q) => q.eq(q.field("accepterId"), accepter))
        .first();
      if (existing) continue;

      await ctx.db.insert("connections", {
        requesterId: requester,
        accepterId: accepter,
        status: "connected",
        source,
        connectedAt: now - daysAgo * day,
        createdAt: now - (daysAgo + 1) * day,
      });
      count++;
    }

    return { inserted: count };
  },
});

// ============================================================
// SEED CONVERSATIONS + MESSAGES — real DM threads
// ============================================================
export const seedConversations = internalMutation({
  args: {},
  handler: async (ctx) => {
    const now = Date.now();
    const hour = 3600000;
    const min = 60000;

    // Helper for canonical ordering
    function canonical(a: Id<"users">, b: Id<"users">) {
      return a < b ? { p1: a, p2: b } : { p1: b, p2: a };
    }

    const sarah = await getUser(ctx, "test_sarah");
    const marcus = await getUser(ctx, "test_marcus");
    const jake = await getUser(ctx, "test_jake");
    const tyler = await getUser(ctx, "test_tyler");
    const caleb = await getUser(ctx, "test_caleb");
    const maya = await getUser(ctx, "test_maya");
    const noah = await getUser(ctx, "test_noah");

    if (!sarah || !marcus || !jake || !tyler || !caleb || !maya || !noah) {
      return "Missing users";
    }

    let convCount = 0;

    // --- Conversation 1: Sarah + Marcus (designer helping with LostHusker) ---
    const c1 = canonical(sarah, marcus);
    const conv1 = await ctx.db.insert("conversations", {
      participant1Id: c1.p1,
      participant2Id: c1.p2,
      lastMessageAt: now - 3 * hour,
      lastMessagePreview: "Thursday at 2 works. See you at the Union!",
      lastMessageSenderId: marcus,
      participant1UnreadCount: 0,
      participant2UnreadCount: 0,
      status: "active",
      initiatorId: marcus,
      createdAt: now - 48 * hour,
    });

    const conv1Messages = [
      { senderId: marcus, content: "Hey Sarah! Saw your LostHusker post — the concept is really cool. I have some ideas for the UI if you're interested in collaborating.", createdAt: now - 48 * hour },
      { senderId: sarah, content: "Marcus!! Yes I was literally about to DM you. The app works but the design is very... engineer-coded lol. Would love your help.", createdAt: now - 47 * hour },
      { senderId: marcus, content: "Haha I could tell 😂 No shade though, the functionality looks solid. I'm thinking we could do a quick design sprint — I'll mock up some screens in Figma and we iterate from there?", createdAt: now - 46 * hour },
      { senderId: sarah, content: "That would be amazing. I'm free Thursday afternoon if you want to meet up and go through it?", createdAt: now - 24 * hour },
      { senderId: marcus, content: "Thursday at 2 works. See you at the Union!", createdAt: now - 3 * hour },
    ];

    for (const msg of conv1Messages) {
      await ctx.db.insert("messages", { conversationId: conv1, ...msg, readAt: now });
    }
    convCount++;

    // --- Conversation 2: Jake + Tyler (mobile app for SmartIrrigate) ---
    const c2 = canonical(jake, tyler);
    const conv2 = await ctx.db.insert("conversations", {
      participant1Id: c2.p1,
      participant2Id: c2.p2,
      lastMessageAt: now - 5 * hour,
      lastMessagePreview: "I'll bring the sensors. Prepare to be impressed 😤",
      lastMessageSenderId: tyler,
      participant1UnreadCount: 0,
      participant2UnreadCount: 0,
      status: "active",
      initiatorId: jake,
      createdAt: now - 24 * hour,
    });

    const conv2Messages = [
      { senderId: jake, content: "Tyler! Your SmartIrrigate project is sick. I've worked with Core Bluetooth before and I could definitely build the iOS companion app. When can I see the hardware?", createdAt: now - 24 * hour },
      { senderId: tyler, content: "Dude yes! I've got a working prototype in my garage. The sensor reads soil moisture every 15 min and sends data via LoRa to a gateway. Right now I'm just logging to a CSV lol", createdAt: now - 23 * hour },
      { senderId: jake, content: "Lmao CSV to App Store pipeline. I can work with that though. I'm thinking SwiftUI for the app, real-time charts for the readings, push alerts when soil gets too dry. Could be really clean.", createdAt: now - 22 * hour },
      { senderId: tyler, content: "That's exactly what I'm picturing. Can you come out to Lincoln this weekend? I can demo the whole setup.", createdAt: now - 8 * hour },
      { senderId: jake, content: "Saturday works for me. Send me the address", createdAt: now - 7 * hour },
      { senderId: tyler, content: "I'll bring the sensors. Prepare to be impressed 😤", createdAt: now - 5 * hour },
    ];

    for (const msg of conv2Messages) {
      await ctx.db.insert("messages", { conversationId: conv2, ...msg, readAt: now });
    }
    convCount++;

    // --- Conversation 3: Maya + Noah (fintech pitch prep) ---
    const c3 = canonical(maya, noah);
    const conv3 = await ctx.db.insert("conversations", {
      participant1Id: c3.p1,
      participant2Id: c3.p2,
      lastMessageAt: now - 10 * hour,
      lastMessagePreview: "You're going to crush it. Let me know how it goes!",
      lastMessageSenderId: noah,
      participant1UnreadCount: 0,
      participant2UnreadCount: 0,
      status: "active",
      initiatorId: maya,
      createdAt: now - 72 * hour,
    });

    const conv3Messages = [
      { senderId: maya, content: "Noah, saw your post about financial model templates. I'm working on PennyWise and my numbers are... not great. Could you help me build a proper model?", createdAt: now - 72 * hour },
      { senderId: noah, content: "Of course! Fintech models are actually my favorite to build. What stage are you at? Do you have any revenue projections yet?", createdAt: now - 71 * hour },
      { senderId: maya, content: "Pre-revenue, pre-launch 😅 But I have user interview data on willingness to pay and I know the round-up model. Just need to make it make sense on paper.", createdAt: now - 70 * hour },
      { senderId: noah, content: "That's totally fine. I'll build you a bottoms-up model. Send me your user interview notes and any assumptions you have. I can have a first draft by Friday.", createdAt: now - 48 * hour },
      { senderId: maya, content: "You're amazing. Sent you the notes. I'm pitching at the Center for Entrepreneurship event next week so this is perfect timing.", createdAt: now - 36 * hour },
      { senderId: noah, content: "You're going to crush it. Let me know how it goes!", createdAt: now - 10 * hour },
    ];

    for (const msg of conv3Messages) {
      await ctx.db.insert("messages", { conversationId: conv3, ...msg, readAt: now });
    }
    convCount++;

    return { conversations: convCount };
  },
});

// ============================================================
// SEED EVENTS — Center for Entrepreneurship + community
// ============================================================
export const seedEvents = internalMutation({
  args: {},
  handler: async (ctx) => {
    const now = Date.now();

    const chris = await getUser(ctx, "test_chris");
    const sarah = await getUser(ctx, "test_sarah");
    if (!chris || !sarah) return "Missing users";

    // Get several users for RSVPs
    const allUsers = await ctx.db.query("users").collect();
    const testUsers = allUsers.filter(m => m.clerkId.startsWith("test_"));

    // Event 1: Center for Entrepreneurship Pitch Night (March 20)
    const mar20 = new Date("2026-03-20T18:00:00-05:00").getTime();
    const event1 = await ctx.db.insert("events", {
      title: "CENTER FOR ENTREPRENEURSHIP: SPRING PITCH NIGHT",
      description: "Pitch your startup idea in 5 minutes. Get feedback from judges, mentors, and fellow founders. Open to all UNL students — whether you have a working product or just a napkin sketch.\n\nPrizes:\n• 1st Place: $500 + mentorship session with Sam Nelson\n• 2nd Place: $250\n• Audience Choice: $100\n\nFood and drinks provided by the Center for Entrepreneurship.",
      date: mar20,
      endDate: mar20 + 3 * 3600000,
      location: "Lincoln, NE",
      fullAddress: "Howard L. Hawks Hall, 730 N 14th St, Lincoln, NE 68588",
      type: "in_person",
      imageUrl: "https://images.unsplash.com/photo-1475721027785-f74eccf877e2?w=800&h=600&fit=crop",
      createdBy: chris,
      createdAt: now - 5 * 86400000,
    });

    // Add 10 RSVPs to pitch night
    for (let i = 0; i < Math.min(10, testUsers.length); i++) {
      await ctx.db.insert("eventRsvps", {
        eventId: event1,
        userId: testUsers[i]._id,
        status: "going",
        createdAt: now - (4 - i * 0.3) * 86400000,
      });
    }

    // Event 2: JUNTO User Meetup (March 14)
    const mar14 = new Date("2026-03-14T14:00:00-05:00").getTime();
    const event2 = await ctx.db.insert("events", {
      title: "JUNTO USER MEETUP",
      description: "Casual meetup for anyone building something. Bring your laptop, bring your prototype, bring your half-baked idea. No pitch decks, no pressure — just show people what you're working on and get real feedback.\n\nWe'll have tables set up for quick demos and plenty of time to mingle.\n\nCoffee provided.",
      date: mar14,
      endDate: mar14 + 2 * 3600000,
      location: "Lincoln, NE",
      fullAddress: "The Mill Coffee, 800 P St, Lincoln, NE 68508",
      type: "in_person",
      imageUrl: "https://images.unsplash.com/photo-1528605248644-14dd04022da1?w=800&h=600&fit=crop",
      createdBy: sarah,
      createdAt: now - 3 * 86400000,
    });

    // Add 6 RSVPs to user meetup
    for (let i = 0; i < Math.min(6, testUsers.length); i++) {
      await ctx.db.insert("eventRsvps", {
        eventId: event2,
        userId: testUsers[i]._id,
        status: "going",
        createdAt: now - (2 - i * 0.2) * 86400000,
      });
    }

    return { events: 2 };
  },
});

// ============================================================
// SEED NOTIFICATIONS — makes the bell icon feel alive
// ============================================================
export const seedNotifications = internalMutation({
  args: {},
  handler: async (ctx) => {
    const now = Date.now();
    const hour = 3600000;

    const sarah = await getUser(ctx, "test_sarah");
    const marcus = await getUser(ctx, "test_marcus");
    const jake = await getUser(ctx, "test_jake");
    const chris = await getUser(ctx, "test_chris");
    const lisa = await getUser(ctx, "test_lisa");
    const tyler = await getUser(ctx, "test_tyler");

    if (!sarah || !marcus || !jake || !chris || !lisa || !tyler) return "Missing users";

    // Get a real post for context
    const posts = await ctx.db.query("posts").withIndex("by_created").order("desc").collect();

    const notifications = [
      {
        recipientId: sarah,
        type: "comment",
        title: "Marcus Williams commented on your post",
        body: "The UI looks so clean!! Did you design this yourself?",
        data: { postId: posts[0]?._id, senderId: marcus },
        createdAt: now - 1.5 * hour,
      },
      {
        recipientId: sarah,
        type: "comment",
        title: "Jake Thompson commented on your post",
        body: "Congrats on shipping! SwiftUI?",
        data: { postId: posts[0]?._id, senderId: jake },
        createdAt: now - 1 * hour,
      },
      {
        recipientId: sarah,
        type: "connection_accepted",
        title: "Emily Rodriguez accepted your connection request",
        data: { senderId: sarah },
        createdAt: now - 12 * hour,
      },
      {
        recipientId: tyler,
        type: "comment",
        title: "Jake Thompson commented on your post",
        body: "This is sick. I could build the iOS app",
        data: { postId: posts[1]?._id, senderId: jake },
        createdAt: now - 5 * hour,
      },
      {
        recipientId: marcus,
        type: "mention",
        title: "Jake Thompson mentioned you in a comment",
        body: "@marcuswilliams is right the design is legit",
        data: { postId: posts[0]?._id, senderId: jake },
        createdAt: now - 1 * hour,
      },
      {
        recipientId: lisa,
        type: "comment",
        title: "Jordan Kim commented on your post",
        body: "I'm in. I've been messing with fine-tuning small models",
        data: { postId: posts[8]?._id, senderId: jake },
        createdAt: now - 46 * hour,
      },
    ];

    let count = 0;
    for (const notif of notifications) {
      await ctx.db.insert("notifications", notif);
      count++;
    }

    return { inserted: count };
  },
});

// ============================================================
// SEED KENNY'S DMs — messages TO Kenny's real account
// ============================================================
export const seedKennyMessages = internalMutation({
  args: {},
  handler: async (ctx) => {
    const now = Date.now();
    const hour = 3600000;

    // Find Kenny's real account
    const kenny = await ctx.db
      .query("users")
      .filter((q) => q.eq(q.field("email"), "kennymorales308@gmail.com"))
      .first();

    if (!kenny) {
      // Try by other possible emails
      const kenny2 = await ctx.db
        .query("users")
        .filter((q) => q.eq(q.field("email"), "kmorales9@huskers.unl.edu"))
        .first();
      if (!kenny2) {
        // Last resort: find any non-test user
        const allUsers = await ctx.db.query("users").collect();
        const realUsers = allUsers.filter(m => !m.clerkId.startsWith("test_"));
        if (realUsers.length === 0) return "Kenny's account not found — sign in to the app first, then re-run";
        return `Found non-test users but none match email. Accounts found: ${realUsers.map(m => m.email || m.name).join(", ")}`;
      }
    }

    const kennyId = kenny ? kenny._id : null;
    if (!kennyId) return "Kenny not found";

    function canonical(a: Id<"users">, b: Id<"users">) {
      return a < b ? { p1: a, p2: b } : { p1: b, p2: a };
    }

    const chris = await getUser(ctx, "test_chris");
    const marcus = await getUser(ctx, "test_marcus");
    const maya = await getUser(ctx, "test_maya");
    const caleb = await getUser(ctx, "test_caleb");
    const mia = await getUser(ctx, "test_mia");
    const alex = await getUser(ctx, "test_alex");

    if (!chris || !marcus || !maya || !caleb || !mia || !alex) return "Missing test users";

    let convCount = 0;

    // --- DM 1: Chris Anderson reaching out about mentoring ---
    const c1 = canonical(kennyId, chris);
    const existing1 = await ctx.db.query("conversations")
      .withIndex("by_participant1", (q) => q.eq("participant1Id", c1.p1))
      .filter((q) => q.eq(q.field("participant2Id"), c1.p2))
      .first();
    if (!existing1) {
      const conv1 = await ctx.db.insert("conversations", {
        participant1Id: c1.p1, participant2Id: c1.p2,
        lastMessageAt: now - 4 * hour,
        lastMessagePreview: "Let's grab coffee this week and I'll walk you through what worked for me.",
        lastMessageSenderId: chris,
        participant1UnreadCount: kennyId === c1.p1 ? 1 : 0,
        participant2UnreadCount: kennyId === c1.p2 ? 1 : 0,
        status: "active", initiatorId: chris, createdAt: now - 48 * hour,
      });
      const msgs1 = [
        { senderId: chris, content: "Hey Kenny! I've been hearing about onjunto.com and what you're building. Honestly impressed — it's exactly what UNL needs. I went through a similar journey with my first startup and made every mistake in the book.", createdAt: now - 48 * hour },
        { senderId: kennyId, content: "Chris! Thanks man that means a lot. I've seen your posts about Big Red Ventures — you clearly know the pitch game. Would love to pick your brain sometime.", createdAt: now - 36 * hour },
        { senderId: chris, content: "Anytime. Biggest lesson I learned: don't pitch features, pitch the problem. If Sam Nelson's team can feel the pain you're solving, the deal closes itself.", createdAt: now - 24 * hour },
        { senderId: kennyId, content: "That's real. I have a meeting with Sam tomorrow actually — pitching onjunto.com as a campus partner. Any tips?", createdAt: now - 12 * hour },
        { senderId: chris, content: "Lead with what HIS team cares about — student engagement data, event ROI, skills gaps. Don't talk about your tech stack. Talk about what he can report to his dean. Also — ask for the money confidently. Don't apologize for pricing.", createdAt: now - 8 * hour },
        { senderId: chris, content: "Let's grab coffee this week and I'll walk you through what worked for me.", createdAt: now - 4 * hour },
      ];
      for (const msg of msgs1) {
        await ctx.db.insert("messages", { conversationId: conv1, ...msg });
      }
      convCount++;
    }

    // --- DM 2: Marcus wanting to help with design ---
    const c2 = canonical(kennyId, marcus);
    const existing2 = await ctx.db.query("conversations")
      .withIndex("by_participant1", (q) => q.eq("participant1Id", c2.p1))
      .filter((q) => q.eq(q.field("participant2Id"), c2.p2))
      .first();
    if (!existing2) {
      const conv2 = await ctx.db.insert("conversations", {
        participant1Id: c2.p1, participant2Id: c2.p2,
        lastMessageAt: now - 6 * hour,
        lastMessagePreview: "Sounds good! I'll have some concepts ready by Thursday.",
        lastMessageSenderId: marcus,
        participant1UnreadCount: 0, participant2UnreadCount: 0,
        status: "active", initiatorId: marcus, createdAt: now - 72 * hour,
      });
      const msgs2 = [
        { senderId: marcus, content: "Kenny — I've been using onjunto.com and the app is legit. But I think the brand identity could be even stronger. Would you be open to me doing a quick brand refresh? Logo, color palette, typography. No charge — I want this in my portfolio.", createdAt: now - 72 * hour },
        { senderId: kennyId, content: "Bro are you serious?? That would be incredible. The current branding was me in Figma at 2am lol", createdAt: now - 60 * hour },
        { senderId: marcus, content: "Haha I could tell 😂 But that's the beauty of it — the product is strong, we just need the wrapper to match. I'll put together a mood board and some logo concepts this week.", createdAt: now - 48 * hour },
        { senderId: kennyId, content: "You're the best. I have a big meeting with the Center for Entrepreneurship tomorrow so if you have anything even rough I could show that would be amazing", createdAt: now - 24 * hour },
        { senderId: marcus, content: "Sounds good! I'll have some concepts ready by Thursday.", createdAt: now - 6 * hour },
      ];
      for (const msg of msgs2) {
        await ctx.db.insert("messages", { conversationId: conv2, ...msg, readAt: now });
      }
      convCount++;
    }

    // --- DM 3: Caleb pitching his bike lock collab ---
    const c3 = canonical(kennyId, caleb);
    const existing3 = await ctx.db.query("conversations")
      .withIndex("by_participant1", (q) => q.eq("participant1Id", c3.p1))
      .filter((q) => q.eq(q.field("participant2Id"), c3.p2))
      .first();
    if (!existing3) {
      const conv3 = await ctx.db.insert("conversations", {
        participant1Id: c3.p1, participant2Id: c3.p2,
        lastMessageAt: now - 10 * hour,
        lastMessagePreview: "Come by the NIC user space anytime — I'm there most afternoons",
        lastMessageSenderId: caleb,
        participant1UnreadCount: kennyId === c3.p1 ? 1 : 0,
        participant2UnreadCount: kennyId === c3.p2 ? 1 : 0,
        status: "active", initiatorId: caleb, createdAt: now - 30 * hour,
      });
      const msgs3 = [
        { senderId: caleb, content: "Hey Kenny, saw you built onjunto.com — the platform is exactly what I've been looking for. I built a smart bike lock prototype and I need a software dev for the companion app. Know anyone who might be interested?", createdAt: now - 30 * hour },
        { senderId: kennyId, content: "That's dope! I saw your post about it. You should connect with Jake Thompson on here — he's done BLE stuff on iOS before", createdAt: now - 20 * hour },
        { senderId: caleb, content: "Already DMed him! This platform is actually making things happen. Also — if you ever want to feature hardware projects on the platform, I'd love to help. There's a whole user community at the NIC that doesn't know about onjunto.com yet.", createdAt: now - 15 * hour },
        { senderId: caleb, content: "Come by the NIC user space anytime — I'm there most afternoons", createdAt: now - 10 * hour },
      ];
      for (const msg of msgs3) {
        await ctx.db.insert("messages", { conversationId: conv3, ...msg });
      }
      convCount++;
    }

    // --- DM 4: Mia wanting to write about onjunto.com ---
    const c4 = canonical(kennyId, mia);
    const existing4 = await ctx.db.query("conversations")
      .withIndex("by_participant1", (q) => q.eq("participant1Id", c4.p1))
      .filter((q) => q.eq(q.field("participant2Id"), c4.p2))
      .first();
    if (!existing4) {
      const conv4 = await ctx.db.insert("conversations", {
        participant1Id: c4.p1, participant2Id: c4.p2,
        lastMessageAt: now - 3 * hour,
        lastMessagePreview: "Perfect — I'll send you some questions tonight and we can do the interview Thursday?",
        lastMessageSenderId: mia,
        participant1UnreadCount: kennyId === c4.p1 ? 1 : 0,
        participant2UnreadCount: kennyId === c4.p2 ? 1 : 0,
        status: "active", initiatorId: mia, createdAt: now - 20 * hour,
      });
      const msgs4 = [
        { senderId: mia, content: "Hi Kenny! I write for the Daily Nebraskan and I'm working on a piece about student-built tech at UNL. onjunto.com keeps coming up in conversations. Would you be down for an interview?", createdAt: now - 20 * hour },
        { senderId: kennyId, content: "That would be awesome! I'd love to talk about it. What angle are you going for?", createdAt: now - 16 * hour },
        { senderId: mia, content: "The story is about how UNL students are building real products, not just homework projects. onjunto.com is the perfect example — a student built a platform that other students are actually using to find collaborators. It writes itself.", createdAt: now - 10 * hour },
        { senderId: mia, content: "Perfect — I'll send you some questions tonight and we can do the interview Thursday?", createdAt: now - 3 * hour },
      ];
      for (const msg of msgs4) {
        await ctx.db.insert("messages", { conversationId: conv4, ...msg });
      }
      convCount++;
    }

    // --- DM 5: Alex wanting to team up on growth ---
    const c5 = canonical(kennyId, alex);
    const existing5 = await ctx.db.query("conversations")
      .withIndex("by_participant1", (q) => q.eq("participant1Id", c5.p1))
      .filter((q) => q.eq(q.field("participant2Id"), c5.p2))
      .first();
    if (!existing5) {
      const conv5 = await ctx.db.insert("conversations", {
        participant1Id: c5.p1, participant2Id: c5.p2,
        lastMessageAt: now - 8 * hour,
        lastMessagePreview: "I'm serious — let's talk about how we can help each other grow",
        lastMessageSenderId: alex,
        participant1UnreadCount: kennyId === c5.p1 ? 1 : 0,
        participant2UnreadCount: kennyId === c5.p2 ? 1 : 0,
        status: "active", initiatorId: alex, createdAt: now - 36 * hour,
      });
      const msgs5 = [
        { senderId: alex, content: "Kenny — real talk. I've been looking for a technical co-founder and what you've built with onjunto.com tells me you can actually ship. I have a social commerce idea I think could be huge on college campuses. Interested in hearing the pitch?", createdAt: now - 36 * hour },
        { senderId: kennyId, content: "I appreciate the compliment! I'm pretty heads-down on onjunto.com and FindU right now but I'd love to hear what you're thinking", createdAt: now - 28 * hour },
        { senderId: alex, content: "Totally get it. Even if the timing isn't right for the co-founder thing, I think we could help each other. I know growth and marketing, you know product and engineering. Could be a good trade — I help with onjunto.com growth strategy, you give me feedback on my product idea.", createdAt: now - 18 * hour },
        { senderId: alex, content: "I'm serious — let's talk about how we can help each other grow", createdAt: now - 8 * hour },
      ];
      for (const msg of msgs5) {
        await ctx.db.insert("messages", { conversationId: conv5, ...msg });
      }
      convCount++;
    }

    return { conversations: convCount, note: `Messages seeded for ${kenny?.name ?? "unknown"} (${kenny?.email ?? "unknown"})` };
  },
});

// ============================================================
// SEED KENNY'S MESSAGE REQUESTS — people reaching out cold
// ============================================================
export const seedKennyRequests = internalMutation({
  args: {},
  handler: async (ctx) => {
    const now = Date.now();
    const hour = 3600000;

    const kenny = await ctx.db
      .query("users")
      .filter((q) => q.eq(q.field("email"), "kennymorales308@gmail.com"))
      .first();
    if (!kenny) return "Kenny's account not found";
    const kennyId = kenny._id;

    function canonical(a: Id<"users">, b: Id<"users">) {
      return a < b ? { p1: a, p2: b } : { p1: b, p2: a };
    }

    const ethan = await getUser(ctx, "test_ethan");
    const sophie = await getUser(ctx, "test_sophie");
    const tyler = await getUser(ctx, "test_tyler");
    const lisa = await getUser(ctx, "test_lisa");

    if (!ethan || !sophie || !tyler || !lisa) return "Missing test users";

    let count = 0;

    // --- Request 1: Ethan wants to film Kenny for the docuseries ---
    const c1 = canonical(kennyId, ethan);
    const existing1 = await ctx.db.query("conversations")
      .withIndex("by_participant1", (q) => q.eq("participant1Id", c1.p1))
      .filter((q) => q.eq(q.field("participant2Id"), c1.p2))
      .first();
    if (!existing1) {
      const conv = await ctx.db.insert("conversations", {
        participant1Id: c1.p1, participant2Id: c1.p2,
        lastMessageAt: now - 2 * hour,
        lastMessagePreview: "Would love to feature you and onjunto.com in the series — your story is exactly what this project is about.",
        lastMessageSenderId: ethan,
        participant1UnreadCount: kennyId === c1.p1 ? 1 : 0,
        participant2UnreadCount: kennyId === c1.p2 ? 1 : 0,
        status: "request", initiatorId: ethan, createdAt: now - 2 * hour,
      });
      await ctx.db.insert("messages", {
        conversationId: conv, senderId: ethan,
        content: "Hey Kenny! I'm filming a docuseries on student entrepreneurs at UNL and everyone keeps telling me I need to talk to you. Would love to feature you and onjunto.com in the series — your story is exactly what this project is about.",
        createdAt: now - 2 * hour,
      });
      count++;
    }

    // --- Request 2: Sophie offering brand design help ---
    const c2 = canonical(kennyId, sophie);
    const existing2 = await ctx.db.query("conversations")
      .withIndex("by_participant1", (q) => q.eq("participant1Id", c2.p1))
      .filter((q) => q.eq(q.field("participant2Id"), c2.p2))
      .first();
    if (!existing2) {
      const conv = await ctx.db.insert("conversations", {
        participant1Id: c2.p1, participant2Id: c2.p2,
        lastMessageAt: now - 5 * hour,
        lastMessagePreview: "I'd love to do a brand case study on onjunto.com for my thesis — would be free work for you and great portfolio material for me.",
        lastMessageSenderId: sophie,
        participant1UnreadCount: kennyId === c2.p1 ? 1 : 0,
        participant2UnreadCount: kennyId === c2.p2 ? 1 : 0,
        status: "request", initiatorId: sophie, createdAt: now - 5 * hour,
      });
      await ctx.db.insert("messages", {
        conversationId: conv, senderId: sophie,
        content: "Hi Kenny! I'm a senior in graphic design and my thesis is on how design builds trust for early-stage brands. I'd love to do a brand case study on onjunto.com for my thesis — would be free work for you and great portfolio material for me.",
        createdAt: now - 5 * hour,
      });
      count++;
    }

    // --- Request 3: Tyler wanting to partner on agtech ---
    const c3 = canonical(kennyId, tyler);
    const existing3 = await ctx.db.query("conversations")
      .withIndex("by_participant1", (q) => q.eq("participant1Id", c3.p1))
      .filter((q) => q.eq(q.field("participant2Id"), c3.p2))
      .first();
    if (!existing3) {
      const conv = await ctx.db.insert("conversations", {
        participant1Id: c3.p1, participant2Id: c3.p2,
        lastMessageAt: now - 7 * hour,
        lastMessagePreview: "Saw you're from Grand Island too — we should link up. I think onjunto.com could be huge for connecting rural students with the Lincoln tech scene.",
        lastMessageSenderId: tyler,
        participant1UnreadCount: kennyId === c3.p1 ? 1 : 0,
        participant2UnreadCount: kennyId === c3.p2 ? 1 : 0,
        status: "request", initiatorId: tyler, createdAt: now - 7 * hour,
      });
      await ctx.db.insert("messages", {
        conversationId: conv, senderId: tyler,
        content: "Yo Kenny — saw you're from Grand Island too. Small world. I think onjunto.com could be huge for connecting rural students with the Lincoln tech scene. A lot of us commute and don't have the same network. Would love to chat about it.",
        createdAt: now - 7 * hour,
      });
      count++;
    }

    // --- Request 4: Lisa wanting to add AI features ---
    const c4 = canonical(kennyId, lisa);
    const existing4 = await ctx.db.query("conversations")
      .withIndex("by_participant1", (q) => q.eq("participant1Id", c4.p1))
      .filter((q) => q.eq(q.field("participant2Id"), c4.p2))
      .first();
    if (!existing4) {
      const conv = await ctx.db.insert("conversations", {
        participant1Id: c4.p1, participant2Id: c4.p2,
        lastMessageAt: now - 1 * hour,
        lastMessagePreview: "I noticed you're using embeddings for matching — I have some ideas on how to make the ranking way better. Can we talk?",
        lastMessageSenderId: lisa,
        participant1UnreadCount: kennyId === c4.p1 ? 1 : 0,
        participant2UnreadCount: kennyId === c4.p2 ? 1 : 0,
        status: "request", initiatorId: lisa, createdAt: now - 1 * hour,
      });
      await ctx.db.insert("messages", {
        conversationId: conv, senderId: lisa,
        content: "Hey! I'm in Dr. Xu's NLP lab and I've been playing around with onjunto.com. I noticed you're using embeddings for matching — I have some ideas on how to make the ranking way better using a re-ranking approach we've been researching. Can we talk?",
        createdAt: now - 1 * hour,
      });
      count++;
    }

    return { requests: count };
  },
});

// ============================================================
// MASTER SEED — runs everything in order
// ============================================================
export const seedFullDemo = internalAction({
  args: {},
  handler: async (ctx) => {
    console.log("Clearing all existing data...");
    const clearResult: any = await ctx.runMutation(internal.seed.clearAll, {});
    console.log(`Cleared ${clearResult.cleared} records`);

    console.log("Seeding 20 users...");
    const userResult: any = await ctx.runMutation(internal.seed.seedUsers, {});
    console.log(`Seeded ${userResult.inserted} users`);

    console.log("Seeding posts...");
    const postResult: any = await ctx.runMutation(internal.seed.seedPosts, {});
    console.log(`Seeded ${postResult.inserted} posts`);

    console.log("Seeding comments...");
    const commentResult: any = await ctx.runMutation(internal.seed.seedComments, {});
    console.log(`Seeded ${commentResult.inserted} comments`);

    console.log("Seeding connections...");
    const connectionResult: any = await ctx.runMutation(internal.seed.seedConnections, {});
    console.log(`Seeded ${connectionResult.inserted} connections`);

    console.log("Seeding conversations + messages...");
    const convoResult: any = await ctx.runMutation(internal.seed.seedConversations, {});
    console.log(`Seeded ${convoResult.conversations} conversations`);

    console.log("Seeding events...");
    const eventResult: any = await ctx.runMutation(internal.seed.seedEvents, {});
    console.log(`Seeded ${eventResult.events} events`);

    console.log("Seeding notifications...");
    const notifResult: any = await ctx.runMutation(internal.seed.seedNotifications, {});
    console.log(`Seeded ${notifResult.inserted} notifications`);

    console.log("Generating AI embeddings...");
    try {
      const embeddingResult: any = await ctx.runAction(internal.embeddings.generateAllEmbeddings, {});
      console.log(`Generated embeddings for ${embeddingResult.processed} users`);
    } catch (e) {
      console.log("Embeddings failed (OpenAI key may be missing) — skipping");
    }

    console.log("Demo seed complete!");

    return {
      users: userResult.inserted,
      posts: postResult.inserted,
      comments: commentResult.inserted,
      connections: connectionResult.inserted,
      conversations: convoResult.conversations,
      events: eventResult.events,
      notifications: notifResult.inserted,
    };
  },
});
