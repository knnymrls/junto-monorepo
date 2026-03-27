import { internalMutation } from "./_generated/server";
import { Id } from "./_generated/dataModel";

const DAY = 86400000;
const HOUR = 3600000;

// ============================================================
// Rich demo data for the onjunto.com university dashboard
// Run: npx convex run seedDashboard:seedAll
// ============================================================

// Unsplash face photos for realistic avatars
const FACES = [
  "photo-1494790108377-be9c29b29330", // Sarah
  "photo-1507003211169-0a1dd7228f2d", // Marcus
  "photo-1438761681033-6461ffad8d80", // Emily
  "photo-1500648767791-00dcc994a43e", // Jake
  "photo-1472099645785-5658abf4ff4e", // Alex
  "photo-1519345182560-3f2917c472ef", // Jordan
  "photo-1534528741775-53994a69daeb", // Maya
  "photo-1560250097-0b93528c311a", // Chris
  "photo-1573497019940-1c28c88b4f3e", // Lisa
  "photo-1506794778202-cad84cf45f1d", // David
  "photo-1580489944761-15a19d654956", // 11
  "photo-1544005313-94ddf0286df2", // 12
  "photo-1531746020798-e6953c6e8e04", // 13
  "photo-1522075469751-3a6694fb2f61", // 14
  "photo-1504257432389-52343af06ae3", // 15
  "photo-1557862921-37829c790f19", // 16
  "photo-1548142813-c348350df52b", // 17
  "photo-1544723795-3fb6469f5b39", // 18
  "photo-1542206395-9feb3edaa68d", // 19
  "photo-1529626455594-4ff0802cfb7e", // 20
  "photo-1607746882042-944635dfe10e", // 21
  "photo-1463453091185-61582044d556", // 22
  "photo-1488426862026-3ee34a7d66df", // 23
  "photo-1502823403499-6ccfcf4fb453", // 24
  "photo-1517841905240-472988babdf9", // 25
  "photo-1539571696357-5a69c17a67c6", // 26
  "photo-1517365830460-955ce3ccd263", // 27
  "photo-1487412720507-e7ab37603c6f", // 28
  "photo-1524504388940-b1c1722653e1", // 29
  "photo-1552058544-f2b08422138a", // 30
];

function face(i: number) {
  return `https://images.unsplash.com/${FACES[i % FACES.length]}?w=200&h=200&fit=crop&crop=face`;
}

