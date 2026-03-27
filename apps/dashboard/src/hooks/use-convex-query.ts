"use client";

import { useState, useEffect, useCallback } from "react";
import { queryDashboard } from "@/lib/convex";

export function useConvexQuery<T>(functionName: string) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [tick, setTick] = useState(0);

  const refetch = useCallback(() => {
    setLoading(true);
    setTick((t) => t + 1);
  }, []);

  useEffect(() => {
    let cancelled = false;

    queryDashboard<T>(functionName)
      .then((result) => {
        if (!cancelled) {
          setData(result);
          setLoading(false);
        }
      })
      .catch((err) => {
        if (!cancelled) {
          setError(err.message);
          setLoading(false);
        }
      });

    return () => {
      cancelled = true;
    };
  }, [functionName, tick]);

  return { data, loading, error, refetch };
}
