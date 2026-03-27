import { internalMutation, action } from "./_generated/server";
import { internal } from "./_generated/api";
import { Id } from "./_generated/dataModel";

// Seed function to populate test users with diverse profiles (internal)
export const seedTestUsers = internalMutation({
  args: {},
  handler: async (ctx): Promise<{ inserted: number; ids: Id<"users">[] }> => {
    const now = Date.now();

    const users = [
      {
        clerkId: "test_sarah",
        email: "sarah@example.com",
        name: "Sarah Chen",
        headline: "Full-stack developer | React & Node",
        avatarUrl: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&h=200&fit=crop&crop=face",
        currentProject: "AI-powered recipe generator that helps people cook with what they have",
        lookingFor: "Co-founder with business/marketing skills, someone who understands the food industry",
        canHelpWith: "Frontend development, API design, code reviews, React architecture",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: {
          linkedin: "https://linkedin.com/in/sarahchen",
          github: "https://github.com/sarahchen",
        },
        isOnboarded: true,
        createdAt: now - 86400000,
        updatedAt: now - 86400000,
      },
      {
        clerkId: "test_marcus",
        email: "marcus@example.com",
        name: "Marcus Williams",
        headline: "UX Designer | Previously at Google",
        avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&crop=face",
        currentProject: "Open-source design system for early-stage startups",
        lookingFor: "Developers to collaborate with, especially React/Vue devs who care about design",
        canHelpWith: "UI/UX design, design systems, user research, Figma, prototyping",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: {
          linkedin: "https://linkedin.com/in/marcuswilliams",
          website: "https://marcus.design",
        },
        isOnboarded: true,
        createdAt: now - 172800000,
        updatedAt: now - 172800000,
      },
      {
        clerkId: "test_emily",
        email: "emily@example.com",
        name: "Emily Rodriguez",
        headline: "Data Scientist | ML Engineer",
        avatarUrl: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&h=200&fit=crop&crop=face",
        currentProject: "ML toolkit that helps small businesses predict customer churn",
        lookingFor: "Frontend developers to build the UI, business partners who know SMB sales",
        canHelpWith: "Machine learning, data analysis, Python, building ML pipelines",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: {
          linkedin: "https://linkedin.com/in/emilyrodriguez",
          github: "https://github.com/emilyrodriguez",
        },
        isOnboarded: true,
        createdAt: now - 259200000,
        updatedAt: now - 259200000,
      },
      {
        clerkId: "test_jake",
        email: "jake@example.com",
        name: "Jake Thompson",
        headline: "iOS Developer | SwiftUI enthusiast",
        avatarUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&h=200&fit=crop&crop=face",
        currentProject: "Habit tracking app with social accountability features",
        lookingFor: "Designer who gets mobile UX, someone to help with marketing and growth",
        canHelpWith: "iOS development, Swift, SwiftUI, App Store optimization, mobile architecture",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: {
          twitter: "https://twitter.com/jakethompson",
          github: "https://github.com/jakethompson",
        },
        isOnboarded: true,
        createdAt: now - 345600000,
        updatedAt: now - 345600000,
      },
      {
        clerkId: "test_alex",
        email: "alex@example.com",
        name: "Alex Rivera",
        headline: "Marketing & Growth | Ex-HubSpot",
        avatarUrl: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&h=200&fit=crop&crop=face",
        currentProject: "Consulting for early-stage startups, looking to join something full-time",
        lookingFor: "Technical co-founder building something in B2B SaaS or developer tools",
        canHelpWith: "Growth marketing, SEO, content strategy, paid acquisition, go-to-market",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: {
          linkedin: "https://linkedin.com/in/alexrivera",
          twitter: "https://twitter.com/alexrivera",
        },
        isOnboarded: true,
        createdAt: now - 432000000,
        updatedAt: now - 432000000,
      },
      {
        clerkId: "test_jordan",
        email: "jordan@example.com",
        name: "Jordan Kim",
        headline: "Backend Engineer | Distributed Systems",
        avatarUrl: "https://images.unsplash.com/photo-1519345182560-3f2917c472ef?w=200&h=200&fit=crop&crop=face",
        currentProject: "Open-source observability tool for small teams",
        lookingFor: "Frontend developer, someone who can help with DevRel and community building",
        canHelpWith: "Backend development, system design, Golang, infrastructure, databases",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: {
          github: "https://github.com/jordankim",
          twitter: "https://twitter.com/jordankim",
        },
        isOnboarded: true,
        createdAt: now - 518400000,
        updatedAt: now - 518400000,
      },
      {
        clerkId: "test_maya",
        email: "maya@example.com",
        name: "Maya Patel",
        headline: "Product Manager | Fintech background",
        avatarUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop&crop=face",
        currentProject: "Micro-investing app for college students",
        lookingFor: "iOS or React Native developer, compliance/legal advisor for fintech",
        canHelpWith: "Product strategy, roadmapping, user interviews, fintech regulations",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: {
          linkedin: "https://linkedin.com/in/mayapatel",
          website: "https://mayapatel.co",
        },
        isOnboarded: true,
        createdAt: now - 604800000,
        updatedAt: now - 604800000,
      },
      {
        clerkId: "test_chris",
        email: "chris@example.com",
        name: "Chris Anderson",
        headline: "Startup Mentor | 2x Founder (1 exit)",
        avatarUrl: "https://images.unsplash.com/photo-1560250097-0b93528c311a?w=200&h=200&fit=crop&crop=face",
        currentProject: "Writing a book about startup lessons, mentoring at NMotion",
        lookingFor: "Ambitious founders to mentor, interesting investment opportunities",
        canHelpWith: "Fundraising, pitch decks, startup strategy, hiring, board management",
        skills: [] as any[],
        interests: [] as any[],
        role: "mentor",
        socialLinks: {
          linkedin: "https://linkedin.com/in/chrisanderson",
          twitter: "https://twitter.com/chrisanderson",
        },
        isOnboarded: true,
        createdAt: now - 691200000,
        updatedAt: now - 691200000,
      },
      {
        clerkId: "test_lisa",
        email: "lisa@example.com",
        name: "Lisa Nguyen",
        headline: "AI/ML Researcher | Stanford PhD",
        avatarUrl: "https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=200&h=200&fit=crop&crop=face",
        currentProject: "Building tools to make LLMs more reliable for production use",
        lookingFor: "Engineers who want to build AI products, startup founders who need AI expertise",
        canHelpWith: "AI/ML research, LLMs, prompt engineering, model fine-tuning",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: {
          twitter: "https://twitter.com/lisanguyen",
          github: "https://github.com/lisanguyen",
        },
        isOnboarded: true,
        createdAt: now - 777600000,
        updatedAt: now - 777600000,
      },
      {
        clerkId: "test_david",
        email: "david@example.com",
        name: "David Park",
        headline: "Mobile Developer | Flutter & React Native",
        avatarUrl: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200&h=200&fit=crop&crop=face",
        currentProject: "Local events discovery app for the Midwest",
        lookingFor: "Backend developer, someone who knows the local events/entertainment space",
        canHelpWith: "Mobile development, Flutter, React Native, app architecture, publishing",
        skills: [] as any[],
        interests: [] as any[],
        socialLinks: {
          github: "https://github.com/davidpark",
          linkedin: "https://linkedin.com/in/davidpark",
        },
        isOnboarded: true,
        createdAt: now - 864000000,
        updatedAt: now - 864000000,
      },
    ];

    const insertedIds: Id<"users">[] = [];
    for (const user of users) {
      // Check if already exists
      const existing = await ctx.db
        .query("users")
        .filter((q) => q.eq(q.field("clerkId"), user.clerkId))
        .first();

      if (!existing) {
        const id = await ctx.db.insert("users", user);
        insertedIds.push(id);
      }
    }

    return { inserted: insertedIds.length, ids: insertedIds };
  },
});