// All 30+ users for the demo
const USERS = [
  // ── Existing 10 (unchanged to preserve their IDs) ──
  { clerkId: "test_sarah", name: "Sarah Chen", headline: "CS Junior — building a campus lost-and-found app", skills: ["React", "TypeScript", "Node.js", "PostgreSQL", "GraphQL"], interests: ["FoodTech", "AI", "Developer Tools"], lookingFor: "Co-founder with business/marketing skills", canHelpWith: "Frontend development, API design, code reviews", currentProject: "AI-powered recipe generator", bio: "Passionate about building beautiful, performant web apps.", role: "student" },
  { clerkId: "test_marcus", name: "Marcus Williams", headline: "Graphic Design Senior — branding & UI", skills: ["Figma", "Design Systems", "User Research", "Prototyping", "Framer"], interests: ["DesignOps", "Accessibility", "Mobile"], lookingFor: "Developers to collaborate with", canHelpWith: "UI/UX design, design systems, user research", currentProject: "Open-source design system for startups", bio: "Design systems nerd. Love creating intuitive user experiences.", role: "student" },
  { clerkId: "test_emily", name: "Emily Rodriguez", headline: "Data Science + Econ — making sense of messy data", skills: ["Python", "TensorFlow", "PyTorch", "SQL", "Data Visualization"], interests: ["AI/ML", "Healthcare", "Climate Tech", "EdTech"], lookingFor: "Frontend developers, business partners", canHelpWith: "Machine learning, data analysis, Python", currentProject: "ML toolkit for small business churn prediction", bio: "Making AI accessible and practical.", role: "student" },
  { clerkId: "test_jake", name: "Jake Thompson", headline: "CS + Entrepreneurship — iOS dev & indie hacker", skills: ["Swift", "SwiftUI", "UIKit", "Core Data", "CloudKit"], interests: ["Health Tech", "Productivity", "Mobile", "Indie Hacking"], lookingFor: "Designer for mobile UX, marketing help", canHelpWith: "iOS development, Swift, SwiftUI", currentProject: "Habit tracking app with social features", bio: "Building native iOS apps since 2015.", role: "student" },
  { clerkId: "test_alex", name: "Alex Rivera", headline: "Marketing Major — growth & content strategy", skills: ["Growth Marketing", "SEO", "Content Strategy", "Analytics", "Paid Ads"], interests: ["B2B SaaS", "Developer Tools", "Creator Economy"], lookingFor: "Technical co-founder for B2B SaaS", canHelpWith: "Growth marketing, SEO, content strategy", currentProject: "Consulting for early-stage startups", bio: "Growth marketer who actually understands tech.", role: "student" },
  { clerkId: "test_jordan", name: "Jordan Kim", headline: "Software Engineering Senior — backend & infrastructure", skills: ["Go", "Rust", "Kubernetes", "PostgreSQL", "Redis"], interests: ["Infrastructure", "Developer Tools", "Open Source"], lookingFor: "Frontend developer, DevRel help", canHelpWith: "Backend development, system design, Golang", currentProject: "Open-source observability tool", bio: "Love building scalable systems.", role: "student" },
  { clerkId: "test_maya", name: "Maya Patel", headline: "Business + CS — product & fintech", skills: ["Product Management", "SQL", "Figma", "User Research", "Agile"], interests: ["Fintech", "EdTech", "Financial Inclusion", "Mobile"], lookingFor: "iOS or React Native developer", canHelpWith: "Product strategy, roadmapping, user interviews", currentProject: "Micro-investing app for college students", bio: "PM who codes. Passionate about financial inclusion.", role: "student" },
  { clerkId: "test_chris", name: "Chris Anderson", headline: "Entrepreneurship Senior — 2x founder, still learning", skills: ["Fundraising", "Leadership", "Strategy", "Sales", "Negotiations"], interests: ["B2B SaaS", "AgTech", "Midwest Startups"], lookingFor: "Ambitious founders to mentor", canHelpWith: "Fundraising, pitch decks, startup strategy", currentProject: "Mentoring at NMotion, angel investing", bio: "Sold my last company in 2022. Now advising founders.", role: "mentor" },
  { clerkId: "test_lisa", name: "Lisa Nguyen", headline: "CS + Math — AI/ML research, LLM projects", skills: ["Python", "PyTorch", "LLMs", "NLP", "Research"], interests: ["AI Safety", "Developer Tools", "Education"], lookingFor: "Engineers for AI products, startup founders", canHelpWith: "AI/ML research, LLMs, prompt engineering", currentProject: "Tools to make LLMs reliable in production", bio: "Researching LLMs and their applications.", role: "student" },
  { clerkId: "test_david", name: "David Park", headline: "CS Sophomore — mobile dev, cross-platform", skills: ["Flutter", "React Native", "Dart", "JavaScript", "Firebase"], interests: ["Mobile", "Local Tech", "Events", "Social Apps"], lookingFor: "Backend developer, events industry expert", canHelpWith: "Mobile development, Flutter, React Native", currentProject: "Local events discovery app for the Midwest", bio: "Cross-platform mobile specialist.", role: "student" },

  // ── 25 NEW users ──
  { clerkId: "test_natalie", name: "Natalie Brooks", headline: "Supply Chain + Data Analytics — logistics nerd", skills: ["Python", "Excel", "Tableau", "Supply Chain", "Operations"], interests: ["AgTech", "Logistics", "Sustainability"], lookingFor: "Developer to build a farm-to-table platform", canHelpWith: "Supply chain optimization, data analytics", currentProject: "Farm logistics optimization tool", bio: "Making Nebraska supply chains smarter.", role: "student" },
  { clerkId: "test_ryan", name: "Ryan Mitchell", headline: "Finance Major — DCF models & startup valuation", skills: ["Financial Modeling", "Excel", "Pitch Decks", "Accounting", "Valuation"], interests: ["Fintech", "VC", "Real Estate Tech"], lookingFor: "Technical co-founder for fintech idea", canHelpWith: "Financial modeling, fundraising strategy, pitch decks", currentProject: "Student loan refinancing calculator", bio: "Aspiring VC. Interned at Nelnet.", role: "student" },
  { clerkId: "test_priya", name: "Priya Sharma", headline: "CS + Design — full-stack with an eye for UX", skills: ["React", "Next.js", "Tailwind CSS", "Figma", "Node.js"], interests: ["EdTech", "Design Engineering", "SaaS"], lookingFor: "Business co-founder for EdTech startup", canHelpWith: "Full-stack development, design implementation", currentProject: "Course review platform for UNL students", bio: "Building at the intersection of design and code.", role: "student" },
  { clerkId: "test_tyler", name: "Tyler Okafor", headline: "Mechanical Engineering — hardware + IoT projects", skills: ["Arduino", "CAD", "3D Printing", "IoT", "C++"], interests: ["Hardware", "AgTech", "Robotics", "Sustainability"], lookingFor: "Software developer to build companion app", canHelpWith: "Hardware prototyping, CAD, 3D printing, IoT", currentProject: "Smart soil moisture sensor for Nebraska farms", bio: "Bridging hardware and software for real-world impact.", role: "student" },
  { clerkId: "test_hannah", name: "Hannah Foster", headline: "Journalism + Marketing — content & brand storytelling", skills: ["Copywriting", "Social Media", "Video Production", "Adobe Premiere", "Photography"], interests: ["Creator Economy", "Media", "Branding"], lookingFor: "Startups that need content strategy", canHelpWith: "Content creation, social media strategy, video editing", currentProject: "Building a personal brand on LinkedIn", bio: "Stories sell. I write the ones that stick.", role: "student" },
  { clerkId: "test_omar", name: "Omar Hassan", headline: "Pre-Med + CS — building health tech on the side", skills: ["Python", "React", "FHIR", "Healthcare APIs", "SQL"], interests: ["Health Tech", "AI in Medicine", "Telemedicine"], lookingFor: "Designer and business partner for health app", canHelpWith: "Healthcare domain knowledge, Python development", currentProject: "Medication reminder app with pharmacy integration", bio: "Future doctor who codes. Building tools patients actually need.", role: "student" },
  { clerkId: "test_kayla", name: "Kayla Washington", headline: "Architecture + UX — designing physical & digital spaces", skills: ["Figma", "AutoCAD", "Blender", "User Research", "Spatial Design"], interests: ["PropTech", "Smart Cities", "Sustainability"], lookingFor: "Developers for smart building dashboard", canHelpWith: "Spatial design, 3D modeling, UX research", currentProject: "Smart building energy dashboard for campus", bio: "Designing spaces that work — online and off.", role: "student" },
  { clerkId: "test_ethan", name: "Ethan Nguyen", headline: "CS Senior — cybersecurity & systems", skills: ["Cybersecurity", "Linux", "Networking", "Python", "Penetration Testing"], interests: ["Security", "Privacy", "Open Source"], lookingFor: "Team for campus security audit tool", canHelpWith: "Cybersecurity audits, networking, Linux administration", currentProject: "Open-source vulnerability scanner for student orgs", bio: "Making systems secure, one pentest at a time.", role: "student" },
  { clerkId: "test_sofia", name: "Sofia Martinez", headline: "Business + Spanish — international market expansion", skills: ["Business Development", "Sales", "Spanish", "Market Research", "CRM"], interests: ["International Business", "LatAm Markets", "E-commerce"], lookingFor: "Developer for e-commerce tool", canHelpWith: "Business development, sales, Spanish-language markets", currentProject: "Connecting Nebraska businesses with Latin American markets", bio: "Bilingual business builder. Growing markets across borders.", role: "student" },
  { clerkId: "test_ben", name: "Ben Taylor", headline: "CS + Math — algorithms & competitive programming", skills: ["C++", "Python", "Algorithms", "Data Structures", "Competitive Programming"], interests: ["Quant Finance", "Gaming", "AI"], lookingFor: "Startup needing hard engineering problems solved", canHelpWith: "Algorithm design, optimization, competitive programming coaching", currentProject: "Game-based algorithm learning platform", bio: "ICPC competitor. Love hard problems.", role: "student" },
  { clerkId: "test_megan", name: "Megan Liu", headline: "Graphic Design + Animation — motion & branding", skills: ["After Effects", "Illustrator", "Blender", "Motion Design", "Branding"], interests: ["Animation", "Branding", "Creator Economy"], lookingFor: "Startups that need brand identity work", canHelpWith: "Logo design, brand guidelines, motion graphics, animation", currentProject: "Animated explainer video series for startups", bio: "Making brands move. Literally.", role: "student" },
  { clerkId: "test_jackson", name: "Jackson Wright", headline: "AgTech — precision agriculture & drones", skills: ["Drone Operations", "GIS", "Python", "Remote Sensing", "Agriculture"], interests: ["AgTech", "Drones", "Sustainability", "Rural Tech"], lookingFor: "Software engineers for drone data pipeline", canHelpWith: "Drone operations, agricultural consulting, GIS mapping", currentProject: "Drone-based crop health monitoring for Nebraska farms", bio: "Nebraska farm kid turned tech founder.", role: "student" },
  { clerkId: "test_aisha", name: "Aisha Johnson", headline: "Education + Psychology — learning science & EdTech", skills: ["Curriculum Design", "Research", "User Interviews", "Teaching", "Data Analysis"], interests: ["EdTech", "Learning Science", "K-12"], lookingFor: "Developer to build adaptive learning tool", canHelpWith: "Learning design, user research, education domain expertise", currentProject: "Adaptive math tutoring prototype for middle schoolers", bio: "Building tech that teaches the way kids actually learn.", role: "student" },
  { clerkId: "test_daniel", name: "Daniel Cooper", headline: "CS + Business — SaaS builder & indie hacker", skills: ["Next.js", "TypeScript", "Stripe", "Vercel", "PostgreSQL"], interests: ["SaaS", "Indie Hacking", "Developer Tools", "Bootstrapping"], lookingFor: "Designer and early customers for SaaS tool", canHelpWith: "Full-stack SaaS development, payments integration, deployment", currentProject: "Invoice management tool for freelancers", bio: "Shipping SaaS products. Currently 3 active projects.", role: "student" },
  { clerkId: "test_grace", name: "Grace Chen", headline: "Pre-Law + Tech Policy — AI governance & ethics", skills: ["Legal Research", "Policy Writing", "Public Speaking", "AI Ethics", "Compliance"], interests: ["AI Policy", "Privacy", "Tech Regulation"], lookingFor: "AI startups that need policy guidance", canHelpWith: "Tech policy analysis, compliance, legal research, public speaking", currentProject: "Student-run AI policy blog at UNL", bio: "The law is catching up to tech. I'm helping.", role: "student" },
  { clerkId: "test_noah", name: "Noah Williams", headline: "Music + CS — audio tech & creative coding", skills: ["Python", "Max/MSP", "Audio Processing", "Creative Coding", "JavaScript"], interests: ["Music Tech", "Creative Tools", "Audio", "Gaming"], lookingFor: "Designer for music collaboration app", canHelpWith: "Audio processing, creative coding, music production", currentProject: "AI-powered music collaboration platform", bio: "Making music with machines.", role: "student" },
  { clerkId: "test_rachel", name: "Rachel Kim", headline: "Marketing + Analytics — data-driven growth", skills: ["Google Analytics", "HubSpot", "Content Marketing", "Email Marketing", "A/B Testing"], interests: ["Growth", "SaaS Marketing", "Analytics"], lookingFor: "Product to grow — want to join a founding team", canHelpWith: "Marketing analytics, email campaigns, A/B testing, growth strategy", currentProject: "Growth audit framework for student startups", bio: "If you can't measure it, you can't grow it.", role: "student" },
  { clerkId: "test_liam", name: "Liam O'Brien", headline: "CS Freshman — learning fast, building faster", skills: ["JavaScript", "HTML/CSS", "React", "Git"], interests: ["Web Development", "Startups", "Learning"], lookingFor: "Mentorship and first startup experience", canHelpWith: "Frontend basics, enthusiasm, willingness to learn anything", currentProject: "Personal portfolio site", bio: "Brand new to startups. Hungry to learn.", role: "student" },
  { clerkId: "test_zara", name: "Zara Abbas", headline: "CS + Linguistics — NLP & chatbot development", skills: ["Python", "NLP", "Transformers", "FastAPI", "Docker"], interests: ["NLP", "Conversational AI", "Education"], lookingFor: "Product person for chatbot startup", canHelpWith: "NLP development, chatbot design, API development", currentProject: "Campus virtual assistant chatbot for UNL", bio: "Teaching machines to understand humans.", role: "student" },
  { clerkId: "test_mason", name: "Mason Reed", headline: "Film + Marketing — short-form video & storytelling", skills: ["Video Production", "TikTok Strategy", "Adobe Premiere", "Photography", "Storytelling"], interests: ["Creator Economy", "Social Media", "Film", "Branding"], lookingFor: "Startups that need video content", canHelpWith: "Video production, TikTok/Reels strategy, brand storytelling", currentProject: "Running a 50K follower TikTok about Nebraska startups", bio: "If your startup isn't on video, does it even exist?", role: "student" },
  { clerkId: "test_chloe", name: "Chloe Park", headline: "Industrial Design — physical products & packaging", skills: ["SolidWorks", "Product Design", "Packaging", "3D Printing", "Sketching"], interests: ["Consumer Products", "Sustainability", "D2C"], lookingFor: "Business partner for D2C product launch", canHelpWith: "Product design, packaging, manufacturing relationships", currentProject: "Sustainable packaging for Nebraska food brands", bio: "Designing products people love to hold.", role: "student" },
  { clerkId: "test_marcus2", name: "Marcus Johnson", headline: "Accounting + Data — financial systems & automation", skills: ["QuickBooks", "Python", "Excel", "Accounting", "Financial Analysis"], interests: ["Fintech", "Automation", "Small Business"], lookingFor: "Developer to automate bookkeeping", canHelpWith: "Accounting, financial analysis, tax strategy for startups", currentProject: "Automated bookkeeping tool for student businesses", bio: "Making numbers make sense.", role: "student" },
  { clerkId: "test_emma", name: "Emma Wilson", headline: "Environmental Science — sustainability & cleantech", skills: ["Environmental Analysis", "GIS", "Data Analysis", "Grant Writing", "Research"], interests: ["CleanTech", "Sustainability", "AgTech", "Policy"], lookingFor: "Technical co-founder for sustainability platform", canHelpWith: "Environmental consulting, grant writing, sustainability strategy", currentProject: "Carbon footprint tracker for campus organizations", bio: "Building a more sustainable Nebraska, one dataset at a time.", role: "student" },
  { clerkId: "test_carlos", name: "Carlos Ramirez", headline: "CS + Art — creative technology & interactive media", skills: ["p5.js", "Three.js", "React", "WebGL", "Generative Art"], interests: ["Creative Tech", "Web3", "Interactive Media", "Gaming"], lookingFor: "Artist collaborators for interactive installations", canHelpWith: "Creative coding, interactive web experiences, 3D graphics", currentProject: "Interactive art installation for Sheldon Museum", bio: "Code is my canvas.", role: "student" },
  { clerkId: "test_ally", name: "Ally Becker", headline: "Management + Psych — team dynamics & org design", skills: ["Team Management", "Hiring", "Culture Building", "Facilitation", "Coaching"], interests: ["HR Tech", "Team Building", "Organizational Psychology"], lookingFor: "Startups that need help building culture early", canHelpWith: "Team building, hiring strategy, culture design, facilitation", currentProject: "Startup team-building workshop series at UNL", bio: "Great teams build great products. I build great teams.", role: "student" },
];

