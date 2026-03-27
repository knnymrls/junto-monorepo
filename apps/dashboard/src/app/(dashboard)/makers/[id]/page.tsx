"use client";

import { useParams, useRouter } from "next/navigation";
import { useConvexQuery } from "@/hooks/use-convex-query";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";
import Link from "next/link";

type MakerProfile = {
  id: string;
  name: string;
  username: string;
  avatarUrl: string | null;
  headline: string | null;
  bio: string | null;
  skills: string[];
  interests: string[];
  lookingFor: string | null;
  canHelpWith: string | null;
  createdAt: number;
  connectionCount: number;
  connections: { id: string; name: string; username: string }[];
  postCount: number;
  commentCount: number;
  recentPosts: { id: string; content: string; createdAt: number }[];
};

function timeAgo(ts: number): string {
  const diff = Date.now() - ts;
  const mins = Math.floor(diff / 60000);
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}

export default function MakerDetailPage() {
  const params = useParams();
  const router = useRouter();
  const makerId = params.id as string;

  const { data: profiles, loading } =
    useConvexQuery<MakerProfile[]>("dashboard:makerProfile");

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <p className="text-sm text-muted-foreground">Loading...</p>
      </div>
    );
  }

  const maker = profiles?.find((p) => p.id === makerId);

  if (!maker) {
    return (
      <div className="space-y-4">
        <Button variant="ghost" size="sm" onClick={() => router.push("/makers")}>
          <ArrowLeft className="h-4 w-4 mr-1" /> Back to network
        </Button>
        <p className="text-sm text-muted-foreground">Maker not found.</p>
      </div>
    );
  }

  const skillsList = maker.skills.length > 0 ? maker.skills : [];
  const interestsList = maker.interests.length > 0 ? maker.interests : [];
  const lookingForList = maker.lookingFor
    ? maker.lookingFor.split(",").map((s) => s.trim()).filter(Boolean)
    : [];
  const canHelpWithList = maker.canHelpWith
    ? maker.canHelpWith.split(",").map((s) => s.trim()).filter(Boolean)
    : [];

  return (
    <div className="space-y-6">
      <Button variant="ghost" size="sm" onClick={() => router.push("/makers")}>
        <ArrowLeft className="h-4 w-4 mr-1" /> Back to network
      </Button>

      {/* Profile header */}
      <div className="flex items-start gap-5">
        {maker.avatarUrl ? (
          <img
            src={maker.avatarUrl}
            alt={maker.name}
            className="h-20 w-20 rounded-full object-cover ring-2 ring-border"
          />
        ) : (
          <div className="flex h-20 w-20 items-center justify-center rounded-full bg-primary/10 text-2xl font-bold text-primary ring-2 ring-border">
            {maker.name
              .split(" ")
              .map((n) => n[0])
              .join("")
              .slice(0, 2)}
          </div>
        )}
        <div className="space-y-1">
          <h2 className="text-2xl font-bold tracking-tight">{maker.name}</h2>
          <p className="text-sm text-muted-foreground">@{maker.username}</p>
          {maker.headline && (
            <p className="text-sm text-foreground">{maker.headline}</p>
          )}
          <p className="text-xs text-muted-foreground">
            Joined {new Date(maker.createdAt).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}
          </p>
        </div>
      </div>

      {/* Stats row */}
      <div className="grid gap-4 sm:grid-cols-4">
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Connections</CardDescription>
          </CardHeader>
          <CardContent>
            <span className="text-3xl font-bold">{maker.connectionCount}</span>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Posts</CardDescription>
          </CardHeader>
          <CardContent>
            <span className="text-3xl font-bold">{maker.postCount}</span>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Comments</CardDescription>
          </CardHeader>
          <CardContent>
            <span className="text-3xl font-bold">{maker.commentCount}</span>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Skills</CardDescription>
          </CardHeader>
          <CardContent>
            <span className="text-3xl font-bold">{skillsList.length}</span>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Bio */}
        {maker.bio && (
          <Card className="lg:col-span-2">
            <CardHeader>
              <CardTitle>Bio</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-foreground whitespace-pre-wrap">{maker.bio}</p>
            </CardContent>
          </Card>
        )}

        {/* Skills & Interests */}
        <Card>
          <CardHeader>
            <CardTitle>Skills</CardTitle>
          </CardHeader>
          <CardContent>
            {skillsList.length > 0 ? (
              <div className="flex flex-wrap gap-1.5">
                {skillsList.map((skill) => (
                  <Badge key={skill} variant="secondary">
                    {skill}
                  </Badge>
                ))}
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">No skills listed</p>
            )}

            {interestsList.length > 0 && (
              <>
                <p className="text-xs font-medium text-muted-foreground mt-4 mb-2">Interests</p>
                <div className="flex flex-wrap gap-1.5">
                  {interestsList.map((interest) => (
                    <Badge key={interest} variant="outline">
                      {interest}
                    </Badge>
                  ))}
                </div>
              </>
            )}
          </CardContent>
        </Card>

        {/* Looking for / Can help with */}
        <Card>
          <CardHeader>
            <CardTitle>Collaboration</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {lookingForList.length > 0 && (
              <div>
                <p className="text-xs font-medium text-muted-foreground mb-2">Looking for</p>
                <div className="flex flex-wrap gap-1.5">
                  {lookingForList.map((item) => (
                    <Badge key={item} className="bg-amber-50 text-amber-800 border-amber-200 hover:bg-amber-50">
                      {item}
                    </Badge>
                  ))}
                </div>
              </div>
            )}
            {canHelpWithList.length > 0 && (
              <div>
                <p className="text-xs font-medium text-muted-foreground mb-2">Can help with</p>
                <div className="flex flex-wrap gap-1.5">
                  {canHelpWithList.map((item) => (
                    <Badge key={item} className="bg-emerald-50 text-emerald-800 border-emerald-200 hover:bg-emerald-50">
                      {item}
                    </Badge>
                  ))}
                </div>
              </div>
            )}
            {lookingForList.length === 0 && canHelpWithList.length === 0 && (
              <p className="text-sm text-muted-foreground">No collaboration preferences set</p>
            )}
          </CardContent>
        </Card>

        {/* Connections list */}
        <Card>
          <CardHeader>
            <CardTitle>Connections</CardTitle>
            <CardDescription>{maker.connectionCount} connected makers</CardDescription>
          </CardHeader>
          <CardContent>
            {maker.connections.length > 0 ? (
              <div className="space-y-2">
                {maker.connections.map((conn) => (
                  <Link
                    key={conn.id}
                    href={`/makers/${conn.id}`}
                    className="flex items-center gap-2 rounded-lg p-2 -mx-2 hover:bg-accent transition-colors"
                  >
                    <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary/10 text-xs font-semibold text-primary">
                      {conn.name.split(" ").map((n) => n[0]).join("").slice(0, 2)}
                    </div>
                    <div>
                      <p className="text-sm font-medium">{conn.name}</p>
                      <p className="text-xs text-muted-foreground">@{conn.username}</p>
                    </div>
                  </Link>
                ))}
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">No connections yet</p>
            )}
          </CardContent>
        </Card>

        {/* Recent posts */}
        <Card>
          <CardHeader>
            <CardTitle>Recent Posts</CardTitle>
            <CardDescription>{maker.postCount} total posts</CardDescription>
          </CardHeader>
          <CardContent>
            {maker.recentPosts.length > 0 ? (
              <div className="space-y-3">
                {maker.recentPosts.map((post) => (
                  <div key={post.id} className="rounded-lg border border-border p-3">
                    <p className="text-sm text-foreground">{post.content}</p>
                    <p className="mt-1 text-xs text-muted-foreground">
                      {timeAgo(post.createdAt)}
                    </p>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">No posts yet</p>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
