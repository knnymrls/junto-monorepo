/* eslint-disable */
/**
 * Generated `api` utility.
 *
 * THIS CODE IS AUTOMATICALLY GENERATED.
 *
 * To regenerate, run `npx convex dev`.
 * @module
 */

import type * as comments from "../comments.js";
import type * as connections from "../connections.js";
import type * as crons from "../crons.js";
import type * as dashboard from "../dashboard.js";
import type * as deviceTokens from "../deviceTokens.js";
import type * as embeddings from "../embeddings.js";
import type * as events from "../events.js";
import type * as feed from "../feed.js";
import type * as feedScoring from "../feedScoring.js";
import type * as http from "../http.js";
import type * as inviteLinks from "../inviteLinks.js";
import type * as majorCache from "../majorCache.js";
import type * as matching from "../matching.js";
import type * as mentions from "../mentions.js";
import type * as messages from "../messages.js";
import type * as notifications from "../notifications.js";
import type * as onboarding from "../onboarding.js";
import type * as portfolio from "../portfolio.js";
import type * as posts from "../posts.js";
import type * as reengagement from "../reengagement.js";
import type * as referenceData from "../referenceData.js";
import type * as reports from "../reports.js";
import type * as search from "../search.js";
import type * as searchChats from "../searchChats.js";
import type * as searchSessions from "../searchSessions.js";
import type * as seed from "../seed.js";
import type * as storage from "../storage.js";
import type * as topics from "../topics.js";
import type * as users from "../users.js";
import type * as vouches from "../vouches.js";
import type * as weeklyMatches from "../weeklyMatches.js";

import type {
  ApiFromModules,
  FilterApi,
  FunctionReference,
} from "convex/server";

declare const fullApi: ApiFromModules<{
  comments: typeof comments;
  connections: typeof connections;
  crons: typeof crons;
  dashboard: typeof dashboard;
  deviceTokens: typeof deviceTokens;
  embeddings: typeof embeddings;
  events: typeof events;
  feed: typeof feed;
  feedScoring: typeof feedScoring;
  http: typeof http;
  inviteLinks: typeof inviteLinks;
  majorCache: typeof majorCache;
  matching: typeof matching;
  mentions: typeof mentions;
  messages: typeof messages;
  notifications: typeof notifications;
  onboarding: typeof onboarding;
  portfolio: typeof portfolio;
  posts: typeof posts;
  reengagement: typeof reengagement;
  referenceData: typeof referenceData;
  reports: typeof reports;
  search: typeof search;
  searchChats: typeof searchChats;
  searchSessions: typeof searchSessions;
  seed: typeof seed;
  storage: typeof storage;
  topics: typeof topics;
  users: typeof users;
  vouches: typeof vouches;
  weeklyMatches: typeof weeklyMatches;
}>;

/**
 * A utility for referencing Convex functions in your app's public API.
 *
 * Usage:
 * ```js
 * const myFunctionReference = api.myModule.myFunction;
 * ```
 */
export declare const api: FilterApi<
  typeof fullApi,
  FunctionReference<any, "public">
>;

/**
 * A utility for referencing Convex functions in your app's internal API.
 *
 * Usage:
 * ```js
 * const myFunctionReference = internal.myModule.myFunction;
 * ```
 */
export declare const internal: FilterApi<
  typeof fullApi,
  FunctionReference<any, "internal">
>;

export declare const components: {};
