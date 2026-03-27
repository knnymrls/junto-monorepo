import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  // === USERS (PROFILES) ===
  users: defineTable({
    // Auth
    clerkId: v.string(),
    email: v.optional(v.string()),          // Auth email (from Clerk sign-in)
    phone: v.optional(v.string()),

    // Campus verification
    eduEmail: v.optional(v.string()),       // Their .edu email (may be same as auth email)
    eduVerified: v.optional(v.boolean()),   // Has verified .edu via OTP

    // Core identity
    name: v.string(),
    headline: v.optional(v.string()),       // "Introduce yourself as you would at a party"
    avatarUrl: v.optional(v.string()),

    // Academic
    universityId: v.optional(v.id("universities")),
    majors: v.optional(v.array(v.object({   // e.g. [{ majorId: "...", credentialLevel: 3 }]
      majorId: v.id("majors"),
      credentialLevel: v.number(),          // 3=Bachelor's, 5=Master's, 6=Doctoral
    }))),
    minors: v.optional(v.array(v.id("majors"))),
    graduationSemester: v.optional(v.string()),  // "Fall 2026"
    programs: v.optional(v.array(v.string())),   // ["Raikes School", "Accelerator"]

    // Matching (collected at onboarding)
    skills: v.optional(v.array(v.id("skills"))),
    interests: v.optional(v.array(v.id("interests"))),
    lookingFor: v.optional(v.string()),     // Free text — feeds needsEmbedding
    canHelpWith: v.optional(v.string()),    // Free text — feeds profileEmbedding

    // Enrichment (added post-onboarding)
    currentProject: v.optional(v.string()),
    socialLinks: v.optional(v.object({
      linkedin: v.optional(v.string()),
      instagram: v.optional(v.string()),
      twitter: v.optional(v.string()),
      github: v.optional(v.string()),
      website: v.optional(v.string()),
    })),

    // AI embeddings
    profileEmbedding: v.optional(v.array(v.float64())),  // 1536 dims — who they are
    needsEmbedding: v.optional(v.array(v.float64())),    // 1536 dims — what they need

    // Metadata
    role: v.optional(v.string()),           // Identity: "student" | "alumni" | "faculty"
    platformRole: v.optional(v.string()),   // Permissions: "user" | "creator" | "superadmin" (default "user")
    status: v.optional(v.string()),         // "active" | "graduated" | "deactivated"
    isOnboarded: v.boolean(),
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_clerk_id", ["clerkId"])
    .index("by_email", ["email"])
    .index("by_edu_email", ["eduEmail"])
    .index("by_university", ["universityId"])
    .searchIndex("search_name", {
      searchField: "name",
    })
    .searchIndex("search_headline", {
      searchField: "headline",
      filterFields: ["universityId", "role", "platformRole"]
    })
    .vectorIndex("by_profile_embedding", {
      vectorField: "profileEmbedding",
      dimensions: 1536,
      filterFields: ["universityId", "role"]
    })
    .vectorIndex("by_needs_embedding", {
      vectorField: "needsEmbedding",
      dimensions: 1536,
      filterFields: ["universityId", "role"]
    }),

  // === CONNECTIONS ===
  connections: defineTable({
    requesterId: v.id("users"),   // Who initiated
    accepterId: v.id("users"),    // Who accepted
    status: v.string(),            // "pending", "connected"
    connectedAt: v.optional(v.number()),
    createdAt: v.number(),
  })
    .index("by_requester", ["requesterId"])
    .index("by_accepter", ["accepterId"])
    .index("by_status", ["status"]),

  // === EVENTS ===
  events: defineTable({
    title: v.string(),
    description: v.optional(v.string()),
    date: v.number(),              // Unix timestamp
    endDate: v.optional(v.number()),
    location: v.optional(v.string()),         // Public location (e.g. "Lincoln, NE")
    fullAddress: v.optional(v.string()),      // Full address revealed after RSVP
    type: v.string(),              // "in_person", "online", "hybrid"
    imageUrl: v.optional(v.string()),
    createdBy: v.id("users"),
    universityId: v.optional(v.id("universities")),
    createdAt: v.number(),
  })
    .index("by_date", ["date"])
    .index("by_university", ["universityId"]),

  // === EVENT RSVPs ===
  eventRsvps: defineTable({
    eventId: v.id("events"),
    userId: v.id("users"),
    status: v.string(),            // "going", "interested", "not_going"
    addedToCalendar: v.optional(v.boolean()),
    createdAt: v.number(),
  })
    .index("by_event", ["eventId"])
    .index("by_user", ["userId"]),

  // === EVENT FEEDBACK ===
  eventFeedback: defineTable({
    eventId: v.id("events"),
    userId: v.id("users"),
    rating: v.number(),
    improvements: v.array(v.string()),
    wantToConnectWith: v.array(v.id("users")),
    createdAt: v.number(),
  })
    .index("by_event", ["eventId"])
    .index("by_user", ["userId"])
    .index("by_event_and_user", ["eventId", "userId"]),

  // === POSTS (FEED) ===
  posts: defineTable({
    authorId: v.id("users"),
    content: v.string(),
    category: v.union(v.literal("asking"), v.literal("sharing"), v.literal("looking_for")),
    imageUrl: v.optional(v.string()),           // Legacy single image
    imageUrls: v.optional(v.array(v.string())), // Multiple images
    linkUrl: v.optional(v.string()),
    gifUrl: v.optional(v.string()),
    embedding: v.optional(v.array(v.float64())),
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_author", ["authorId"])
    .index("by_created", ["createdAt"])
    .vectorIndex("by_embedding", {
      vectorField: "embedding",
      dimensions: 1536,
    }),

  // === COMMENTS ===
  comments: defineTable({
    postId: v.id("posts"),
    authorId: v.id("users"),
    content: v.string(),
    mentions: v.optional(v.array(v.id("users"))),
    imageUrl: v.optional(v.string()),
    linkUrl: v.optional(v.string()),
    gifUrl: v.optional(v.string()),
    createdAt: v.number(),
  })
    .index("by_post", ["postId"])
    .index("by_author", ["authorId"]),

  // === UNIVERSITIES ===
  universities: defineTable({
    name: v.string(),                                // "University of Nebraska-Lincoln"
    shortName: v.optional(v.string()),               // "UNL"
    domains: v.optional(v.array(v.string())),        // ["nebraska.edu", "unl.edu"]
    logoUrl: v.optional(v.string()),                   // Original external URL (logo.dev)
    logoStorageId: v.optional(v.string()),             // Convex file storage ID (owned copy)
    city: v.string(),
    state: v.string(),                               // "NE"

    // Classification (from College Scorecard)
    scorecardId: v.optional(v.number()),             // UNITID for linking back to FindU data
    carnegieClassification: v.optional(v.number()),  // 15=R1, 16=R2, etc.
    institutionLevel: v.optional(v.number()),        // 1=4-year, 2=2-year, 3=<2-year
    isHbcu: v.optional(v.boolean()),
    isHsi: v.optional(v.boolean()),

    // Business
    plan: v.string(),                                // "pilot" | "paid" | "prospect" | "none"
    programs: v.optional(v.array(v.string())),       // University-specific programs: ["Raikes School", "Catalyst"]
    isActive: v.boolean(),                           // Live on Junto

    createdAt: v.number(),
  })
    .index("by_state", ["state"])
    .index("by_plan", ["plan"])
    .index("by_active", ["isActive"])
    .searchIndex("search_name", {
      searchField: "name",
    }),

  // === MAJORS (master list of academic programs) ===
  majors: defineTable({
    name: v.string(),                    // "Computer Science" (clean display name)
    cipCode: v.string(),                 // "1101" (4-digit CIP code)
    category: v.string(),                // "Computing & IT"
  })
    .index("by_cip_code", ["cipCode"])
    .index("by_category", ["category"])
    .searchIndex("search_name", {
      searchField: "name",
    }),

  // === UNIVERSITY MAJORS (what each university actually offers) ===
  universityMajors: defineTable({
    universityId: v.id("universities"),
    majorId: v.id("majors"),
    credentialLevel: v.number(),         // 3=Bachelor's, 5=Master's, 6=Doctoral, etc.
    credentialTitle: v.string(),         // "Bachelor's Degree"
  })
    .index("by_university", ["universityId"])
    .index("by_major", ["majorId"])
    .index("by_university_major", ["universityId", "majorId"]),

  // === SKILLS (curated, universal) ===
  skills: defineTable({
    name: v.string(),                    // "UI Design"
    category: v.string(),                // "Design"
  })
    .index("by_category", ["category"])
    .searchIndex("search_name", {
      searchField: "name",
    }),

  // === INTERESTS (curated, universal) ===
  interests: defineTable({
    name: v.string(),                    // "Artificial Intelligence"
    category: v.string(),                // "Technology"
  })
    .index("by_category", ["category"])
    .searchIndex("search_name", {
      searchField: "name",
    }),

  // === UNIVERSITY ROLES (scoped permissions per university) ===
  universityRoles: defineTable({
    userId: v.id("users"),
    universityId: v.id("universities"),
    role: v.string(),                        // "owner" | "admin" | "moderator" | "rep"
    grantedAt: v.number(),
    expiresAt: v.optional(v.number()),       // For temporary roles (e.g. semester moderator)
    grantedBy: v.optional(v.id("users")),    // Audit trail
  })
    .index("by_user", ["userId"])
    .index("by_university", ["universityId"])
    .index("by_user_university", ["userId", "universityId"]),

  // === CONVERSATIONS ===
  conversations: defineTable({
    participant1Id: v.id("users"),     // Lexicographically smaller ID always
    participant2Id: v.id("users"),     // Lexicographically larger ID always
    lastMessageAt: v.number(),
    lastMessagePreview: v.optional(v.string()),
    lastMessageSenderId: v.optional(v.id("users")),
    participant1UnreadCount: v.number(),
    participant2UnreadCount: v.number(),
    status: v.optional(v.string()),            // "active" | "request" (default active)
    initiatorId: v.optional(v.id("users")),   // Who started the conversation (for requests)
    createdAt: v.number(),
  })
    .index("by_participant1", ["participant1Id"])
    .index("by_participant2", ["participant2Id"]),

  // === MESSAGES ===
  messages: defineTable({
    conversationId: v.id("conversations"),
    senderId: v.id("users"),
    content: v.string(),
    gifUrl: v.optional(v.string()),
    readAt: v.optional(v.number()),
    createdAt: v.number(),
  })
    .index("by_conversation", ["conversationId", "createdAt"]),

  // === TYPING INDICATORS (ephemeral) ===
  typingIndicators: defineTable({
    conversationId: v.id("conversations"),
    userId: v.id("users"),
    expiresAt: v.number(),
  })
    .index("by_conversation", ["conversationId"]),

  // === AI SEARCH CHATS ===
  searchChats: defineTable({
    userId: v.id("users"),
    title: v.string(),
    lastQueryAt: v.number(),
    lastQueryPreview: v.optional(v.string()),
    createdAt: v.number(),
  })
    .index("by_user", ["userId", "lastQueryAt"]),

  searchMessages: defineTable({
    chatId: v.id("searchChats"),
    role: v.string(),
    content: v.string(),
    results: v.optional(v.string()),
    createdAt: v.number(),
  })
    .index("by_chat", ["chatId", "createdAt"]),

  // === PORTFOLIO ITEMS ===
  portfolioItems: defineTable({
    userId: v.id("users"),
    type: v.union(
      v.literal("github"),
      v.literal("gallery"),
      v.literal("link"),
      v.literal("experience")
    ),
    title: v.optional(v.string()),
    url: v.optional(v.string()),
    description: v.optional(v.string()),
    imageUrls: v.optional(v.array(v.string())),
    organization: v.optional(v.string()),
    startDate: v.optional(v.string()),
    endDate: v.optional(v.string()),
    size: v.optional(v.union(v.literal("small"), v.literal("medium"), v.literal("large"))),
    order: v.number(),
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_user", ["userId"]),

  // === DEVICE TOKENS (for push notifications) ===
  deviceTokens: defineTable({
    userId: v.id("users"),
    token: v.string(),              // APNs device token (hex string)
    platform: v.string(),           // "ios" | "android"
    appVersion: v.optional(v.string()),
    deviceModel: v.optional(v.string()),
    osVersion: v.optional(v.string()),
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_user", ["userId"])
    .index("by_token", ["token"]),

  // === NOTIFICATIONS (in-app notifications) ===
  notifications: defineTable({
    recipientId: v.id("users"),
    type: v.string(),               // "comment", "mention", "connection_request", "connection_accepted"
    title: v.string(),
    body: v.optional(v.string()),
    data: v.optional(v.object({
      postId: v.optional(v.id("posts")),
      commentId: v.optional(v.id("comments")),
      senderId: v.optional(v.id("users")),
      connectionId: v.optional(v.id("connections")),
      eventId: v.optional(v.id("events")),
      conversationId: v.optional(v.id("conversations")),
    })),
    readAt: v.optional(v.number()),
    createdAt: v.number(),
  })
    .index("by_recipient", ["recipientId"])
    .index("by_recipient_unread", ["recipientId", "readAt"]),

  // === SEARCH SESSIONS (streaming AI search) ===
  searchSessions: defineTable({
    userId: v.id("users"),
    query: v.string(),
    status: v.string(),                    // "pending" | "streaming" | "complete" | "error"
    thinkingText: v.optional(v.string()),
    results: v.optional(v.string()),       // JSON string of partial SearchResult[]
    resultCount: v.optional(v.number()),
    createdAt: v.number(),
    updatedAt: v.number(),
  }).index("by_user", ["userId", "createdAt"]),

  // === DAILY MATCHES (pre-computed AI matches) ===
  dailyMatches: defineTable({
    userId: v.id("users"),
    matches: v.array(v.object({
      matchId: v.id("users"),
      matchReason: v.string(),
    })),
    date: v.string(),          // "2026-02-16" — one row per user per day
    generatedAt: v.number(),
  })
    .index("by_user_date", ["userId", "date"])
    .index("by_date", ["date"]),

  // === REPORTS ===
  reports: defineTable({
    reporterId: v.id("users"),
    postId: v.id("posts"),
    reason: v.string(),             // "spam", "harassment", "inappropriate", "other"
    details: v.optional(v.string()),
    status: v.string(),             // "pending", "reviewed", "dismissed"
    createdAt: v.number(),
  })
    .index("by_post", ["postId"])
    .index("by_status", ["status"]),

  // === VOUCHES ===
  vouches: defineTable({
    fromUserId: v.id("users"),
    toUserId: v.id("users"),
    reason: v.string(),              // "Built the entire matching algorithm"
    createdAt: v.number(),
  })
    .index("by_from_user", ["fromUserId"])
    .index("by_to_user", ["toUserId"])
    .index("by_created", ["createdAt"]),

  // === AI INSIGHTS (pre-computed feed cards) ===
  insights: defineTable({
    targetUserId: v.id("users"),     // Who this insight is for
    type: v.union(
      v.literal("match"),
      v.literal("skill_gap"),
      v.literal("cluster"),
      v.literal("event_rec")
    ),
    headline: v.string(),            // "Meet Elena — she's a designer"
    body: v.string(),                // Full description
    relatedUserIds: v.array(v.id("users")),
    relatedEventId: v.optional(v.id("events")),
    actionType: v.union(             // What CTA to show
      v.literal("connect"),
      v.literal("view"),
      v.literal("post"),
      v.literal("rsvp")
    ),
    relevanceScore: v.number(),      // 0-1, higher = more relevant
    dismissed: v.boolean(),
    interactedWith: v.boolean(),
    fingerprint: v.string(),         // Dedup key (type + related users + context hash)
    expiresAt: v.number(),
    createdAt: v.number(),
  })
    .index("by_target_user", ["targetUserId"])
    .index("by_target_active", ["targetUserId", "dismissed", "expiresAt"])
    .index("by_fingerprint", ["fingerprint"])
    .index("by_created", ["createdAt"]),
});
