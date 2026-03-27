"use client";

import { useState, useCallback } from "react";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useConvexQuery } from "@/hooks/use-convex-query";
import { mutateDashboard, uploadToConvex } from "@/lib/convex";

type Attendee = {
  id: string;
  name: string;
  avatarUrl: string | null;
  headline: string | null;
  rsvpStatus: string;
  rsvpDate: number;
};

type EventData = {
  id: string;
  title: string;
  description: string | null;
  date: number;
  endDate: number | null;
  location: string | null;
  type: string;
  imageUrl: string | null;
  createdBy: { id: string; name: string; avatarUrl: string | null };
  rsvpCount: number;
  interestedCount: number;
  feedbackCount: number;
  averageRating: number | null;
  postEventConnections: number;
  attendees: Attendee[];
  interestedAttendees: Attendee[];
  topImprovements: { label: string; count: number }[];
  ratingBreakdown: number[];
};

type FormData = {
  title: string;
  description: string;
  date: string;
  endDate: string;
  location: string;
  type: string;
  imageUrl: string;
};

const EMPTY_FORM: FormData = {
  title: "",
  description: "",
  date: "",
  endDate: "",
  location: "",
  type: "in_person",
  imageUrl: "",
};

function toLocalDatetime(ts: number): string {
  const d = new Date(ts);
  const offset = d.getTimezoneOffset();
  const local = new Date(d.getTime() - offset * 60000);
  return local.toISOString().slice(0, 16);
}