// Not-yet-onboarded signups (show funnel drop-off)
const UNONBOARDED = [
  { clerkId: "test_incomplete_1", name: "Taylor Smith" },
  { clerkId: "test_incomplete_2", name: "Jordan Lee" },
  { clerkId: "test_incomplete_3", name: "Casey Brown" },
  { clerkId: "test_incomplete_4", name: "Morgan Davis" },
  { clerkId: "test_incomplete_5", name: "Riley Johnson" },
  { clerkId: "test_incomplete_6", name: "Avery Garcia" },
  { clerkId: "test_incomplete_7", name: "Quinn Martinez" },
];

export const clearAll = internalMutation({
  args: {},
  handler: async (ctx) => {
    // Delete in dependency order
    const tables = [
      "eventFeedback", "eventRsvps", "events",
      "messages", "conversations",
      "comments", "posts",
      "connections",
      "searchSessions",
      "dailyMatches",
      "notifications",
      "users",
    ] as const;
    let total = 0;
    for (const table of tables) {
      const rows = await ctx.db.query(table).collect();
      for (const row of rows) {
        await ctx.db.delete(row._id);
      }
      total += rows.length;
    }
    return `Cleared ${total} rows across ${tables.length} tables`;
  },
});

// ── Step 1: Seed users ──
export const seedUsers = internalMutation({
  args: {},
  handler: async (ctx) => {
    const now = Date.now();
    const ids: Id<"users">[] = [];

    for (let i = 0; i < USERS.length; i++) {
      const m = USERS[i];
      const existing = await ctx.db.query("users").filter(q => q.eq(q.field("clerkId"), m.clerkId)).first();
      if (existing) { ids.push(existing._id); continue; }

      const age = (USERS.length - i) * DAY + Math.floor(Math.random() * DAY);
      const id = await ctx.db.insert("users", {
        clerkId: m.clerkId,
        email: `${m.clerkId}@unl.edu`,
        name: m.name,
        headline: m.headline,
        avatarUrl: face(i),
        currentProject: m.currentProject,
        lookingFor: m.lookingFor,
        canHelpWith: m.canHelpWith,
        skills: [],
        interests: [],
        role: m.role ?? "student",
        isOnboarded: true,
        createdAt: now - age,
        updatedAt: now - age + Math.floor(Math.random() * DAY),
      });
      ids.push(id);
    }

    // Add unonboarded users (signed up but never finished profile)
    for (const u of UNONBOARDED) {
      const existing = await ctx.db.query("users").filter(q => q.eq(q.field("clerkId"), u.clerkId)).first();
      if (existing) continue;
      await ctx.db.insert("users", {
        clerkId: u.clerkId,
        email: `${u.clerkId}@unl.edu`,
        name: u.name,
        isOnboarded: false,
        createdAt: now - Math.floor(Math.random() * 14 * DAY),
        updatedAt: now - Math.floor(Math.random() * 14 * DAY),
      });
    }

    return `Seeded ${ids.length} onboarded + ${UNONBOARDED.length} incomplete users`;
  },
});

