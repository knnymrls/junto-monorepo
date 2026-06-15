"use client";

import * as React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { House, Share2, Inbox, CalendarDays, Sparkles } from "lucide-react";
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarRail,
} from "@/components/ui/sidebar";
import { TeamSwitcher } from "./team-switcher";
import { NavUser } from "./nav-user";
import { SidebarSearch } from "./sidebar-search";

// Flat, ordered by Amanda's loop: see -> act/run -> explore. Ask sits apart (AI omnibox).
const NAV = [
  { href: "/home", label: "Home", icon: House },
  { href: "/map", label: "Map", icon: Share2 },
  { href: "/needs", label: "Needs", icon: Inbox },
  { href: "/events", label: "Events", icon: CalendarDays },
  { href: "/ask", label: "Ask Junto", icon: Sparkles },
];

function NavItems({ items, pathname }: { items: typeof NAV; pathname: string }) {
  return (
    <SidebarMenu>
      {items.map((it) => {
        const active = pathname === it.href || pathname.startsWith(it.href + "/");
        return (
          <SidebarMenuItem key={it.href}>
            <SidebarMenuButton isActive={active} tooltip={it.label} render={<Link href={it.href} />}>
              <it.icon />
              <span>{it.label}</span>
            </SidebarMenuButton>
          </SidebarMenuItem>
        );
      })}
    </SidebarMenu>
  );
}

export function AppSidebar({ ...props }: React.ComponentProps<typeof Sidebar>) {
  const pathname = usePathname();
  return (
    <Sidebar collapsible="icon" {...props}>
      <SidebarHeader>
        <TeamSwitcher />
        <SidebarSearch />
      </SidebarHeader>
      <SidebarContent>
        <SidebarGroup>
          <NavItems items={NAV} pathname={pathname} />
        </SidebarGroup>
      </SidebarContent>
      <SidebarFooter>
        <NavUser />
      </SidebarFooter>
      <SidebarRail />
    </Sidebar>
  );
}