function getInitials(name: string) {
  return name
    .split(" ")
    .map((n) => n[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();
}

function Avatar({
  url,
  name,
  size = "sm",
}: {
  url: string | null;
  name: string;
  size?: "sm" | "md";
}) {
  const dims = size === "md" ? "h-9 w-9" : "h-7 w-7";
  const textSize = size === "md" ? "text-xs" : "text-[10px]";
  if (url) {
    return (
      <img
        src={url}
        alt={name}
        className={`${dims} rounded-full object-cover`}
      />
    );
  }
  return (
    <div
      className={`flex ${dims} items-center justify-center rounded-full bg-primary/10 ${textSize} font-semibold text-primary`}
    >
      {getInitials(name)}
    </div>
  );
}

const TYPE_LABELS: Record<string, string> = {
  in_person: "In Person",
  online: "Online",
  hybrid: "Hybrid",
};

const TYPE_COLORS: Record<string, string> = {
  in_person: "bg-emerald-500/10 text-emerald-600",
  online: "bg-blue-500/10 text-blue-600",
  hybrid: "bg-violet-500/10 text-violet-600",
};

export default function EventsPage() {
  const { data, loading, refetch } =
    useConvexQuery<EventData[]>("dashboard:eventPerformance");
  const [showDialog, setShowDialog] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<FormData>(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [selectedEvent, setSelectedEvent] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<"details" | "attendees" | "analytics">("details");
  const [uploading, setUploading] = useState(false);
  const [imagePreview, setImagePreview] = useState<string | null>(null);

  const handleImageUpload = useCallback(
    async (file: File) => {
      if (!file.type.startsWith("image/")) return;
      // Show local preview immediately
      const localUrl = URL.createObjectURL(file);
      setImagePreview(localUrl);
      setUploading(true);
      try {
        const url = await uploadToConvex(file);
        setForm((f) => ({ ...f, imageUrl: url }));
      } catch {
        // If upload fails, clear preview
        setImagePreview(null);
      } finally {
        setUploading(false);
      }
    },
    []
  );

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <p className="text-sm text-muted-foreground">Loading...</p>
      </div>
    );
  }

  const events = data ?? [];
  const now = Date.now();
  const pastEvents = events.filter((e) => e.date <= now);
  const upcomingEvents = events.filter((e) => e.date > now);
  const totalRsvps = events.reduce((s, e) => s + e.rsvpCount, 0);
  const totalPostEventConnections = events.reduce(
    (s, e) => s + e.postEventConnections,
    0
  );

  const selected = selectedEvent
    ? events.find((e) => e.id === selectedEvent) ?? null
    : null;

  function openCreate() {
    setEditingId(null);
    setForm(EMPTY_FORM);
    setImagePreview(null);
    setShowDialog(true);
  }

  function openEdit(event: EventData) {
    setEditingId(event.id);
    setForm({
      title: event.title,
      description: event.description ?? "",
      date: toLocalDatetime(event.date),
      endDate: event.endDate ? toLocalDatetime(event.endDate) : "",
      location: event.location ?? "",
      type: event.type,
      imageUrl: event.imageUrl ?? "",
    });
    setImagePreview(event.imageUrl);
    setShowDialog(true);
  }

  async function handleSave() {
    if (!form.title || !form.date) return;
    setSaving(true);
    try {
      const dateTs = new Date(form.date).getTime();
      const endDateTs = form.endDate
        ? new Date(form.endDate).getTime()
        : undefined;

      if (editingId) {
        await mutateDashboard("dashboard:updateEvent", {
          id: editingId,
          title: form.title,
          description: form.description || undefined,
          date: dateTs,
          endDate: endDateTs,
          location: form.location || undefined,
          type: form.type,
          imageUrl: form.imageUrl || undefined,
        });
      } else {
        await mutateDashboard("dashboard:createEvent", {
          title: form.title,
          description: form.description || undefined,
          date: dateTs,
          endDate: endDateTs,
          location: form.location || undefined,
          type: form.type,
          imageUrl: form.imageUrl || undefined,
        });
      }
      setShowDialog(false);
      refetch();
    } catch {
      // silently handle for demo
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">Events</h2>
          <p className="mt-1 text-sm text-muted-foreground">
            Create events, track RSVPs, and measure post-event outcomes
          </p>
        </div>
        <Button onClick={openCreate}>Create Event</Button>
      </div>

      {/* Stats */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardContent className="pt-5 pb-4">
            <p className="text-xs text-muted-foreground">Total Events</p>
            <p className="mt-1 text-3xl font-bold tabular-nums">
              {events.length}
            </p>
            <p className="mt-0.5 text-xs text-muted-foreground">
              {upcomingEvents.length} upcoming &middot; {pastEvents.length} past
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-5 pb-4">
            <p className="text-xs text-muted-foreground">Total RSVPs</p>
            <p className="mt-1 text-3xl font-bold tabular-nums">{totalRsvps}</p>
            <p className="mt-0.5 text-xs text-muted-foreground">
              {events.length > 0
                ? `${Math.round(totalRsvps / events.length)} avg per event`
                : "---"}
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-5 pb-4">
            <p className="text-xs text-muted-foreground">
              Post-Event Connections
            </p>
            <p className="mt-1 text-3xl font-bold tabular-nums">
              {totalPostEventConnections}
            </p>
            <p className="mt-0.5 text-xs text-muted-foreground">
              Within 48h of event end
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-5 pb-4">
            <p className="text-xs text-muted-foreground">Avg Rating</p>
            <p className="mt-1 text-3xl font-bold tabular-nums">
              {(() => {
                const rated = pastEvents.filter(
                  (e) => e.averageRating !== null
                );
                if (rated.length === 0) return "---";
                const avg =
                  rated.reduce((s, e) => s + e.averageRating!, 0) /
                  rated.length;
                return `${Math.round(avg * 10) / 10}/5`;
              })()}
            </p>
            <p className="mt-0.5 text-xs text-muted-foreground">
              From {events.reduce((s, e) => s + e.feedbackCount, 0)} feedback
              submissions
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Main content: list + detail panel */}
      <div className="grid gap-6 lg:grid-cols-5">
        {/* Event list */}
        <div className="lg:col-span-2 space-y-4">
          {upcomingEvents.length > 0 && (
            <div className="space-y-2">
              <h3 className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                Upcoming
              </h3>
              {upcomingEvents.map((event) => (
                <EventListItem
                  key={event.id}
                  event={event}
                  isSelected={selectedEvent === event.id}
                  onSelect={() => {
                    setSelectedEvent(event.id);
                    setActiveTab("details");
                  }}
                />
              ))}
            </div>
          )}

          {pastEvents.length > 0 && (
            <div className="space-y-2">
              <h3 className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                Past
              </h3>
              {pastEvents.map((event) => (
                <EventListItem
                  key={event.id}
                  event={event}
                  isSelected={selectedEvent === event.id}
                  onSelect={() => {
                    setSelectedEvent(event.id);
                    setActiveTab("details");
                  }}
                />
              ))}
            </div>
          )}

          {events.length === 0 && (
            <Card>
              <CardContent className="py-12 text-center">
                <p className="text-sm text-muted-foreground">
                  No events yet — create your first one
                </p>
              </CardContent>
            </Card>
          )}
        </div>

        {/* Detail panel */}
        <div className="lg:col-span-3">
          {selected ? (
            <Card className="overflow-hidden">
              {/* Event header image */}
              {selected.imageUrl ? (
                <div className="relative h-48 bg-muted">
                  <img
                    src={selected.imageUrl}
                    alt={selected.title}
                    className="h-full w-full object-cover"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
                  <div className="absolute bottom-4 left-4 right-4">
                    <h3 className="text-lg font-bold text-white">
                      {selected.title}
                    </h3>
                    <p className="text-sm text-white/80">
                      {formatEventDate(selected.date, selected.endDate)}
                    </p>
                  </div>
                </div>
              ) : (
                <div className="relative h-32 bg-gradient-to-br from-primary/10 via-primary/5 to-background">
                  <div className="absolute bottom-4 left-4 right-4">
                    <h3 className="text-lg font-bold">{selected.title}</h3>
                    <p className="text-sm text-muted-foreground">
                      {formatEventDate(selected.date, selected.endDate)}
                    </p>
                  </div>
                </div>
              )}

              {/* Quick stat bar */}
              <div className="flex items-center gap-1 border-b border-border px-4 py-2">
                <div className="flex items-center gap-4 flex-1">
                  <Badge
                    variant="secondary"
                    className={`text-xs ${TYPE_COLORS[selected.type] ?? ""}`}
                  >
                    {TYPE_LABELS[selected.type] ?? selected.type}
                  </Badge>
                  {selected.location && (
                    <span className="text-xs text-muted-foreground truncate">
                      {selected.location}
                    </span>
                  )}
                </div>
                <Button
                  variant="ghost"
                  size="sm"
                  className="text-xs h-7 px-2"
                  onClick={() => openEdit(selected)}
                >
                  Edit
                </Button>
              </div>

              {/* Tab bar */}
              <div className="flex border-b border-border">
                {(
                  [
                    { key: "details", label: "Details" },
                    { key: "attendees", label: `Attendees (${selected.rsvpCount})` },
                    { key: "analytics", label: "Analytics" },
                  ] as const
                ).map((tab) => (
                  <button
                    key={tab.key}
                    onClick={() => setActiveTab(tab.key)}
                    className={`px-4 py-2.5 text-sm font-medium border-b-2 transition-colors ${
                      activeTab === tab.key
                        ? "border-primary text-foreground"
                        : "border-transparent text-muted-foreground hover:text-foreground"
                    }`}
                  >
                    {tab.label}
                  </button>
                ))}
              </div>

              {/* Tab content */}
              <CardContent className="pt-4 pb-5">
                {activeTab === "details" && (
                  <DetailsTab event={selected} />
                )}
                {activeTab === "attendees" && (
                  <AttendeesTab event={selected} />
                )}
                {activeTab === "analytics" && (
                  <AnalyticsTab event={selected} />
                )}
              </CardContent>
            </Card>
          ) : (
            <Card>
              <CardContent className="py-20 text-center">
                <p className="text-sm text-muted-foreground">
                  Select an event to view details, attendees, and analytics
                </p>
              </CardContent>
            </Card>
          )}
        </div>
      </div>

      {/* Create/Edit Dialog */}
      {showDialog && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div
            className="absolute inset-0 bg-black/50"
            onClick={() => setShowDialog(false)}
          />
          <div className="relative z-10 w-full max-w-lg rounded-xl bg-background border border-border shadow-lg p-6">
            <h3 className="text-lg font-semibold mb-4">
              {editingId ? "Edit Event" : "Create Event"}
            </h3>
            <div className="space-y-4">
              <div>
                <label className="text-sm font-medium mb-1 block">Title</label>
                <Input
                  value={form.title}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, title: e.target.value }))
                  }
                  placeholder="Speed Networking Night"
                />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">
                  Description
                </label>
                <textarea
                  value={form.description}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, description: e.target.value }))
                  }
                  placeholder="What's this event about?"
                  className="flex w-full rounded-md border border-input bg-background px-3 py-2 text-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring min-h-[80px] resize-none"
                />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">
                  Cover Image
                </label>
                {imagePreview || form.imageUrl ? (
                  <div className="relative group">
                    <div className="h-32 rounded-lg overflow-hidden bg-muted">
                      <img
                        src={imagePreview || form.imageUrl}
                        alt="Cover preview"
                        className="h-full w-full object-cover"
                      />
                      {uploading && (
                        <div className="absolute inset-0 bg-black/40 flex items-center justify-center">
                          <p className="text-sm text-white font-medium">
                            Uploading...
                          </p>
                        </div>
                      )}
                    </div>
                    <button
                      type="button"
                      onClick={() => {
                        setForm((f) => ({ ...f, imageUrl: "" }));
                        setImagePreview(null);
                      }}
                      className="absolute top-2 right-2 h-6 w-6 rounded-full bg-black/60 text-white text-xs flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
                    >
                      x
                    </button>
                  </div>
                ) : (
                  <label
                    onDragOver={(e) => {
                      e.preventDefault();
                      e.stopPropagation();
                    }}
                    onDrop={(e) => {
                      e.preventDefault();
                      e.stopPropagation();
                      const file = e.dataTransfer.files?.[0];
                      if (file) handleImageUpload(file);
                    }}
                    className="flex flex-col items-center justify-center h-32 rounded-lg border-2 border-dashed border-border hover:border-primary/40 hover:bg-muted/50 transition-colors cursor-pointer"
                  >
                    <input
                      type="file"
                      accept="image/*"
                      className="absolute w-0 h-0 overflow-hidden opacity-0 pointer-events-none"
                      onChange={(e) => {
                        const file = e.target.files?.[0];
                        if (file) handleImageUpload(file);
                      }}
                    />
                    <svg
                      className="h-8 w-8 text-muted-foreground/50 mb-2"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                      strokeWidth={1.5}
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909M3.75 21h16.5A2.25 2.25 0 0022.5 18.75V5.25A2.25 2.25 0 0020.25 3H3.75A2.25 2.25 0 001.5 5.25v13.5A2.25 2.25 0 003.75 21z"
                      />
                    </svg>
                    <p className="text-sm text-muted-foreground">
                      Drop an image or{" "}
                      <span className="text-primary font-medium">browse</span>
                    </p>
                    <p className="text-[10px] text-muted-foreground/60 mt-0.5">
                      PNG, JPG up to 5MB
                    </p>
                  </label>
                )}
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium mb-1 block">
                    Start Date & Time
                  </label>
                  <Input
                    type="datetime-local"
                    value={form.date}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, date: e.target.value }))
                    }
                  />
                </div>
                <div>
                  <label className="text-sm font-medium mb-1 block">
                    End Date & Time
                  </label>
                  <Input
                    type="datetime-local"
                    value={form.endDate}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, endDate: e.target.value }))
                    }
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium mb-1 block">
                    Location
                  </label>
                  <Input
                    value={form.location}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, location: e.target.value }))
                    }
                    placeholder="Nebraska Innovation Campus"
                  />
                </div>
                <div>
                  <label className="text-sm font-medium mb-1 block">Type</label>
                  <select
                    value={form.type}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, type: e.target.value }))
                    }
                    className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                  >
                    <option value="in_person">In Person</option>
                    <option value="online">Online</option>
                    <option value="hybrid">Hybrid</option>
                  </select>
                </div>
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <Button
                  variant="outline"
                  onClick={() => setShowDialog(false)}
                >
                  Cancel
                </Button>
                <Button
                  onClick={handleSave}
                  disabled={saving || uploading || !form.title || !form.date}
                >
                  {saving
                    ? "Saving..."
                    : editingId
                      ? "Save Changes"
                      : "Create Event"}
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ── Event list item (left panel) ──

