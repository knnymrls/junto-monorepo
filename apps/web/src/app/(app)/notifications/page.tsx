"use client";

import { useQuery, useMutation } from "convex/react";
import { api } from "@junto/backend/convex/_generated/api";
import { useCurrentMaker } from "@/hooks/use-current-maker";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Avatar } from "@/components/avatar";
import { formatRelativeTime, cn } from "@/lib/utils";
import { CheckCheck, MessageCircle, UserPlus, AtSign, Calendar } from "lucide-react";
import Link from "next/link";

const typeIcons: Record<string, typeof MessageCircle> = {
  comment: MessageCircle,
  mention: AtSign,
  connection_request: UserPlus,
  connection_accepted: UserPlus,
  new_message: MessageCircle,
  message_request: MessageCircle,
  event_rsvp: Calendar,
};

export default function NotificationsPage() {
  const { maker } = useCurrentMaker();

  const notifications = useQuery(
    api.notifications.listForMaker,
    maker ? { makerId: maker._id } : "skip"
  );

  const markAllRead = useMutation(api.notifications.markAllAsRead);
  const markRead = useMutation(api.notifications.markAsRead);

  const unreadCount = notifications?.filter((n) => !n.readAt).length ?? 0;

  function getNotificationLink(notification: {
    type: string;
    data?: {
      postId?: string;
      conversationId?: string;
      senderId?: string;
    } | null;
  }): string {
    if (notification.data?.postId) return `/feed/${notification.data.postId}`;
    if (notification.data?.conversationId) return "/messages";
    if (notification.data?.senderId)
      return `/profile/${notification.data.senderId}`;
    return "#";
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Notifications</h1>
          {unreadCount > 0 && (
            <p className="text-sm text-muted-foreground">
              {unreadCount} unread
            </p>
          )}
        </div>
        {unreadCount > 0 && maker && (
          <Button
            variant="ghost"
            size="sm"
            onClick={() => markAllRead({ makerId: maker._id })}
          >
            <CheckCheck className="h-3.5 w-3.5" />
            Mark all read
          </Button>
        )}
      </div>

      {notifications === undefined ? (
        <div className="space-y-2">
          {[1, 2, 3, 4].map((i) => (
            <Card key={i} size="sm">
              <CardContent>
                <div className="animate-pulse flex items-center gap-3">
                  <div className="h-10 w-10 rounded-full bg-muted" />
                  <div className="flex-1 space-y-1.5">
                    <div className="h-4 w-48 rounded bg-muted" />
                    <div className="h-3 w-20 rounded bg-muted" />
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : notifications.length === 0 ? (
        <Card size="sm">
          <CardContent className="py-12 text-center">
            <p className="text-muted-foreground text-sm">
              No notifications yet
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-2">
          {notifications.map((notification) => {
            const Icon = typeIcons[notification.type] || MessageCircle;
            const link = getNotificationLink(notification);

            return (
              <Link
                key={notification._id}
                href={link}
                onClick={() => {
                  if (!notification.readAt) {
                    markRead({ notificationId: notification._id });
                  }
                }}
              >
                <Card
                  size="sm"
                  className={cn(
                    "hover:ring-foreground/20 transition-all cursor-pointer",
                    !notification.readAt && "ring-chart-2/20 bg-chart-2/5"
                  )}
                >
                  <CardContent className="flex items-start gap-3">
                    {notification.sender ? (
                      <Avatar
                        src={notification.sender.avatarUrl}
                        name={notification.sender.name}
                        size="md"
                      />
                    ) : (
                      <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-muted">
                        <Icon className="h-4 w-4 text-muted-foreground" />
                      </div>
                    )}
                    <div className="flex-1 min-w-0">
                      <p className="text-sm">{notification.title}</p>
                      {notification.body && (
                        <p className="mt-0.5 text-xs text-muted-foreground truncate">
                          {notification.body}
                        </p>
                      )}
                      <p className="mt-1 text-xs text-muted-foreground">
                        {formatRelativeTime(notification.createdAt)}
                      </p>
                    </div>
                    {!notification.readAt && (
                      <div className="mt-1 h-2 w-2 shrink-0 rounded-full bg-chart-2" />
                    )}
                  </CardContent>
                </Card>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}
