"use client";

import { useQuery, useMutation } from "convex/react";
import { api } from "@junto/backend/convex/_generated/api";
import { Id } from "@junto/backend/convex/_generated/dataModel";
import { useCurrentMaker } from "@/hooks/use-current-maker";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Avatar } from "@/components/avatar";
import { formatRelativeTime } from "@/lib/utils";
import { ArrowLeft, Send } from "lucide-react";
import { useState, use } from "react";
import Link from "next/link";

const categoryColors = {
  asking: "bg-chart-1/10 text-chart-1",
  sharing: "bg-emerald-500/10 text-emerald-600",
  looking_for: "bg-violet-500/10 text-violet-600",
};

const categoryLabels = {
  asking: "Asking",
  sharing: "Sharing",
  looking_for: "Looking for",
};

export default function PostDetailPage({
  params,
}: {
  params: Promise<{ postId: string }>;
}) {
  const { postId } = use(params);
  const { maker } = useCurrentMaker();
  const [commentText, setCommentText] = useState("");

  const post = useQuery(api.posts.get, {
    postId: postId as Id<"posts">,
  });

  const comments = useQuery(api.comments.listByPost, {
    postId: postId as Id<"posts">,
  });

  const createComment = useMutation(api.comments.create);

  async function handleComment() {
    if (!maker || !commentText.trim()) return;
    await createComment({
      postId: postId as Id<"posts">,
      authorId: maker._id,
      content: commentText.trim(),
    });
    setCommentText("");
  }

  if (post === undefined) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
      </div>
    );
  }

  if (!post) {
    return (
      <div className="py-20 text-center text-muted-foreground">
        Post not found
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <Link
        href="/feed"
        className="inline-flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground transition-colors"
      >
        <ArrowLeft className="h-4 w-4" />
        Back to feed
      </Link>

      <Card>
        <CardContent className="space-y-3">
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
                  className="font-medium text-sm hover:underline"
                >
                  {post.author?.name}
                </Link>
                <span className="text-xs text-muted-foreground">
                  {formatRelativeTime(post.createdAt)}
                </span>
              </div>
            </div>
            <span
              className={`shrink-0 rounded-full px-2.5 py-0.5 text-xs font-medium ${categoryColors[post.category]}`}
            >
              {categoryLabels[post.category]}
            </span>
          </div>
          <p className="text-sm whitespace-pre-wrap">{post.content}</p>
        </CardContent>
      </Card>

      {/* Comment input */}
      <div className="flex items-start gap-3">
        {maker && (
          <Avatar src={maker.avatarUrl} name={maker.name} size="sm" />
        )}
        <div className="flex flex-1 gap-2">
          <textarea
            value={commentText}
            onChange={(e) => setCommentText(e.target.value)}
            placeholder="Write a comment..."
            className="flex-1 resize-none rounded-md border border-input bg-transparent px-3 py-2 text-sm outline-none placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50"
            rows={1}
            onKeyDown={(e) => {
              if (e.key === "Enter" && !e.shiftKey) {
                e.preventDefault();
                handleComment();
              }
            }}
          />
          <Button
            size="icon-sm"
            onClick={handleComment}
            disabled={!commentText.trim()}
          >
            <Send className="h-3.5 w-3.5" />
          </Button>
        </div>
      </div>

      {/* Comments */}
      <div className="space-y-3">
        <h2 className="text-sm font-medium text-muted-foreground">
          {comments?.length ?? 0} comments
        </h2>
        {comments?.map((comment) => (
          <div key={comment._id} className="flex gap-3">
            <Link href={`/profile/${comment.author?._id}`} className="shrink-0">
              <Avatar
                src={comment.author?.avatarUrl}
                name={comment.author?.name || "?"}
                size="sm"
              />
            </Link>
            <div className="flex-1 rounded-lg bg-muted/50 px-3 py-2">
              <div className="flex items-center gap-2">
                <Link
                  href={`/profile/${comment.author?._id}`}
                  className="text-sm font-medium hover:underline"
                >
                  {comment.author?.name}
                </Link>
                <span className="text-xs text-muted-foreground">
                  {formatRelativeTime(comment.createdAt)}
                </span>
              </div>
              <p className="mt-0.5 text-sm">{comment.content}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