function EventListItem({
  event,
  isSelected,
  onSelect,
}: {
  event: EventData;
  isSelected: boolean;
  onSelect: () => void;
}) {
  const isPast = event.date <= Date.now();
  const d = new Date(event.date);
  const month = d.toLocaleDateString("en-US", { month: "short" });
  const day = d.getDate();

  return (
    <button
      onClick={onSelect}
      className={`w-full text-left rounded-lg border transition-colors ${
        isSelected
          ? "border-primary bg-primary/5"
          : "border-border hover:border-primary/30 hover:bg-muted/50"
      }`}
    >
      <div className="flex items-start gap-3 p-3">
        {/* Image or date block */}
        {event.imageUrl ? (
          <div className="h-14 w-14 shrink-0 rounded-md overflow-hidden bg-muted">
            <img
              src={event.imageUrl}
              alt=""
              className="h-full w-full object-cover"
            />
          </div>
        ) : (
          <div className="h-14 w-14 shrink-0 rounded-md bg-muted flex flex-col items-center justify-center">
            <span className="text-[10px] uppercase text-muted-foreground leading-tight">
              {month}
            </span>
            <span className="text-lg font-bold tabular-nums leading-tight">
              {day}
            </span>
          </div>
        )}

        <div className="flex-1 min-w-0">
          <p className="text-sm font-semibold truncate">{event.title}</p>
          <div className="flex items-center gap-2 mt-0.5">
            <Badge
              variant="secondary"
              className={`text-[10px] h-5 ${TYPE_COLORS[event.type] ?? ""}`}
            >
              {TYPE_LABELS[event.type] ?? event.type}
            </Badge>
            {!isPast && (
              <span className="text-[10px] text-blue-600 font-medium">
                Upcoming
              </span>
            )}
          </div>
          <div className="flex items-center gap-3 mt-1.5">
            {/* Attendee avatars */}
            {event.attendees.length > 0 ? (
              <div className="flex items-center">
                <div className="flex -space-x-1.5">
                  {event.attendees.slice(0, 4).map((a) => (
                    <div key={a.id} className="ring-2 ring-background rounded-full">
                      <Avatar url={a.avatarUrl} name={a.name} size="sm" />
                    </div>
                  ))}
                </div>
                <span className="ml-1.5 text-[11px] text-muted-foreground">
                  {event.rsvpCount} going
                </span>
              </div>
            ) : (
              <span className="text-[11px] text-muted-foreground">
                {event.rsvpCount} RSVPs
              </span>
            )}
            {event.averageRating !== null && (
              <span className="text-[11px] text-muted-foreground">
                {event.averageRating}/5
              </span>
            )}
          </div>
        </div>
      </div>
    </button>
  );
}

