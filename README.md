# Junto

Campus platform where students build a professional identity, get matched with people they should know, and actually connect across disciplines. Universities pay for the engagement data and insights.

## Monorepo Structure

```
apps/
  ios/          SwiftUI iOS app (managed by Xcode)
  web/          Next.js web app (student-facing)
  dashboard/    Next.js university dashboard (admin-facing)
packages/
  backend/      Shared Convex backend (schema, functions, crons)
docs/           Product docs (PRD, specs, meeting prep)
```

## Getting Started

**Backend (Convex):**
```bash
cd packages/backend
npx convex dev
```

**Web app:**
```bash
pnpm --filter @junto/web dev
```

**Dashboard:**
```bash
pnpm --filter @junto/dashboard dev
```

**iOS app:**
Open `apps/ios/junto.xcodeproj` in Xcode.

## Tech Stack

- **iOS:** SwiftUI + Convex Swift SDK + Clerk
- **Web:** Next.js 16 + Convex + Clerk + Tailwind + shadcn/ui
- **Dashboard:** Next.js + Convex + d3-force + Recharts + shadcn/ui
- **Backend:** Convex (real-time, serverless)
- **Auth:** Clerk
- **Analytics:** PostHog
- **AI:** OpenAI embeddings (text-embedding-3-small) + GPT for matching
