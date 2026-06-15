"use client";

import { usePathname } from "next/navigation";

const LABELS: Record<string, string> = {
  home: "Home",
  map: "The Map",
  needs: "Needs",
  events: "Events",
  ask: "Ask Junto",
  report: "The Report",
};

export function HeaderTitle() {
  const seg = usePathname().split("/").filter(Boolean)[0] ?? "home";
  return <span className="text-sm font-medium">{LABELS[seg] ?? "Home"}</span>;
}