// ── Step 2: Seed connections ──
export const seedConnections = internalMutation({
  args: {},
  handler: async (ctx) => {
    const users = await ctx.db.query("users").filter(q => q.eq(q.field("isOnboarded"), true)).collect();
    const existing = await ctx.db.query("connections").collect();
    if (existing.length > 20) return `Already have ${existing.length} connections`;

    const now = Date.now();
    let count = 0;

    // Create a realistic network — not everyone connected to everyone
    // Hub nodes (high connectivity): Sarah, Chris, Maya, Alex, Daniel
    const hubIndices = [0, 7, 6, 4, 23]; // Sarah, Chris, Maya, Alex, Daniel
    const pairs: [number, number][] = [];

    // Hub connections (each hub connects to 8-12 others)
    for (const hub of hubIndices) {
      const targets = Array.from({ length: users.length }, (_, i) => i)
        .filter(i => i !== hub)
        .sort(() => Math.random() - 0.5)
        .slice(0, 8 + Math.floor(Math.random() * 5));
      for (const t of targets) {
        const pair: [number, number] = hub < t ? [hub, t] : [t, hub];
        if (!pairs.some(p => p[0] === pair[0] && p[1] === pair[1])) {
          pairs.push(pair);
        }
      }
    }

    // Regular connections (everyone gets at least 2-4)
    for (let i = 0; i < users.length; i++) {
      const myConnections = pairs.filter(p => p[0] === i || p[1] === i).length;
      if (myConnections < 2) {
        const needed = 2 + Math.floor(Math.random() * 3) - myConnections;
        const targets = Array.from({ length: users.length }, (_, j) => j)
          .filter(j => j !== i && !pairs.some(p => (p[0] === Math.min(i, j) && p[1] === Math.max(i, j))))
          .sort(() => Math.random() - 0.5)
          .slice(0, Math.max(needed, 0));
        for (const t of targets) {
          pairs.push(i < t ? [i, t] : [t, i]);
        }
      }
    }

    // Insert connections with varying ages
    for (const [a, b] of pairs) {
      if (a >= users.length || b >= users.length) continue;
      const age = Math.floor(Math.random() * 30 * DAY);
      const createdAt = now - age;
      await ctx.db.insert("connections", {
        requesterId: users[a]._id,
        accepterId: users[b]._id,
        status: "connected",
        connectedAt: createdAt + Math.floor(Math.random() * DAY),
        createdAt,
      });
      count++;
    }

    // Add some pending connections
    for (let i = 0; i < 5; i++) {
      const a = Math.floor(Math.random() * users.length);
      let b = Math.floor(Math.random() * users.length);
      while (b === a) b = Math.floor(Math.random() * users.length);
      await ctx.db.insert("connections", {
        requesterId: users[a]._id,
        accepterId: users[b]._id,
        status: "pending",
        createdAt: now - Math.floor(Math.random() * 3 * DAY),
      });
      count++;
    }

    return `Seeded ${count} connections`;
  },
});

