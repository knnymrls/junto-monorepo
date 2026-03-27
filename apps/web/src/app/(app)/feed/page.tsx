"use client";

import { useQuery, useMutation } from "convex/react";
import { api } from "@junto/backend/convex/_generated/api";
import { Id } from "@junto/backend/convex/_generated/dataModel";
import { useCurrentMaker } from "@/hooks/use-current-maker";
import { Card, CardContent, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Avatar } from "@/components/avatar";
import { formatRelativeTime } from "@/lib/utils";
import { MessageCircle, Send } from "lucide-react";
import { useState } from "react";
import Link from "next/link";

const categoryLabels = {
  asking: "Asking",
  sharing: "Sharing",
  looking_for: "Looking for",
};

const categoryColors = {
  asking: "bg-chart-1/10 text-chart-1",
  sharing: "bg-emerald-500/10 text-emerald-600",
  looking_for: "bg-violet-500/10 text-violet-600",
};

export default function FeedPage() {
  const { maker } = useCurrentMaker();
  const [composerOpen, setComposerOpen] = useState(false);
  const [content, setContent] = useState("");
  const [category, setCategory] = useState<
    "asking" | "sharing" | "looking_for"
  >("sharing");

  const feed = useQuery(
    api.posts.getFeed,
    maker ? { makerId: maker._id } : "skip"
  );

  const createPost = useMutation(api.posts.create);

  async function handlePost() {
    if (!maker || !content.trim()) return;
    await createPost({
      authorId: maker._id,
      content: content.trim(),
      category,
    });
    setContent("");
    setComposerOpen(false);
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold tracking-tight">Feed</h1>

      {/* Composer */}
      <Card size="sm">
        <CardContent>
          {composerOpen ? (
            <div className="space-y-3">
              <div className="flex gap-2">
                {(["sharing", "asking", "looking_for"] as const).map((cat) => (
                  <button
                    key={cat}
                    onClick={() => setCategory(cat)}
                    className={`rounded-full px-3 py-1 text-xs font-medium transition-colors ${
                      category === cat
                        ? categoryColors[cat]
                        : "bg-muted text-muted-foreground hover:bg-muted/80"
                    }`}
                  >
                    {categoryLabels[cat]}
                  </button>
                ))}
              </div>
              <textarea
                value={content}
                onChange={(e) => setContent(e.target.value)}
                placeholder="What's on your mind?"
                className="w-full resize-none rounded-md border border-input bg-transparent px-3 py-2 text-sm outline-none placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50"
                rows={3}
                autoFocus
              />
              <div className="flex justify-end gap-2">
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => {
                    setComposerOpen(false);
                    setContent("");
                  }}
                >
                  Cancel
                </Button>
                <Button
                  size="sm"
                  onClick={handlePost}
                  disabled={!content.trim()}
                >
                  <Send className="h-3.5 w-3.5" />
                  Post
                </Button>
              </div>
            </div>
          ) : (
            <button
              onClick={() => setComposerOpen(true)}
              className="w-full rounded-md border border-input px-3 py-2 text-left text-sm text-muted-foreground hover:bg-muted/50 transition-colors"
            >
              Share something with the community...
            </button>
          )}
        </CardContent>
      </Card>

      {/* Feed */}
      {feed === undefined ? (
        <div className="space-y-4">
          {[1, 2, 3].map((i) => (
            <Card key={i} size="sm">
              <CardContent>
                <div className="animate-pulse space-y-3">
                  <div className="flex items-center gap-3">
                    <div className="h-10 w-10 rounded-full bg-muted" />
                    <div className="space-y-1.5">
                      <div className="h-4 w-24 rounded bg-muted" />
                      <div className="h-3 w-16 rounded bg-muted" />
                    </div>
                  </div>
                  <div className="h-4 w-full rounded bg-muted" />
                  <div className="h-4 w-3/4 rounded bg-muted" />
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : feed.length === 0 ? (
        <Card size="sm">
          <CardContent className="py-12 text-center">
            <p className="text-muted-foreground">
              No posts yet. Be the first to share something!
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-4">
          {feed.map((post) => (
            <PostCard key={post._id} post={post} />
          ))}
        </div>
      )}
    </div>
  );
}

function PostCard({
  post,
}: {
  post: {
    _id: Id<"posts">;
    content: string;
    category: "asking" | "sharing" | "looking_for";
    imageUrl?: string;
    imageUrls?: string[];
    gifUrl?: string;
    createdAt: number;
    author: {
      _id: Id<"makers">;
      name: string;
      headline?: string;
      avatarUrl?: string;
    } | null;
    commentCount: number;
    recentCommenters?: { _id: string; name: string; avatarUrl?: string }[];
  };
}) {
  return (
    <Card size="sm">
      <CardContent className="space-y-3">
        {/* Author row */}
        <div className="flex items-center gap-3">
          <Link href={`/profile/${post.author?._id}`} className="shrink-0">
            <Avatar
              src={post.author?.avatarUrl}
              name={post.author?.name || "?"}
              size="md"
            />
          </Link>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2">
              <Link
                href={`/profile/${post.author?._id}`}
                className="font-medium text-sm hover:underline truncate"
              >
                {post.author?.name}
              </Link>
              <span className="text-xs text-muted-foreground">
                {formatRelativeTime(post.createdAt)}
              </span>
            </div>
            {post.author?.headline && (
              <p className="text-xs text-muted-foreground truncate">
                {post.author.headline}
              </p>
            )}
          </div>
          <span
            className={`shrink-0 rounded-full px-2.5 py-0.5 text-xs font-medium ${categoryColors[post.category]}`}
          >
            {categoryLabels[post.category]}
          </span>
        </div>

        {/* Content */}
        <p className="text-sm whitespace-pre-wrap">{post.content}</p>

        {post.imageUrl && (
          <img
            src={post.imageUrl}
            alt=""
            className="rounded-lg max-h-80 w-full object-cover"
          />
        )}

        {post.imageUrls && post.imageUrls.length > 0 && (
          <div className="grid grid-cols-2 gap-2">
            {post.imageUrls.map((url, i) => (
              <img
                key={i}
                src={url}
                alt=""
                className="rounded-lg max-h-40 w-full object-cover"
              />
            ))}
          </div>
        )}

        {post.gifUrl && (
          <img
            src={post.gifUrl}
            alt="GIF"
            className="rounded-lg max-h-60"
          />
        )}
      </CardContent>

      <CardFooter className="gap-4">
        <Link
          href={`/feed/${post._id}`}
          className="flex items-center gap-1.5 text-xs text-muted-foreground hover:text-foreground transition-colors"
        >
          <MessageCircle className="h-3.5 w-3.5" />
          {post.commentCount > 0 ? post.commentCount : "Comment"}
        </Link>

        {post.recentCommenters && post.recentCommenters.length > 0 && (
          <div className="flex -space-x-1.5">
            {post.recentCommenters.map((commenter) => (
              <Avatar
                key={commenter._id}
                src={commenter.avatarUrl}
                name={commenter.name}
                size="xs"
              />
            ))}
          </div>
        )}
      </CardFooter>
    </Card>
  );
}