// ── Details tab ──

function DetailsTab({ event }: { event: EventData }) {
  return (
    <div className="space-y-4">
      {event.description && (
        <div>
          <p className="text-xs font-medium text-muted-foreground mb-1">
            Description
          </p>
          <p className="text-sm leading-relaxed">{event.description}</p>
        </div>
      )}

      <div className="grid grid-cols-2 gap-4">
        <div>
          <p className="text-xs font-medium text-muted-foreground mb-1">Date</p>
          <p className="text-sm">
            {formatEventDate(event.date, event.endDate)}
          </p>
        </div>
        {event.location && (
          <div>
            <p className="text-xs font-medium text-muted-foreground mb-1">
              Location
            </p>
            <p className="text-sm">{event.location}</p>
          </div>
        )}
        <div>
          <p className="text-xs font-medium text-muted-foreground mb-1">Type</p>
          <p className="text-sm">
            {TYPE_LABELS[event.type] ?? event.type}
          </p>
        </div>
        <div>
          <p className="text-xs font-medium text-muted-foreground mb-1">
            Created By
          </p>
          <div className="flex items-center gap-2">
            <Avatar
              url={event.createdBy.avatarUrl}
              name={event.createdBy.name}
              size="sm"
            />
            <span className="text-sm">{event.createdBy.name}</span>
          </div>
        </div>
      </div>

      {/* Quick stats grid */}
      <div className="grid grid-cols-4 gap-3 pt-2">
        <div className="rounded-lg bg-muted/50 p-3 text-center">
          <p className="text-lg font-bold tabular-nums">{event.rsvpCount}</p>
          <p className="text-[10px] text-muted-foreground">Going</p>
        </div>
        <div className="rounded-lg bg-muted/50 p-3 text-center">
          <p className="text-lg font-bold tabular-nums">
            {event.interestedCount}
          </p>
          <p className="text-[10px] text-muted-foreground">Interested</p>
        </div>
        <div className="rounded-lg bg-muted/50 p-3 text-center">
          <p className="text-lg font-bold tabular-nums">
            {event.postEventConnections}
          </p>
          <p className="text-[10px] text-muted-foreground">Connections</p>
        </div>
        <div className="rounded-lg bg-muted/50 p-3 text-center">
          <p className="text-lg font-bold tabular-nums">
            {event.averageRating !== null ? `${event.averageRating}` : "---"}
          </p>
          <p className="text-[10px] text-muted-foreground">Avg Rating</p>
        </div>
      </div>
    </div>
  );
}

