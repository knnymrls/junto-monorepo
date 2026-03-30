"use client";

import { useQuery } from "convex/react";
import { api } from "@junto/backend/convex/_generated/api";
import { useCurrentMaker } from "@/hooks/use-current-maker";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Avatar } from "@/components/avatar";
import { Search } from "lucide-react";
import { useState } from "react";
import Link from "next/link";

export default function DiscoverPage() {
  const { maker } = useCurrentMaker();
  const [query, setQuery] = useState("");

  const allMakers = useQuery(api.users.list, {});

  const searchResults = useQuery(
    api.users.searchForCards,
    query.length >= 2 && maker
      ? { query, currentUserId: maker._id, limit: 20 }
      : "skip"
  );

  const displayMakers = query.length >= 2 ? searchResults : allMakers;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Discover</h1>
        <p className="text-sm text-muted-foreground">
          Find makers to connect with
        </p>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search by name..."
          className="pl-9"
        />
      </div>

      {/* Makers Grid */}
      {displayMakers === undefined ? (
        <div className="grid gap-3 sm:grid-cols-2">
          {[1, 2, 3, 4, 5, 6].map((i) => (
            <Card key={i} size="sm">
              <CardContent>
                <div className="animate-pulse flex items-start gap-3">
                  <div className="h-10 w-10 rounded-full bg-muted" />
                  <div className="flex-1 space-y-1.5">
                    <div className="h-4 w-24 rounded bg-muted" />
                    <div className="h-3 w-32 rounded bg-muted" />
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : displayMakers.length === 0 ? (
        <div className="py-12 text-center text-muted-foreground text-sm">
          {query ? "No makers found" : "No makers yet"}
        </div>
      ) : (
        <>
          {query.length >= 2 && (
            <p className="text-sm text-muted-foreground">
              {displayMakers.length} result
              {displayMakers.length !== 1 ? "s" : ""}
            </p>
          )}
          <div className="grid gap-3 sm:grid-cols-2">
            {displayMakers
              .filter((m) => m._id !== maker?._id)
              .map((m) => (
                <Link key={m._id} href={`/profile/${m._id}`}>
                  <Card
                    size="sm"
                    className="hover:ring-foreground/20 hover:shadow-md transition-all cursor-pointer"
                  >
                    <CardContent className="flex items-start gap-3">
                      <Avatar src={m.avatarUrl} name={m.name} size="md" />
                      <div className="flex-1 min-w-0">
                        <p className="font-medium text-sm truncate">
                          {m.name}
                        </p>
                        {m.headline && (
                          <p className="text-xs text-muted-foreground truncate">
                            {m.headline}
                          </p>
                        )}
                        {m.lookingFor && (
                          <p className="mt-1 text-xs text-chart-2 truncate">
                            Looking for: {m.lookingFor}
                          </p>
                        )}
                        {m.skills && m.skills.length > 0 && (
                          <div className="mt-1.5 flex flex-wrap gap-1">
                            {m.skills.slice(0, 3).map((skill) => (
                              <Badge
                                key={skill}
                                variant="secondary"
                                className="text-[10px]"
                              >
                                {skill}
                              </Badge>
                            ))}
                          </div>
                        )}
                      </div>
                    </CardContent>
                  </Card>
                </Link>
              ))}
          </div>
        </>
      )}
    </div>
  );
}
