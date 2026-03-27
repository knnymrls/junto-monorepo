"use client";

import { Sidebar } from "@/components/sidebar";
import {
  SignIn,
  SignedIn,
  SignedOut,
  ClerkLoaded,
  ClerkLoading,
} from "@clerk/nextjs";

export default function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <ClerkLoading>
        <div className="flex min-h-screen items-center justify-center">
          <div className="space-y-3 text-center">
            <div className="h-8 w-8 mx-auto animate-spin rounded-full border-2 border-primary border-t-transparent" />
            <p className="text-xs text-muted-foreground">Connecting...</p>
          </div>
        </div>
      </ClerkLoading>

      <ClerkLoaded>
        <SignedOut>
          <div className="flex min-h-screen items-center justify-center bg-background">
            <div className="w-full max-w-md">
              <div className="mb-8 text-center">
                <h1 className="text-2xl font-bold tracking-tight">
                  mkrs.world
                </h1>
                <p className="mt-1 text-sm text-muted-foreground">
                  Find your people. Build together.
                </p>
              </div>
              <SignIn routing="hash" />
            </div>
          </div>
        </SignedOut>

        <SignedIn>
          <div className="min-h-screen bg-background">
            <Sidebar />
            <main className="lg:pl-60">
              <div className="mx-auto max-w-3xl px-6 py-8 pt-16 lg:pt-8">
                {children}
              </div>
            </main>
          </div>
        </SignedIn>
      </ClerkLoaded>
    </>
  );
}