// Generate embeddings for all test users
export const generateTestEmbeddings = action({
  args: {},
  handler: async (ctx): Promise<{ processed: number }> => {
    const result = await ctx.runAction(internal.embeddings.generateAllEmbeddings, {}) as { processed: number };
    return result;
  },
});

// Combined: seed users and generate embeddings
export const seedWithEmbeddings = action({
  args: {},
  handler: async (ctx): Promise<{ usersSeeded: number; embeddingsGenerated: number }> => {
    // First seed the users
    const seedResult = await ctx.runMutation(internal.seed.seedTestUsers, {}) as { inserted: number };
    console.log(`Seeded ${seedResult.inserted} users`);

    // Then generate embeddings
    const embeddingResult = await ctx.runAction(internal.embeddings.generateAllEmbeddings, {}) as { processed: number };
    console.log(`Generated embeddings for ${embeddingResult.processed} users`);

    return {
      usersSeeded: seedResult.inserted,
      embeddingsGenerated: embeddingResult.processed,
    };
  },
});

// Clear all events (for re-seeding)
export const clearEvents = internalMutation({
  args: {},
  handler: async (ctx) => {
    const events = await ctx.db.query("events").collect();
    for (const event of events) {
      // Also clear RSVPs for this event
      const rsvps = await ctx.db
        .query("eventRsvps")
        .withIndex("by_event", (q) => q.eq("eventId", event._id))
        .collect();
      for (const rsvp of rsvps) {
        await ctx.db.delete(rsvp._id);
      }
      await ctx.db.delete(event._id);
    }
    return `Cleared ${events.length} events`;
  },
});

