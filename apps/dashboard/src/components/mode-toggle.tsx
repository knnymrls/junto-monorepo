"use client";

import { useEffect, useState } from "react";
import { useTheme } from "next-themes";
import { Sun, Moon } from "lucide-react";
import { Button } from "@/components/ui/button";

export function ModeToggle() {
  const { resolvedTheme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);

  const dark = resolvedTheme === "dark";
  return (
    <Button
      variant="ghost"
      size="icon"
      className="size-9 rounded-full text-muted-foreground"
      onClick={() => setTheme(dark ? "light" : "dark")}
      aria-label="Toggle theme"
    >
      {mounted && dark ? <Sun className="size-4" /> : <Moon className="size-4" />}
    </Button>
  );
}