// ── Step 3: Seed events with RSVPs and feedback ──
export const seedEvents = internalMutation({
  args: {},
  handler: async (ctx) => {
    const users = await ctx.db.query("users").filter(q => q.eq(q.field("isOnboarded"), true)).collect();
    const existing = await ctx.db.query("events").collect();
    if (existing.length > 3) return `Already have ${existing.length} events`;

    const now = Date.now();
    let count = 0;

    const eventDefs = [
      // ── Past events (with feedback + ratings) ──
      {
        title: "JUNTO LAUNCH PARTY",
        description: "The official launch of onjunto.com at UNL! Meet the founding community, connect with fellow users, and celebrate the start of something new. Demo stations, lightning talks, and free food.",
        date: now - 28 * DAY,
        endDate: now - 28 * DAY + 3 * HOUR,
        location: "Nebraska Innovation Campus",
        type: "in_person",
        imageUrl: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&h=600&fit=crop",
        rsvpCount: 22,
        feedbackRatings: [5, 5, 4, 5, 4, 5, 5, 4, 5, 4, 3, 5, 5, 4, 5],
        improvements: ["More networking time", "Bigger venue", "More food options", "Start earlier", "Louder speakers"],
      },
      {
        title: "FOUNDER COFFEE CHAT",
        description: "Casual coffee meetup for founders and aspiring founders. No agenda, no pitch decks — just real conversations about what you're building.",
        date: now - 21 * DAY,
        endDate: now - 21 * DAY + 2 * HOUR,
        location: "The Mill Coffee, 800 P St",
        type: "in_person",
        imageUrl: "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800&h=600&fit=crop",
        rsvpCount: 14,
        feedbackRatings: [5, 4, 4, 5, 3, 4, 5, 4, 4],
        improvements: ["More structured intros", "Longer event", "Name tags"],
      },
      {
        title: "PITCH PRACTICE NIGHT",
        description: "Practice your pitch in a low-stakes environment. Get feedback from peers and mentors. Whether you have a working product or just a napkin sketch — come sharpen your story.",
        date: now - 14 * DAY,
        endDate: now - 14 * DAY + 2.5 * HOUR,
        location: "College of Business, Room 125",
        type: "in_person",
        imageUrl: "https://images.unsplash.com/photo-1475721027785-f74eccf877e2?w=800&h=600&fit=crop",
        rsvpCount: 18,
        feedbackRatings: [5, 5, 5, 4, 5, 4, 5, 5, 3, 4, 5, 5],
        improvements: ["More mentor judges", "Written feedback forms", "Record pitches"],
      },
      {
        title: "DESIGN x DEV JAM",
        description: "Pair up a designer and developer. Get 3 hours to build something real. Past jams have produced landing pages, app prototypes, and one actual shipped product.",
        date: now - 7 * DAY,
        endDate: now - 7 * DAY + 3 * HOUR,
        location: "Kauffman Center, UNL",
        type: "in_person",
        imageUrl: "https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800&h=600&fit=crop",
        rsvpCount: 16,
        feedbackRatings: [5, 5, 4, 5, 5, 4, 5, 4, 5, 5],
        improvements: ["More time", "Pre-assign teams", "Better WiFi"],
      },

      // ── Upcoming events ──
      {
        title: "CENTER FOR ENTREPRENEURSHIP: SPRING PITCH NIGHT",
        description: "Pitch your startup idea in 5 minutes. Get feedback from judges, mentors, and fellow founders. Open to all UNL students.\n\nPrizes:\n• 1st Place: $500 + mentorship session with Sam Nelson\n• 2nd Place: $250\n• Audience Choice: $100\n\nFood and drinks provided by the Center for Entrepreneurship.",
        date: now + 11 * DAY,
        endDate: now + 11 * DAY + 3 * HOUR,
        location: "Lincoln, NE",
        type: "in_person",
        imageUrl: "https://images.unsplash.com/photo-1559223607-a43c990c692c?w=800&h=600&fit=crop",
        rsvpCount: 10,
        feedbackRatings: [],
        improvements: [],
      },
      {
        title: "JUNTO USER MEETUP",
        description: "Monthly user meetup. Show what you're working on, find collaborators, and hang out with the community. No formal agenda — just bring your laptop and your energy.",
        date: now + 18 * DAY,
        endDate: now + 18 * DAY + 2 * HOUR,
        location: "Nebraska Innovation Campus",
        type: "in_person",
        imageUrl: "https://images.unsplash.com/photo-1528605248644-14dd04022da1?w=800&h=600&fit=crop",
        rsvpCount: 6,
        feedbackRatings: [],
        improvements: [],
      },
      {
        title: "AI HACKATHON: BUILD WITH LLMS",
        description: "24-hour hackathon focused on building real products with LLMs. Teams of 2-4. API credits provided by Anthropic and OpenAI. Mentors from local AI companies.",
        date: now + 25 * DAY,
        endDate: now + 26 * DAY,
        location: "Raikes School, UNL",
        type: "in_person",
        imageUrl: "https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800&h=600&fit=crop",
        rsvpCount: 8,
        feedbackRatings: [],
        improvements: [],
      },
    ];

    for (const def of eventDefs) {
      const creator = users[Math.floor(Math.random() * 5)]; // Top 5 users as organizers
      const isPast = def.date < now;

      const eventId = await ctx.db.insert("events", {
        title: def.title,
        description: def.description,
        date: def.date,
        endDate: def.endDate,
        location: def.location,
        type: def.type,
        imageUrl: def.imageUrl,
        createdBy: creator._id,
        createdAt: def.date - 14 * DAY,
      });

      // RSVPs — pick random users
      const shuffled = [...users].sort(() => Math.random() - 0.5);
      const attendees = shuffled.slice(0, def.rsvpCount);
      for (const attendee of attendees) {
        await ctx.db.insert("eventRsvps", {
          eventId,
          userId: attendee._id,
          status: "going",
          createdAt: def.date - Math.floor(Math.random() * 7 * DAY),
        });
      }

      // Some "interested" RSVPs
      const interested = shuffled.slice(def.rsvpCount, def.rsvpCount + 3);
      for (const i of interested) {
        await ctx.db.insert("eventRsvps", {
          eventId,
          userId: i._id,
          status: "interested",
          createdAt: def.date - Math.floor(Math.random() * 7 * DAY),
        });
      }

      // Feedback for past events
      if (isPast && def.feedbackRatings.length > 0) {
        for (let f = 0; f < def.feedbackRatings.length && f < attendees.length; f++) {
          const improvementPool = def.improvements;
          const picked = improvementPool
            .sort(() => Math.random() - 0.5)
            .slice(0, 1 + Math.floor(Math.random() * 2));

          // wantToConnectWith — pick 1-3 other attendees
          const others = attendees.filter((_, idx) => idx !== f);
          const wantToConnect = others
            .sort(() => Math.random() - 0.5)
            .slice(0, 1 + Math.floor(Math.random() * 3))
            .map(m => m._id);

          await ctx.db.insert("eventFeedback", {
            eventId,
            userId: attendees[f]._id,
            rating: def.feedbackRatings[f],
            improvements: picked,
            wantToConnectWith: wantToConnect,
            createdAt: def.date + 2 * HOUR + Math.floor(Math.random() * DAY),
          });
        }
      }

      count++;
    }

    return `Seeded ${count} events with RSVPs and feedback`;
  },
});

