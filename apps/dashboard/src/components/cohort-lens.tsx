"use client";

import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { COHORTS, useCohort, type Cohort } from "@/app/providers";

export function CohortLens() {
  const { cohort, setCohort } = useCohort();
  return (
    <Tabs value={cohort} onValueChange={(v) => setCohort(v as Cohort)}>
      <TabsList>
        {COHORTS.map((c) => (
          <TabsTrigger key={c} value={c}>
            {c}
          </TabsTrigger>
        ))}
      </TabsList>
    </Tabs>
  );
}
