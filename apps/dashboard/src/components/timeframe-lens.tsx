"use client";

import { useState } from "react";
import { Calendar, ChevronDown } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
} from "@/components/ui/dropdown-menu";

const RANGES = ["This week", "This month", "This semester", "All time"];

export function TimeframeLens() {
  const [range, setRange] = useState("This week");
  return (
    <DropdownMenu>
      <DropdownMenuTrigger
        render={
          <Button variant="ghost" className="h-8 gap-1.5 rounded-full px-3 text-[13px] font-medium text-muted-foreground" />
        }
      >
        <Calendar className="size-3.5" />
        {range}
        <ChevronDown className="size-3.5" />
      </DropdownMenuTrigger>
      <DropdownMenuContent align="start">
        <DropdownMenuRadioGroup value={range} onValueChange={setRange}>
          {RANGES.map((r) => (
            <DropdownMenuRadioItem key={r} value={r}>{r}</DropdownMenuRadioItem>
          ))}
        </DropdownMenuRadioGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
