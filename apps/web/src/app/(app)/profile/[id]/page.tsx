"use client";

import { useQuery, useMutation } from "convex/react";
import { api } from "@junto/backend/convex/_generated/api";
import { Id } from "@junto/backend/convex/_generated/dataModel";
import { useCurrentMaker } from "@/hooks/use-current-maker";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { Avatar } from "@/components/avatar";
import { formatRelativeTime } from "@/lib/utils";
import {
  ArrowLeft,
  UserPlus,
  UserCheck,
  MessageCircle,
  LinkIcon,
  Github,
  Briefcase,
  Clock,
  ExternalLink,
} from "lucide-react";
import { use } from "react";
import Link from "next/link";

export default function ProfilePage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = use(params);
  const { maker: currentMaker } = useCurrentMaker();
  const makerId = id as Id<"makers">;

  const maker = useQuery(api.users.get, { id: makerId });
  const portfolio = useQuery(api.portfolio.list, { makerId });
  const posts = useQuery(api.posts.getByAuthor, { authorId: makerId, limit: 5 });
  const connections = useQuery(api.connections.listForMaker, { makerId });

  const connectionStatus = useQuery(
    api.connections.getConnectionStatus,
    currentMaker && currentMaker._id !== makerId
      ? { fromMakerId: currentMaker._id, toMakerId: makerId }
      : "skip"
  );

  const sendRequest = useMutation(api.connections.sendRequest);
  const sendMessage = useMutation(api.messages.sendMessage);

  const isOwnProfile = currentMaker?._id === makerId;

  if (maker === undefined) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
      </div>
    );
  }

  if (!maker) {
    return (
      <div className="py-20 text-center text-muted-foreground">
        Maker not found
      </div>
    );
  }

  async function handleConnect() {
    if (!currentMaker) return;
    await sendRequest({
      requesterId: currentMaker._id,
      accepterId: makerId,
    });
  }

  return (
    <div className="space-y-6">
      <Link
        href="/discover"
        className="inline-flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground transition-colors"
      >
        <ArrowLeft className="h-4 w-4" />
        Back
      </Link>

      {/* Profile header */}
      <Card>
        <CardContent className="flex flex-col items-center gap-4 sm:flex-row sm:items-start">
          <Avatar src={maker.avatarUrl} name={maker.name} size="xl" />
          <div className="flex-1 text-center sm:text-left">
            <h1 className="text-xl font-bold tracking-tight">{maker.name}</h1>
            {maker.headline && (
              <p className="mt-0.5 text-sm text-muted-foreground">
                {maker.headline}
              </p>
            )}
            {maker.location && (
              <p className="mt-0.5 text-xs text-muted-foreground">
                {maker.location}
              </p>
            )}

            {/* Connection count */}
            {connections && (
              <p className="mt-2 text-xs text-muted-foreground">
                {connections.length} connection
                {connections.length !== 1 ? "s" : ""}
              </p>
            )}

            {/* Actions */}
            {!isOwnProfile && currentMaker && (
              <div className="mt-3 flex justify-center gap-2 sm:justify-start">
                {connectionStatus === "connected" ? (
                  <Button variant="secondary" size="sm" disabled>
                    <UserCheck className="h-3.5 w-3.5" />
                    Connected
                  </Button>
                ) : connectionStatus === "pending_sent" ? (
                  <Button variant="secondary" size="sm" disabled>
                    <Clock className="h-3.5 w-3.5" />
                    Pending
                  </Button>
                ) : (
                  <Button size="sm" onClick={handleConnect}>
                    <UserPlus className="h-3.5 w-3.5" />
                    Connect
                  </Button>
                )}
                <Link href="/messages">
                  <Button variant="outline" size="sm">
                    <MessageCircle className="h-3.5 w-3.5" />
                    Message
                  </Button>
                </Link>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Bio & details */}
      {(maker.bio || maker.currentProject || maker.lookingFor || maker.canHelpWith) && (
        <Card size="sm">
          <CardContent className="space-y-4">
            {maker.bio && (
              <div>
                <h3 className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                  About
                </h3>
                <p className="mt-1 text-sm whitespace-pre-wrap">{maker.bio}</p>
              </div>
            )}
            {maker.currentProject && (
              <div>
                <h3 className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                  Currently building
                </h3>
                <p className="mt-1 text-sm">{maker.currentProject}</p>
              </div>
            )}
            {maker.lookingFor && (
              <div>
                <h3 className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                  Looking for
                </h3>
                <p className="mt-1 text-sm text-chart-2">{maker.lookingFor}</p>
              </div>
            )}
            {maker.canHelpWith && (
              <div>
                <h3 className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                  Can help with
                </h3>
                <p className="mt-1 text-sm text-emerald-600">
                  {maker.canHelpWith}
                </p>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* Skills & Interests */}
      {((maker.skills && maker.skills.length > 0) ||
        (maker.interests && maker.interests.length > 0)) && (
        <Card size="sm">
          <CardContent className="space-y-3">
            {maker.skills && maker.skills.length > 0 && (
              <div>
                <h3 className="text-xs font-medium text-muted-foreground uppercase tracking-wider mb-2">
                  Skills
                </h3>
                <div className="flex flex-wrap gap-1.5">
                  {maker.skills.map((skill) => (
                    <Badge key={skill} variant="secondary">
                      {skill}
                    </Badge>
                  ))}
                </div>
              </div>
            )}
            {maker.interests && maker.interests.length > 0 && (
              <div>
                <h3 className="text-xs font-medium text-muted-foreground uppercase tracking-wider mb-2">
                  Interests
                </h3>
                <div className="flex flex-wrap gap-1.5">
                  {maker.interests.map((interest) => (
                    <Badge key={interest} variant="outline">
                      {interest}
                    </Badge>
                  ))}
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* Social Links */}
      {maker.socialLinks &&
        Object.values(maker.socialLinks).some(Boolean) && (
          <Card size="sm">
            <CardContent>
              <h3 className="text-xs font-medium text-muted-foreground uppercase tracking-wider mb-2">
                Links
              </h3>
              <div className="flex flex-wrap gap-2">
                {maker.socialLinks.github && (
                  <a
                    href={maker.socialLinks.github}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-1.5 rounded-md bg-muted px-3 py-1.5 text-xs font-medium hover:bg-muted/80 transition-colors"
                  >
                    <Github className="h-3.5 w-3.5" />
                    GitHub
                  </a>
                )}
                {maker.socialLinks.linkedin && (
                  <a
                    href={maker.socialLinks.linkedin}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-1.5 rounded-md bg-muted px-3 py-1.5 text-xs font-medium hover:bg-muted/80 transition-colors"
                  >
                    <LinkIcon className="h-3.5 w-3.5" />
                    LinkedIn
                  </a>
                )}
                {maker.socialLinks.twitter && (
                  <a
                    href={maker.socialLinks.twitter}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-1.5 rounded-md bg-muted px-3 py-1.5 text-xs font-medium hover:bg-muted/80 transition-colors"
                  >
                    <ExternalLink className="h-3.5 w-3.5" />
                    X / Twitter
                  </a>
                )}
                {maker.socialLinks.website && (
                  <a
                    href={maker.socialLinks.website}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-1.5 rounded-md bg-muted px-3 py-1.5 text-xs font-medium hover:bg-muted/80 transition-colors"
                  >
                    <ExternalLink className="h-3.5 w-3.5" />
                    Website
                  </a>
                )}
              </div>
            </CardContent>
          </Card>
        )}

      {/* Portfolio */}
      {portfolio && portfolio.length > 0 && (
        <div className="space-y-3">
          <h2 className="text-sm font-medium">Portfolio</h2>
          <div className="grid gap-3 sm:grid-cols-2">
            {portfolio.map((item) => (
              <Card key={item._id} size="sm">
                <CardContent>
                  <div className="flex items-start gap-3">
                    <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-md bg-muted">
                      {item.type === "github" ? (
                        <Github className="h-4 w-4 text-muted-foreground" />
                      ) : item.type === "experience" ? (
                        <Briefcase className="h-4 w-4 text-muted-foreground" />
                      ) : (
                        <LinkIcon className="h-4 w-4 text-muted-foreground" />
                      )}
                    </div>
                    <div className="min-w-0">
                      {item.url ? (
                        <a
                          href={item.url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-sm font-medium hover:underline truncate block"
                        >
                          {item.title || "Untitled"}
                        </a>
                      ) : (
                        <p className="text-sm font-medium truncate">
                          {item.title || "Untitled"}
                        </p>
                      )}
                      {item.description && (
                        <p className="text-xs text-muted-foreground line-clamp-2">
                          {item.description}
                        </p>
                      )}
                      {item.organization && (
                        <p className="text-xs text-muted-foreground">
                          {item.organization}
                        </p>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      )}

      {/* Recent Posts */}
      {posts && posts.length > 0 && (
        <div className="space-y-3">
          <h2 className="text-sm font-medium">Recent Posts</h2>
          {posts.map((post) => (
            <Link key={post._id} href={`/feed/${post._id}`}>
              <Card
                size="sm"
                className="hover:ring-foreground/20 transition-all cursor-pointer"
              >
                <CardContent>
                  <p className="text-sm line-clamp-3">{post.content}</p>
                  <p className="mt-1.5 text-xs text-muted-foreground">
                    {formatRelativeTime(post.createdAt)}
                    {post.commentCount > 0 &&
                      ` · ${post.commentCount} comment${post.commentCount !== 1 ? "s" : ""}`}
                  </p>
                </CardContent>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
