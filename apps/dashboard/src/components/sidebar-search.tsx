"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Search, House, Share2, Inbox, CalendarDays, Sparkles } from "lucide-react";
import {
  Command,
  CommandDialog,
  CommandInput,
  CommandList,
  CommandEmpty,
  CommandGroup,
  CommandItem,
} from "@/components/ui/command";

const PAGES = [
  { href: "/home", label: "Home", icon: House },
  { href: "/map", label: "Map", icon: Share2 },
  { href: "/needs", label: "Needs", icon: Inbox },
  { href: "/events", label: "Events", icon: CalendarDays },
  { href: "/ask", label: "Ask Junto", icon: Sparkles },
];

export function SidebarSearch() {
  const [open, setOpen] = useState(false);
  const router = useRouter();

  useEffect(() => {
    const down = (e: KeyboardEvent) => {
      if (e.key === "k" && (e.metaKey || e.ctrlKey)) {
        e.preventDefault();
        setOpen((o) => !o);
      }
    };
    document.addEventListener("keydown", down);
    return () => document.removeEventListener("keydown", down);
  }, []);

  const go = (href: string) => {
    setOpen(false);
    router.push(href);
  };

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="flex h-8 w-full items-center gap-2 rounded-xl bg-muted px-2.5 text-sm text-muted-foreground transition-colors hover:bg-accent group-data-[collapsible=icon]:hidden"
      >
        <Search className="size-4 shrink-0" />
        <span className="flex-1 truncate text-left">Search…</span>
        <kbd className="pointer-events-none rounded border bg-background px-1.5 font-mono text-[10px] tracking-wider">
          ⌘K
        </kbd>
      </button>

      <CommandDialog open={open} onOpenChange={setOpen}>
        <Command>
          <CommandInput placeholder="Search students, events, pages…" />
          <CommandList>
            <CommandEmpty>No results found.</CommandEmpty>
            <CommandGroup heading="Go to">
              {PAGES.map((p) => (
                <CommandItem key={p.href} value={p.label} onSelect={() => go(p.href)}>
                  <p.icon />
                  {p.label}
                </CommandItem>
              ))}
            </CommandGroup>
          </CommandList>
        </Command>
      </CommandDialog>
    </>
  );
}
