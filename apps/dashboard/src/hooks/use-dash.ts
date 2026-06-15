"use client";

import { useQuery } from "convex/react";
import { makeFunctionReference } from "convex/server";

/**
 * Reactive read of a backend dashboard query by name (e.g. "dashboard:overview").
 * Untyped on purpose so the dashboard app doesn't need the backend's generated
 * api types wired through the workspace. Returns `undefined` while loading.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function useDash<T = any>(name: string): T | undefined {
  const ref = makeFunctionReference<"query">(name);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return useQuery(ref as any, {}) as T | undefined;
}