// ── Step 4: Seed posts and comments ──
export const seedPosts = internalMutation({
  args: {},
  handler: async (ctx) => {
    const users = await ctx.db.query("users").filter(q => q.eq(q.field("isOnboarded"), true)).collect();
    const existing = await ctx.db.query("posts").collect();
    if (existing.length > 5) return `Already have ${existing.length} posts`;

    const now = Date.now();

    const postDefs = [
      { author: 0, content: "Just shipped the v1 of my recipe app! Been working on this for 3 months. Would love feedback from anyone who cooks. Link in my profile.", category: "sharing" as const },
      { author: 7, content: "Looking for founders who want pitch deck feedback. I've reviewed 200+ decks this year. Drop a comment if you want a free 15-min session.", category: "sharing" as const },
      { author: 3, content: "Anyone here experienced with App Store Optimization? My habit tracker app is getting downloads but the conversion rate from page views is terrible.", category: "asking" as const },
      { author: 4, content: "Running a growth experiment: I'm going to document building a SaaS product in public for 30 days. Follow along and hold me accountable.", category: "sharing" as const },
      { author: 12, content: "Need a developer! Building a course review platform for UNL students — I have the design and user research done, just need someone to help build it. React/Next.js preferred.", category: "looking_for" as const },
      { author: 6, content: "Just got accepted into the UNL accelerator program! If anyone else is applying, happy to share my application and pitch deck.", category: "sharing" as const },
      { author: 15, content: "Pre-med students who code — are there more of us? Starting a health tech study group. We meet Wednesdays at the Union.", category: "looking_for" as const },
      { author: 23, content: "Shipped my third SaaS product this month. Here's what I learned about building fast: 1) Use Next.js + Vercel 2) Stripe for payments day one 3) Launch ugly, iterate fast", category: "sharing" as const },
      { author: 21, content: "Nebraska farms need better tech. Working on drone-based crop monitoring — any CS students interested in satellite image processing?", category: "looking_for" as const },
      { author: 8, content: "PSA: If you're building with LLMs, check out this new prompting technique called 'chain-of-thought with verification'. Dramatically improved my model's accuracy.", category: "sharing" as const },
      { author: 2, content: "Data viz nerds — I made a Tableau dashboard showing Lincoln startup funding trends over the last 5 years. Surprising how much growth there's been. Will share the link.", category: "sharing" as const },
      { author: 19, content: "Hot take: most student startups fail because they skip user interviews, not because of bad code. I've done 50+ user interviews this semester. AMA.", category: "sharing" as const },
      { author: 29, content: "Looking for someone who understands the TikTok algorithm. We have a 50K following but engagement dropped 40% this month. Need help diagnosing.", category: "asking" as const },
      { author: 1, content: "Just open-sourced my design system on GitHub! It's built for early-stage startups who don't have a designer yet. Figma + React components.", category: "sharing" as const },
      { author: 24, content: "Anyone want to start a weekly creative coding session? I'm thinking Processing/p5.js, generative art, maybe some Three.js. Sheldon Museum said we can use their space.", category: "looking_for" as const },
      { author: 11, content: "Finance students: I built a free financial modeling template for startup valuations. DCF, comps, and cap table all in one Google Sheet. Link in comments.", category: "sharing" as const },
      { author: 20, content: "The logo I designed for the Junto. launch party made me realize — there's a huge demand for quick brand identity work from student startups. Thinking of starting a design sprint service.", category: "sharing" as const },
      { author: 5, content: "Deployed my observability tool to 3 student org servers this week. Finding bugs they didn't know they had. Open source is the best marketing.", category: "sharing" as const },
    ];

    const postIds: Id<"posts">[] = [];
    for (let i = 0; i < postDefs.length; i++) {
      const p = postDefs[i];
      const age = (postDefs.length - i) * DAY * 1.5 + Math.floor(Math.random() * DAY);
      const id = await ctx.db.insert("posts", {
        authorId: users[p.author]._id,
        content: p.content,
        category: p.category,
        createdAt: now - age,
        updatedAt: now - age,
      });
      postIds.push(id);
    }

    // Add comments — 2-5 per post
    const commentTemplates = [
      "This is awesome! 🔥",
      "Love this — DM'd you!",
      "I'm interested, let's connect",
      "Great work, keep shipping!",
      "This is exactly what I needed",
      "I had the same problem. What stack are you using?",
      "Following this. Super useful.",
      "Count me in!",
      "Would love to collaborate on this",
      "Just sent you a message about this",
      "Been thinking about the same thing. Let's chat.",
      "Incredible. How long did this take?",
      "Can confirm — this approach works well.",
      "I might be able to help with the design side of this.",
      "This is the kind of content I joined Junto for.",
    ];

    let commentCount = 0;
    for (const postId of postIds) {
      const numComments = 2 + Math.floor(Math.random() * 4);
      const commenters = [...users].sort(() => Math.random() - 0.5).slice(0, numComments);
      for (const commenter of commenters) {
        const template = commentTemplates[Math.floor(Math.random() * commentTemplates.length)];
        await ctx.db.insert("comments", {
          postId,
          authorId: commenter._id,
          content: template,
          createdAt: now - Math.floor(Math.random() * 20 * DAY),
        });
        commentCount++;
      }
    }

    return `Seeded ${postDefs.length} posts and ${commentCount} comments`;
  },
});

