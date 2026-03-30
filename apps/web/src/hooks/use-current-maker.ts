"use client";

import { useUser } from "@clerk/nextjs";
import { useQuery, useMutation } from "convex/react";
import { api } from "@junto/backend/convex/_generated/api";
import { useEffect, useRef } from "react";

export function useCurrentMaker() {
  const { user, isLoaded: isClerkLoaded } = useUser();
  const upsertMaker = useMutation(api.users.upsert);
  const hasTriedCreate = useRef(false);

  const maker = useQuery(
    api.users.getByClerkId,
    user ? { clerkId: user.id } : "skip"
  );

  // Auto-create maker profile if Clerk user exists but no maker record
  useEffect(() => {
    if (user && maker === null && !hasTriedCreate.current) {
      hasTriedCreate.current = true;
      const email = user.primaryEmailAddress?.emailAddress;
      const nameFromEmail = email ? email.split("@")[0].replace(/[._]/g, " ") : undefined;
      upsertMaker({
        clerkId: user.id,
        name: user.fullName || user.firstName || nameFromEmail || "New Maker",
        email,
        avatarUrl: user.imageUrl,
      });
    }
  }, [user, maker, upsertMaker]);

  return {
    maker: maker ?? null,
    isLoading: !isClerkLoaded || (user && maker === undefined),
    clerkUser: user,
  };
}
