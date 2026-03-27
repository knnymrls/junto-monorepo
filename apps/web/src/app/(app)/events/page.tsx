"use client";

import { useQuery, useMutation } from "convex/react";
import { api } from "@junto/backend/convex/_generated/api";
import { useCurrentMaker } from "@/hooks/use-current-maker";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
  CardAction,
  CardFooter,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar } from "@/components/avatar";
import { formatEventDate } from "@/lib/utils";
import { MapPin, Calendar, Users, Check } from "lucide-react";

export default function EventsPage() {
  const { maker } = useCurrentMaker();
  const events = useQuery(api.events.listUpcoming, {});

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Events</h1>
        <p className="text-sm text-muted-foreground">
          Upcoming campus events
        </p>
      </div>

      {events === undefined ? (
        <div className="space-y-4">
          {[1, 2, 3].map((i) => (
            <Card key={i}>
              <CardContent>
                <div className="animate-pulse space-y-3">
                  <div className="h-5 w-48 rounded bg-muted" />
                  <div className="h-4 w-full rounded bg-muted" />
                  <div className="h-4 w-2/3 rounded bg-muted" />
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : events.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <p className="text-muted-foreground">No upcoming events</p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-4">
          {events.map((event) => (
            <EventCard
              key={event._id}
              event={event}
              currentMakerId={maker?._id}
            />
          ))}
        </div>
      )}
    </div>
  );
}

function EventCard({
  event,
  currentMakerId,
}: {
  event: {
    _id: string;
    title: string;
    description?: string;
    date: number;
    location?: string;
    type: string;
    imageUrl?: string;
    host: { id: string; name: string; avatarUrl?: string } | null;
    goingCount: number;
    attendeePreviews: ({ id: string; name: string; avatarUrl?: string } | null)[];
  };
  currentMakerId?: string;
}) {
  const rsvpMutation = useMutation(api.events.rsvp);

  const userRsvp = useQuery(
    api.events.getUserRsvp,
    currentMakerId
      ? { eventId: event._id as any, makerId: currentMakerId as any }
      : "skip"
  );

  const isGoing = userRsvp?.status === "going";
  const isInterested = userRsvp?.status === "interested";

  async function handleRsvp(status: string) {
    if (!currentMakerId) return;
    await rsvpMutation({
      eventId: event._id as any,
      makerId: currentMakerId as any,
      status,
    });
  }

  return (
    <Card>
      {event.imageUrl && (
        <img
          src={event.imageUrl}
          alt={event.title}
          className="h-48 w-full object-cover"
        />
      )}
      <CardHeader>
        <CardTitle className="text-lg">{event.title}</CardTitle>
        <CardDescription className="flex flex-wrap items-center gap-x-4 gap-y-1">
          <span className="inline-flex items-center gap-1">
            <Calendar className="h-3.5 w-3.5" />
            {formatEventDate(event.date)}
          </span>
          {event.location && (
            <span className="inline-flex items-center gap-1">
              <MapPin className="h-3.5 w-3.5" />
              {event.location}
            </span>
          )}
        </CardDescription>
        <CardAction>
          <Badge variant="outline" className="capitalize">
            {event.type.replace("_", " ")}
          </Badge>
        </CardAction>
      </CardHeader>

      {event.description && (
        <CardContent>
          <p className="text-sm text-muted-foreground line-clamp-3">
            {event.description}
          </p>
        </CardContent>
      )}

      <CardFooter className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          {event.attendeePreviews.filter(Boolean).length > 0 && (
            <div className="flex -space-x-2">
              {event.attendeePreviews.filter(Boolean).map((a) => (
                <Avatar key={a!.id} src={a!.avatarUrl} name={a!.name} size="xs" />
              ))}
            </div>
          )}
          <span className="text-xs text-muted-foreground">
            <Users className="mr-1 inline h-3 w-3" />
            {event.goingCount} going
          </span>
        </div>

        <div className="flex gap-2">
          <Button
            variant={isInterested ? "secondary" : "outline"}
            size="sm"
            onClick={() =>
              handleRsvp(isInterested ? "not_going" : "interested")
            }
          >
            Interested
          </Button>
          <Button
            variant={isGoing ? "default" : "outline"}
            size="sm"
            onClick={() => handleRsvp(isGoing ? "not_going" : "going")}
          >
            {isGoing && <Check className="h-3.5 w-3.5" />}
            Going
          </Button>
        </div>
      </CardFooter>
    </Card>
  );
}