// ── Step 5: Seed conversations and messages ──
export const seedMessages = internalMutation({
  args: {},
  handler: async (ctx) => {
    const users = await ctx.db.query("users").filter(q => q.eq(q.field("isOnboarded"), true)).collect();
    const existing = await ctx.db.query("conversations").collect();
    if (existing.length > 10) return `Already have ${existing.length} conversations`;

    const now = Date.now();
    let convoCount = 0;

    // Create 20 conversations with messages
    const pairs: [number, number][] = [];
    for (let i = 0; i < 25; i++) {
      const a = Math.floor(Math.random() * users.length);
      let b = Math.floor(Math.random() * users.length);
      while (b === a) b = Math.floor(Math.random() * users.length);
      const min = Math.min(a, b);
      const max = Math.max(a, b);
      if (pairs.some(p => p[0] === min && p[1] === max)) continue;
      pairs.push([min, max]);
    }

    const msgTemplates = [
      ["Hey! Saw your post about {topic}. I'm working on something similar.", "Oh nice! What are you building?", "It's a {thing}. Would love to compare notes sometime.", "Definitely! Want to grab coffee this week?"],
      ["Your project looks really cool. Need any help with the frontend?", "Yes actually! Are you free to chat?", "How about tomorrow at 2pm?", "Works for me. I'll send you a calendar invite."],
      ["Hey, we met at the Junto event last week. Great chatting with you!", "Same! Loved hearing about your startup.", "Want to keep the conversation going? I think there's a good collab opportunity.", "For sure. Let me send you what I've been working on."],
      ["Quick question — what tech stack are you using for your project?", "Next.js, Convex, and Tailwind. You?", "React Native + Firebase. Thinking about switching to Convex though.", "It's been great. Happy to do a walkthrough if you want."],
      ["Congrats on shipping! How's the user feedback been?", "Thanks! Mixed honestly. Good engagement but onboarding needs work.", "Happy to help review the flow if you want a second pair of eyes.", "That would be amazing. Free this afternoon?"],
    ];

    for (const [a, b] of pairs) {
      const user1 = users[a];
      const user2 = users[b];

      // Ensure lexicographic order
      const [p1, p2] = user1._id < user2._id ? [user1, user2] : [user2, user1];

      const template = msgTemplates[Math.floor(Math.random() * msgTemplates.length)];
      const age = Math.floor(Math.random() * 20 * DAY);

      const convoId = await ctx.db.insert("conversations", {
        participant1Id: p1._id,
        participant2Id: p2._id,
        lastMessageAt: now - age,
        lastMessagePreview: template[template.length - 1],
        lastMessageSenderId: p2._id,
        participant1UnreadCount: Math.random() > 0.5 ? 1 : 0,
        participant2UnreadCount: Math.random() > 0.5 ? 1 : 0,
        status: "active",
        initiatorId: p1._id,
        createdAt: now - age - DAY,
      });

      // Insert messages
      for (let m = 0; m < template.length; m++) {
        const sender = m % 2 === 0 ? p1 : p2;
        await ctx.db.insert("messages", {
          conversationId: convoId,
          senderId: sender._id,
          content: template[m]
            .replace("{topic}", p2.currentProject ?? "your project")
            .replace("{thing}", p1.currentProject ?? "a cool app"),
          createdAt: now - age + m * HOUR,
        });
      }

      convoCount++;
    }

    return `Seeded ${convoCount} conversations with messages`;
  },
});

