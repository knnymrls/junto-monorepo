"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Newspaper,
  Search,
  MessageCircle,
  Calendar,
  Bell,
  User,
  Menu,
  X,
} from "lucide-react";
import { useState } from "react";
import { cn } from "@/lib/utils";
import { useQuery } from "convex/react";
import { api } from "@junto/backend/convex/_generated/api";
import { useCurrentMaker } from "@/hooks/use-current-maker";

const navItems = [
  { href: "/feed", label: "Feed", icon: Newspaper },
  { href: "/discover", label: "Discover", icon: Search },
  { href: "/messages", label: "Messages", icon: MessageCircle },
  { href: "/events", label: "Events", icon: Calendar },
  { href: "/notifications", label: "Notifications", icon: Bell },
];

export function Sidebar() {
  const pathname = usePathname();
  const [mobileOpen, setMobileOpen] = useState(false);
  const { maker } = useCurrentMaker();

  const unreadMessages = useQuery(
    api.messages.getUnreadMessageCount,
    maker ? { makerId: maker._id } : "skip"
  );

  const unreadNotifications = useQuery(
    api.notifications.getUnreadCount,
    maker ? { makerId: maker._id } : "skip"
  );

  return (
    <>
      {/* Mobile menu button */}
      <button
        onClick={() => setMobileOpen(true)}
        className="fixed top-4 left-4 z-50 rounded-md bg-sidebar p-2 text-sidebar-foreground/70 hover:text-sidebar-foreground lg:hidden"
      >
        <Menu className="h-5 w-5" />
      </button>

      {/* Mobile overlay */}
      {mobileOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/50 lg:hidden"
          onClick={() => setMobileOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={cn(
          "fixed inset-y-0 left-0 z-50 flex w-60 flex-col bg-sidebar border-r border-sidebar-border transition-transform duration-200 lg:translate-x-0",
          mobileOpen ? "translate-x-0" : "-translate-x-full"
        )}
      >
        {/* Close button (mobile) */}
        <button
          onClick={() => setMobileOpen(false)}
          className="absolute top-4 right-4 text-sidebar-foreground/50 hover:text-sidebar-foreground lg:hidden"
        >
          <X className="h-4 w-4" />
        </button>

        {/* Header */}
        <div className="px-6 py-6">
          <h1 className="text-lg font-bold text-sidebar-foreground tracking-tight">
            mkrs.world
          </h1>
          <p className="mt-0.5 text-xs text-sidebar-foreground/40 leading-tight">
            Find your people
          </p>
        </div>

        {/* Navigation */}
        <nav className="flex-1 space-y-1 px-3">
          {navItems.map((item) => {
            const isActive =
              pathname === item.href ||
              pathname.startsWith(item.href + "/");

            const badge =
              item.href === "/messages"
                ? unreadMessages
                : item.href === "/notifications"
                  ? unreadNotifications
                  : undefined;

            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setMobileOpen(false)}
                className={cn(
                  "flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors",
                  isActive
                    ? "bg-primary text-primary-foreground"
                    : "text-sidebar-foreground/60 hover:bg-sidebar-accent hover:text-sidebar-foreground"
                )}
              >
                <item.icon className="h-4 w-4" />
                {item.label}
                {badge !== undefined && badge > 0 ? (
                  <span className="ml-auto flex h-5 w-5 items-center justify-center rounded-full bg-chart-2 text-[10px] font-bold text-white">
                    {badge > 99 ? "99+" : badge}
                  </span>
                ) : null}
              </Link>
            );
          })}
        </nav>

        {/* Profile link */}
        {maker && (
          <div className="border-t border-sidebar-border px-3 py-3">
            <Link
              href={`/profile/${maker._id}`}
              onClick={() => setMobileOpen(false)}
              className={cn(
                "flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors",
                pathname.startsWith("/profile")
                  ? "bg-primary text-primary-foreground"
                  : "text-sidebar-foreground/60 hover:bg-sidebar-accent hover:text-sidebar-foreground"
              )}
            >
              <User className="h-4 w-4" />
              Profile
            </Link>
          </div>
        )}

        {/* Footer */}
        <div className="px-6 py-4 border-t border-sidebar-border">
          <p className="text-xs text-sidebar-foreground/25">
            mkrs.world v2.0
          </p>
        </div>
      </aside>
    </>
  );
}
