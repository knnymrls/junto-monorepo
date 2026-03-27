"use client";

import { Sidebar } from "@/components/sidebar";
import { AuthGate } from "@/components/auth-gate";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <AuthGate>
      <div className="min-h-screen bg-background">
        <Sidebar />
        <main className="lg:pl-60">
          <div className="mx-auto max-w-6xl px-6 py-8 pt-16 lg:pt-8">
            {children}
          </div>
        </main>
      </div>
    </AuthGate>
  );
}