// ── Step 6: Seed search sessions (demand signals) ──
export const seedSearches = internalMutation({
  args: {},
  handler: async (ctx) => {
    const users = await ctx.db.query("users").filter(q => q.eq(q.field("isOnboarded"), true)).collect();
    const existing = await ctx.db.query("searchSessions").collect();
    if (existing.length > 5) return `Already have ${existing.length} search sessions`;

    const now = Date.now();
    const searches = [
      { query: "React developer", status: "complete", resultCount: 8 },
      { query: "someone who knows fundraising", status: "complete", resultCount: 3 },
      { query: "designer for mobile app", status: "complete", resultCount: 5 },
      { query: "marketing help for SaaS", status: "complete", resultCount: 4 },
      { query: "co-founder with business skills", status: "complete", resultCount: 6 },
      { query: "anyone doing AI/ML projects", status: "complete", resultCount: 7 },
      { query: "iOS developer", status: "complete", resultCount: 2 },
      { query: "pitch deck feedback", status: "complete", resultCount: 4 },
      { query: "need a video editor", status: "complete", resultCount: 1 },
      { query: "graphic designer for logo", status: "complete", resultCount: 3 },
      { query: "backend developer go or python", status: "complete", resultCount: 5 },
      { query: "sustainability projects", status: "complete", resultCount: 2 },
      { query: "hardware prototyping", status: "complete", resultCount: 1 },
      { query: "someone who knows TikTok growth", status: "complete", resultCount: 2 },
      { query: "financial modeling", status: "complete", resultCount: 1 },
      { query: "looking for a co-founder", status: "complete", resultCount: 9 },
      { query: "UX researcher", status: "complete", resultCount: 3 },
      { query: "anyone doing agtech", status: "complete", resultCount: 3 },
      { query: "startup mentor", status: "complete", resultCount: 2 },
      { query: "web developer Next.js", status: "complete", resultCount: 6 },
    ];

    for (const s of searches) {
      const user = users[Math.floor(Math.random() * users.length)];
      await ctx.db.insert("searchSessions", {
        userId: user._id,
        query: s.query,
        status: s.status,
        resultCount: s.resultCount,
        createdAt: now - Math.floor(Math.random() * 30 * DAY),
        updatedAt: now - Math.floor(Math.random() * 30 * DAY),
      });
    }

    return `Seeded ${searches.length} search sessions`;
  },
});

// ── Run all steps ──
export const seedAll = internalMutation({
  args: {},
  handler: async () => {
    return "Run each step individually: seedDashboard:clearAll → seedDashboard:seedUsers → seedDashboard:seedConnections → seedDashboard:seedEvents → seedDashboard:seedPosts → seedDashboard:seedMessages → seedDashboard:seedSearches";
  },
});
