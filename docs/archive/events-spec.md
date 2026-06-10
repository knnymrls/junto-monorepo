# Events

Community events where makers meet IRL.

## Philosophy

- Events are the acquisition funnel (download app → RSVP)
- Post-event connections matter more than during-event pressure
- Feedback drives iteration on event formats

## Goal

Get people in the room, help them connect after.

---

## Decisions Made

| Element | Decision |
|---------|----------|
| RSVP states | Going, Interested, Not Going |
| RSVP requirement | Must be signed in |
| Attendee visibility | Hidden until you RSVP (or event ends) |
| Post-event access | Attendee list unlocks after event ends |
| Feedback timing | Prompted 1 day after event |
| Event types | General, Speed Dating (future: Workshop, Hackathon) |
| Matching (speed dating) | Based on lookingFor + interests + embedding similarity |

---

## Screens to Design

1. **Events list** — Upcoming events
2. **Event detail** — Single event with RSVP
3. **Attendees list** — Who's going / who attended (post-event)
4. **Feedback sheet** — Post-event survey
5. **Admin: Create event** — (if you want in-app creation, otherwise skip)

---

## Components

### Event card (in list)

- Event image
- Title
- Date + time
- Location (or "Virtual")
- Attendee count ("23 going")
- RSVP status indicator (if you've RSVPed)

### Event detail

- Hero image
- Title
- Date + time + location
- Description
- Host info (tappable → profile)
- RSVP button (primary CTA)
- Attendee preview (avatars, "23 makers going")
- "See who's going" (gated until RSVP)

### Attendees list

- Avatar + name + headline
- Connect button per person
- Post-event: "You met at [Event Name]" context
- Optional: Match score badge ("85% match")

### Feedback sheet

- "How was [Event Name]?" (1-5 rating or emoji)
- "What would improve future events?" (multi-select: more time, different venue, themed topics, smaller/larger group)
- "Anyone you'd like to connect with?" (optional, shows attendee list for quick-select)
- Submit button

---

## Notifications

- Event reminder (1 day before, 1 hour before)
- "Event just ended — see who attended"
- "How was [Event Name]?" (feedback prompt, 1 day after)
- Someone from event connected with you

---

## Track in PostHog

| Event | Properties |
|-------|------------|
| `event_viewed` | eventId, eventType |
| `event_rsvp` | eventId, status (going/interested/not_going) |
| `attendees_list_viewed` | eventId, timing (pre/post event) |
| `connect_from_event` | eventId, toMakerId |
| `feedback_submitted` | eventId, rating |
| `feedback_skipped` | eventId |

---

## Schema Changes Needed

```
eventAttendees (extends eventRsvps)
  - checkedIn: boolean

eventFeedback
  - eventId
  - makerId
  - rating: number
  - improvements: string[]
  - wantToConnectWith: Id[]
  - createdAt
```

---

## Out of Scope (for now)

- In-app event creation (use admin/Convex dashboard)
- Speed dating round management UI
- Recurring events
- Ticketed/paid events
