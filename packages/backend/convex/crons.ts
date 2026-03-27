import { cronJobs } from "convex/server";
import { internal } from "./_generated/api";

const crons = cronJobs();

// Event reminders — every 15 min, notifies "going" RSVPs when event is ~1hr away
crons.interval(
  "event reminders",
  { minutes: 15 },
  internal.reengagement.sendEventReminders
);

// Pending connection nudges — every 6 hours, nudges unanswered requests > 24h
crons.interval(
  "pending connection nudges",
  { hours: 6 },
  internal.reengagement.sendPendingConnectionNudges
);

// Weekly digest — Saturday 10am CT (16:00 UTC)
crons.weekly(
  "weekly digest",
  { dayOfWeek: "saturday", hourUTC: 16, minuteUTC: 0 },
  internal.reengagement.sendWeeklyDigest
);

// Inactivity nudges — daily at 10am CT (16:00 UTC)
crons.daily(
  "inactivity nudges",
  { hourUTC: 16, minuteUTC: 0 },
  internal.reengagement.sendInactivityNudges
);

// Milestone celebrations — daily at noon CT (18:00 UTC)
crons.daily(
  "milestone celebrations",
  { hourUTC: 18, minuteUTC: 0 },
  internal.reengagement.sendMilestoneCelebrations
);

// Content prompts — Thursday 10am CT (16:00 UTC)
crons.weekly(
  "content prompts",
  { dayOfWeek: "thursday", hourUTC: 16, minuteUTC: 0 },
  internal.reengagement.sendContentPrompts
);

// Daily matches — 6am CT (12:00 UTC)
crons.daily(
  "daily matches",
  { hourUTC: 12, minuteUTC: 0 },
  internal.dailyMatches.generateForAllUsers
);

export default crons;