// Seed an event created by someone else (for testing Join flow)
export const seedExternalEvent = internalMutation({
  args: {},
  handler: async (ctx) => {
    const now = Date.now();

    // Get Sarah Chen as the host (not the first user)
    const sarah = await ctx.db
      .query("users")
      .filter((q) => q.eq(q.field("clerkId"), "test_sarah"))
      .first();
    if (!sarah) return "Sarah not found - seed test users first";

    // March 1, 2026 at 2:00 PM Central
    const mar1 = new Date("2026-03-01T14:00:00-06:00").getTime();

    const eventId = await ctx.db.insert("events", {
      title: "FOUNDER COFFEE CHAT",
      description:
        "Casual coffee meetup for founders and aspiring founders. No agenda, no pitch decks — just real conversations about what you're building, struggles, and wins.\n\nBring your laptop if you want to show something off. First round of coffee is on us.",
      date: mar1,
      endDate: mar1 + 2 * 60 * 60 * 1000,
      location: "Lincoln, NE",
      fullAddress: "The Mill Coffee, 800 P St, Lincoln, NE 68508",
      type: "in_person",
      imageUrl:
        "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800&h=600&fit=crop",
      createdBy: sarah._id,
      createdAt: now,
    });

    // Sarah auto-RSVPs as going
    await ctx.db.insert("eventRsvps", {
      eventId,
      userId: sarah._id,
      status: "going",
      createdAt: now,
    });

    // Add Marcus as going too
    const marcus = await ctx.db
      .query("users")
      .filter((q) => q.eq(q.field("clerkId"), "test_marcus"))
      .first();
    if (marcus) {
      await ctx.db.insert("eventRsvps", {
        eventId,
        userId: marcus._id,
        status: "going",
        createdAt: now,
      });
    }

    return `Created "FOUNDER COFFEE CHAT" hosted by Sarah Chen`;
  },
});

// Original seed functions kept for reference
export const seedUsers = internalMutation({
  args: {},
  handler: async (ctx) => {
    return "Use seedTestUsers instead";
  },
});

export const seedEvents = internalMutation({
  args: {},
  handler: async (ctx) => {
    const now = Date.now();

    // Check if we already have events
    const existing = await ctx.db.query("events").first();
    if (existing) {
      return "Already seeded";
    }

    // Get first user to use as creator
    const user = await ctx.db.query("users").first();
    if (!user) {
      return "No users found - seed users first";
    }

    // Feb 25, 2026 at 10:00 AM Central
    const feb25 = new Date("2026-02-25T10:00:00-06:00").getTime();

    const events = [
      {
        title: "JUNTO SPEED NETWORKING",
        description:
          "Meet other users in quick 5-minute conversations. Rotate through and connect with founders, designers, and developers building cool stuff in Lincoln. Whether you're looking for a co-founder, collaborator, or just want to expand your network — this is the spot.\n\nExact location will be shared after you RSVP.",
        date: feb25,
        endDate: feb25 + 2 * 60 * 60 * 1000, // 2 hours
        location: "Lincoln, NE",
        fullAddress: "1234 Innovation Dr, Lincoln, NE 68508",
        type: "in_person",
        imageUrl: "https://avid-chicken-478.convex.cloud/api/storage/82df8e1e-1ac5-48ea-b6e6-e20bf1cb8adf",
        createdBy: user._id,
        createdAt: now,
      },
    ];

    // Insert events and auto-RSVP host as going
    const eventIds: Id<"events">[] = [];
    for (const event of events) {
      const eventId = await ctx.db.insert("events", event);
      eventIds.push(eventId);

      // Host automatically goes
      await ctx.db.insert("eventRsvps", {
        eventId,
        userId: event.createdBy,
        status: "going",
        createdAt: now,
      });
    }

    // Add more participants to first event (JUNTO Speed Networking)
    const allUsers = await ctx.db.query("users").collect();
    const otherUsers = allUsers.filter(m => m._id !== user._id).slice(0, 4);

    for (const otherUser of otherUsers) {
      await ctx.db.insert("eventRsvps", {
        eventId: eventIds[0],
        userId: otherUser._id,
        status: "going",
        createdAt: now,
      });
    }

    return `Seeded ${events.length} events with ${otherUsers.length + 1} participants`;
  },
});
