"use client";

import { createContext, useContext, useState } from "react";
import { ConvexProvider, ConvexReactClient } from "convex/react";
import { ThemeProvider } from "next-themes";
import { TooltipProvider } from "@/components/ui/tooltip";

const convex = new ConvexReactClient(
  process.env.NEXT_PUBLIC_CONVEX_URL || "https://placeholder.convex.cloud"
);

/* ---- cohort lens: the global filter shared across every surface ---- */
export const COHORTS = ["All", "Accelerator", "Catalyst", "Raikes"] as const;
export type Cohort = (typeof COHORTS)[number];

const CohortContext = createContext<{ cohort: Cohort; setCohort: (c: Cohort) => void }>({
  cohort: "All",
  setCohort: () => {},
});
export const useCohort = () => useContext(CohortContext);

export function Providers({ children }: { children: React.ReactNode }) {
  const [cohort, setCohort] = useState<Cohort>("All");
  return (
    <ConvexProvider client={convex}>
      <ThemeProvider attribute="class" defaultTheme="light" enableSystem={false} disableTransitionOnChange>
        <TooltipProvider delay={200}>
          <CohortContext.Provider value={{ cohort, setCohort }}>{children}</CohortContext.Provider>
        </TooltipProvider>
      </ThemeProvider>
    </ConvexProvider>
  );
}