// ── Attendees tab ──

function AttendeesTab({ event }: { event: EventData }) {
  const allAttendees = [
    ...event.attendees.map((a) => ({ ...a, section: "going" as const })),
    ...event.interestedAttendees.map((a) => ({
      ...a,
      section: "interested" as const,
    })),
  ];

  if (allAttendees.length === 0) {
    return (
      <p className="text-sm text-muted-foreground py-6 text-center">
        No RSVPs yet
      </p>
    );
  }

  const going = allAttendees.filter((a) => a.section === "going");
  const interested = allAttendees.filter((a) => a.section === "interested");

  return (
    <div className="space-y-4">
      {going.length > 0 && (
        <div>
          <div className="flex items-center justify-between mb-2">
            <p className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
              Going ({going.length})
            </p>
          </div>
          <div className="space-y-1">
            {going.map((attendee) => (
              <AttendeeRow key={attendee.id} attendee={attendee} />
            ))}
          </div>
        </div>
      )}

      {interested.length > 0 && (
        <div>
          <p className="text-xs font-medium text-muted-foreground uppercase tracking-wider mb-2">
            Interested ({interested.length})
          </p>
          <div className="space-y-1">
            {interested.map((attendee) => (
              <AttendeeRow key={attendee.id} attendee={attendee} />
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

function AttendeeRow({ attendee }: { attendee: Attendee }) {
  return (
    <div className="flex items-center gap-3 rounded-md px-2 py-2 hover:bg-muted/50 transition-colors">
      <Avatar url={attendee.avatarUrl} name={attendee.name} size="md" />
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium truncate">{attendee.name}</p>
        {attendee.headline && (
          <p className="text-xs text-muted-foreground truncate">
            {attendee.headline}
          </p>
        )}
      </div>
      <span className="text-[10px] text-muted-foreground shrink-0">
        {new Date(attendee.rsvpDate).toLocaleDateString("en-US", {
          month: "short",
          day: "numeric",
        })}
      </span>
    </div>
  );
}

// ── Analytics tab ──

function AnalyticsTab({ event }: { event: EventData }) {
  const isPast = event.date <= Date.now();
  const connectionRate =
    event.rsvpCount > 0
      ? Math.round((event.postEventConnections / event.rsvpCount) * 100)
      : 0;

  return (
    <div className="space-y-5">
      {/* Key metrics */}
      <div className="grid grid-cols-3 gap-4">
        <div>
          <p className="text-xs text-muted-foreground">Connection Rate</p>
          <p className="text-2xl font-bold tabular-nums mt-0.5">
            {isPast
              ? event.rsvpCount > 0
                ? `${connectionRate}%`
                : "---"
              : "---"}
          </p>
          <p className="text-[10px] text-muted-foreground">
            Connections / RSVPs
          </p>
        </div>
        <div>
          <p className="text-xs text-muted-foreground">Feedback Rate</p>
          <p className="text-2xl font-bold tabular-nums mt-0.5">
            {isPast
              ? event.rsvpCount > 0
                ? `${Math.round((event.feedbackCount / event.rsvpCount) * 100)}%`
                : "---"
              : "---"}
          </p>
          <p className="text-[10px] text-muted-foreground">
            {event.feedbackCount} of {event.rsvpCount} responded
          </p>
        </div>
        <div>
          <p className="text-xs text-muted-foreground">Post-Event DMs</p>
          <p className="text-2xl font-bold tabular-nums mt-0.5">
            {event.postEventConnections}
          </p>
          <p className="text-[10px] text-muted-foreground">Within 48 hours</p>
        </div>
      </div>

      {/* Rating breakdown */}
      {event.feedbackCount > 0 && (
        <div>
          <p className="text-xs font-medium text-muted-foreground mb-2">
            Rating Distribution
          </p>
          <div className="space-y-1.5">
            {[5, 4, 3, 2, 1].map((star) => {
              const count = event.ratingBreakdown[star - 1] ?? 0;
              const pct =
                event.feedbackCount > 0
                  ? Math.round((count / event.feedbackCount) * 100)
                  : 0;
              return (
                <div key={star} className="flex items-center gap-2">
                  <span className="text-xs w-3 text-right tabular-nums">
                    {star}
                  </span>
                  <div className="h-2 flex-1 rounded-full bg-muted">
                    <div
                      className="h-2 rounded-full bg-amber-400"
                      style={{ width: `${Math.max(pct, 2)}%` }}
                    />
                  </div>
                  <span className="text-xs text-muted-foreground w-6 text-right tabular-nums">
                    {count}
                  </span>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Top improvement requests */}
      {event.topImprovements.length > 0 && (
        <div>
          <p className="text-xs font-medium text-muted-foreground mb-2">
            Improvement Requests
          </p>
          <div className="space-y-1.5">
            {event.topImprovements.map((imp) => (
              <div
                key={imp.label}
                className="flex items-center justify-between rounded-md bg-muted/50 px-3 py-2"
              >
                <span className="text-sm">{imp.label}</span>
                <Badge variant="secondary" className="text-xs">
                  {imp.count}
                </Badge>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Insight */}
      {isPast && event.rsvpCount > 0 && (
        <div className="rounded-lg bg-muted/50 p-3">
          <p className="text-xs font-medium mb-1">Insight</p>
          <p className="text-sm text-muted-foreground">
            {connectionRate >= 30
              ? "Strong networking event — this format works. Consider running it monthly."
              : connectionRate > 0
                ? "Some connections formed. Try adding structured networking (speed intros, skill-matching breakouts) to boost the rate."
                : "No post-event connections detected. Consider adding ice-breakers or a post-event channel to keep momentum."}
          </p>
        </div>
      )}

      {!isPast && (
        <div className="rounded-lg bg-blue-500/5 border border-blue-500/10 p-3">
          <p className="text-xs font-medium mb-1 text-blue-600">
            Upcoming Event
          </p>
          <p className="text-sm text-muted-foreground">
            Analytics will populate after the event ends. Post-event connections
            are tracked for 48 hours.
          </p>
        </div>
      )}
    </div>
  );
}

// ── Helpers ──

function formatEventDate(
  date: number,
  endDate: number | null
): string {
  const start = new Date(date);
  const startStr = start.toLocaleDateString("en-US", {
    weekday: "short",
    month: "short",
    day: "numeric",
  });
  const timeStr = start.toLocaleTimeString("en-US", {
    hour: "numeric",
    minute: "2-digit",
  });

  if (!endDate) return `${startStr} at ${timeStr}`;

  const end = new Date(endDate);
  const sameDay = start.toDateString() === end.toDateString();
  const endTimeStr = end.toLocaleTimeString("en-US", {
    hour: "numeric",
    minute: "2-digit",
  });

  if (sameDay) return `${startStr}, ${timeStr} - ${endTimeStr}`;

  const endStr = end.toLocaleDateString("en-US", {
    weekday: "short",
    month: "short",
    day: "numeric",
  });
  return `${startStr} ${timeStr} - ${endStr} ${endTimeStr}`;
}
