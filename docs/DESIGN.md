# Junto — Design System (web)

> The design language for Junto on the web, lifted directly from the iOS app (`apps/ios/junto/Core/Theme` + `Core/Components`). Read this as law before generating any UI. Use these tokens. Do not invent colors, fonts, or spacing.

## Identity

Monochrome, flat, and quiet. The whole language is black / white / grays with **no accent color**. Surfaces are defined by 1px hairline borders, not fills or heavy shadows. Type is SF Pro everywhere, with Bricolage Grotesque reserved for the wordmark and rare display moments. Interaction feels tactile (a springy press scale). It is premium by restraint, Apple-native. Color appears only in two places: status (success/warn/error) and categorical encoding (skill categories, graph cohorts), and even those stay muted unless they are the point of the view.

The connection graph (the Map) is the one place we let the design breathe and feel alive. Everything else stays calm so the graph is the jewel.

## Hard rules (do / don't)

- **No accent color.** The primary action color is monochrome: near-black `#333` in light, white in dark. There is no brand blue/green/purple.
- **No purple, no gradients-on-white, no glows.** These are the AI-generic tells. Avoid them.
- **Fonts:** SF Pro (system) for everything. Bricolage Grotesque ONLY for the "Junto" wordmark and occasional oversized display. Never use Inter, Roboto, or Space Grotesk.
- **Cards are flat:** surface color equals background; lift with a 1px hairline border (and at most a very soft shadow in light mode). No filled gray cards, no drop shadows stacked.
- **Color is earned:** only status and category/cohort encoding. Default category icons to gray; show their color only where category identity is the content (e.g. the graph, a "browse by category" row).
- **Icons: line by default, solid when contained.** Standalone / inline icons (top-nav, inline tags, empty states, input affordances) are line/outline. Icons that sit inside a button or a filled/contained frame (icon buttons, the FAB, a circle/avatar action, a selected or active state) use the **solid (filled)** variant. Streamline Flex on iOS ships both weights; on web use one set that has both line + solid (e.g. Hugeicons, or Lucide + a solid companion). Always template / monochrome, taking the text color. No emoji, no multicolor icons.
- **Hairlines are 1px** (0.5px where the platform allows). Borders use the border token, never a hard black line.

## How we build (shadcn-first)

- **Reach for a shadcn primitive first.** shadcn has a big library — before building anything, check whether a primitive already exists (Button, Card, Input, Textarea, Badge, Avatar, Tabs, Toggle, ToggleGroup, Tooltip, Skeleton, Label, Separator, Dialog, Popover, DropdownMenu, Select, Switch, etc.). Add what's missing with `pnpm dlx shadcn@latest add <name>`. Do not invent a component that shadcn already ships.
- **Edit the primitive, don't wrap it.** When a primitive needs to match Junto's look, edit the file in `src/components/ui/` so the change is global. Do NOT hand-roll a parallel one-off. Feature/composed components are assembled FROM these primitives.
- **Stack:** Next + shadcn `base-vega` style (on Base UI) + Tailwind v4. All tokens live in `src/app/globals.css` (the mono system below). Never hardcode a color or radius — use the tokens.
- **Exact per-component values:** see [component-specs.md](./component-specs.md).

### Primitive customizations already in place
- `button.tsx` — added a `pill` size (53px capsule = the primary CTA) and a `fab` size (16px); press-scale (`active:scale-[0.97]`) baked into the base so every button springs.
- `input.tsx` / `textarea.tsx` — filled (`bg-input`), **borderless**, 16px radius (the JuntoTextField look).
- `badge.tsx` — added `open` / `matched` / `resolved` status variants.
- `card.tsx` — flat: 1px hairline border, no ring, no shadow (= `.cardStyle()`).
- `skeleton.tsx` — `bg-foreground/[0.06]` shimmer (matches the iOS skeleton).
- `avatar.tsx` — removed the default border ring.
- `Tabs` used as the pill segmented control (cohort lens); `Toggle` used for selectable + feedback chips.

The component canvas lives at the `/components` route — the gallery to design against and the source of these patterns.

## Color tokens

Exact values from `AppTheme.swift`. Map to shadcn token names; provide both modes. Cards share the background color (flat).

### Light
```
--background:        #FFFFFF
--foreground:        #2D2D2D   /* primary text */
--card:              #FFFFFF   /* flat: same as bg, lifted by border */
--card-foreground:   #2D2D2D
--popover:           #FFFFFF
--popover-foreground:#2D2D2D
--muted:             #F2F2F2   /* secondary surface / input fill */
--muted-foreground:  #999999   /* secondary text */
--secondary:         #F2F2F2
--secondary-foreground:#2D2D2D
--accent:            #F5F5F5   /* hover/active surface only, NOT a brand accent */
--accent-foreground: #2D2D2D
--primary:           #333333   /* the action color (monochrome) */
--primary-foreground:#FFFFFF
--border:            #E5E5E5   /* hairline border + divider */
--input:             #F2F2F2   /* inputs are filled, not outlined */
--ring:              #333333   /* focus ring, mono, used sparingly */
--shadow:            rgba(0,0,0,0.05)
```

### Dark
```
--background:        #101010
--foreground:        #FFFFFF
--card:              #101010
--card-foreground:   #FFFFFF
--popover:           #1C1C1C
--popover-foreground:#FFFFFF
--muted:             #1C1C1C
--muted-foreground:  #AAAAAA
--secondary:         #1C1C1C
--secondary-foreground:#FFFFFF
--accent:            #262626
--accent-foreground: #FFFFFF
--primary:           #FFFFFF
--primary-foreground:#101010
--border:            rgba(255,255,255,0.10)
--input:             #262626
--ring:              #FFFFFF
--shadow:            rgba(0,0,0,0.50)
```

### Status (use ONLY for status, both modes)
```
--success: #34C759
--error:   #FF3B30   (dark: #FF4539)
--warning: #FFC800   (dark: #FFD60A)
--link:    system blue  /* links / inline interactive text only */
```

### Categorical palette (skill categories / graph cohorts)
A 12-color set spread across the hue wheel, from `SkillCategoryStyle.swift`. Use for category identity and graph-node / cohort coloring. Keep muted (gray) unless category color IS the information.
```
software #0051FF · ai #6741D9 · design #7C3AED · hardware #E8590C · data #0CA678
business #2F9E44 · finance #B7791F · marketing #E8388A · content #AE3EC9
science #4263EB · health #E03131 · impact #1098AD · leadership #F08C00
```
For graph cohorts (Accelerator / Catalyst / Raikes) pick a small, legible subset and keep saturation modest so the Map reads as one designed set, not confetti.

## Typography

- **Primary typeface:** SF Pro via system stack: `-apple-system, "SF Pro Text", "SF Pro Display", system-ui, sans-serif`.
- **Display / wordmark:** Bricolage Grotesque (load from Google Fonts), weight 600-800, optical size large. Wordmark + rare hero numbers only.
- Metrics use `font-variant-numeric: tabular-nums` and tight tracking.

Scale (px, from `Typography.swift`):
```
display    48 / 32   (bold)        headings via Bricolage at 24-64 for wordmark/hero
heading    24 / 20 / 18 (semibold)
body       16 / 14 / 13 (regular / medium / semibold)
caption    12 / 11
micro      10
```
Default body is 14-16. Big proof numbers are the only oversized type on a normal screen.

## Spacing (4px base)
```
2 · 4 · 6 · 8 · 12 · 16 · 20 · 24 · 32 · 36 · 40
(xxxs xxs xs sm md lg xl xxl xxxl jumbo huge)
```
Card padding ~16-20. Section gaps ~24-32. Generous whitespace; let it breathe.

## Radius
```
xs 4 · sm 6 · md 8 · lg 10 · xl 12 · xxl 16 · xxxl 24 · pill 9999
```
Pick per element, never one global radius. From the iOS app (most-used: 16, 8, 12):
- **md 8** — rectangular buttons (the Connect button), small controls.
- **lg 10** — compact / masonry cards.
- **xl 12** — the STANDARD card, category chips, the tab center button.
- **xxl 16** — the workhorse: inputs, image thumbnails, the FAB, selectable chips, inner content boxes, full-width CTAs.
- **xxxl 24** — large elevated feature cards (a hero match / event card).
- **full** — pill buttons (PrimaryButton is a Capsule), status capsules, interest pills.

## Surfaces, lists & cards
Three patterns, and **most of the app is the FIRST**:
1. **Flat list rows (default).** Feed, Discover people, Events, activity, the Asks queue: full-width rows, padding 12-16, surface background, **no border, no corner radius**, separated by a **1px (or 0.5px) hairline divider**. Do NOT wrap list items in bordered cards.
2. **Standard card (radius 12).** A contained block: surface + a **1px hairline border**, radius xl (12), **no shadow, no ring**. Flat.
3. **Elevated feature card (radius 24).** A hero block only: surface + 1px border, radius xxxl (24), optional very soft shadow (light mode only).

**Inner content boxes** (a nested "looking for" box, a description, an answer) use the **muted/secondary surface fill** + radius **16**, no border.
**Borders:** 1px standard, 0.5px for the finest dividers, always the border token. **Shadows are rare** (~12 files in the entire iOS app) — default to border-only; a soft `0 2px 6px` at 5% is light-mode-only and reserved for genuinely floating things (the FAB). Dark mode never uses a shadow.

## Components (conventions to design against)

- **Buttons.** Primary = full-width pill, `--primary` fill, `--primary-foreground` text, 16 semibold, ~48-53px tall. Secondary = transparent + 1px border, foreground text. Every button gets the **springy press scale** (scale ~0.96-0.97, spring response ~0.3, damping ~0.55) and, where it maps, haptic-equivalent feedback. Disabled = 0.6 opacity. Any icon inside a button uses the **solid** variant (it's contained).
- **Inputs.** Filled (`--input`), ~48-53px tall, radius 16, optional 16px leading line icon in `--muted-foreground`, optional label above in 16 semibold.
- **Chips / tags.** (a) Inline tag: line icon + 14px label in `--muted-foreground`, no background. (b) Bordered chip: line icon (colored only if category identity) + label on surface + 1px border, radius 12. (c) Selectable chip: fills `--primary` with `--primary-foreground` when selected, `--input` otherwise, +/x affordance, slight scale on select. (d) Status pill: capsule, tinted bg + colored text, used for Open / Matched / Resolved (map to status hues, muted).
- **Avatars.** Circle. Fallback = `--muted` circle + initial in `--muted-foreground` at ~0.4x size, medium weight.
- **Top nav.** Leading avatar (40) + center wordmark (Bricolage) or title (SF Pro 24 semibold) + optional trailing 28px line icon in a 40px tap target. Sits on `--background`.
- **Empty state.** Centered: 48px line icon (`--muted-foreground`) + 18px title + optional 14px muted subtitle, generous vertical padding.
- **Skeleton.** Base = foreground at 6% opacity, shimmer = a clear -> 8% -> clear gradient sweeping left to right, ~1.2s linear loop. Skeletons mirror the real card's radius + border.

## Motion
Restraint plus one signature: the **springy press scale** on every tappable element. Spring transitions (response 0.25-0.3, damping 0.55-0.6). One orchestrated entrance per view at most. No scattered micro-animations. The Map may animate (nodes settling, time-scrubber) since it is the hero.

## Sizes
- **Control heights:** primary button + input = **53** (use 48-53 on web). Status capsule ~24-28.
- **Avatars:** 14 (inline host) · 20 (stacked badge) · 36 · 40 · **44 (default list avatar)** · 48 (framed) · 56 (feature card) · 72-80 (profile).
- **Icons:** nav 24 · trailing nav 28 (in a 40 tap target) · button leading 20 · input affordance 16 · inline tag 14 · small inline 12 · empty-state 48.
- A hairline divider sits between every list row.

## Press feedback (the signature, per element)
Springy scale-down on press, spring(response 0.3, damping 0.55):
- nav icons / avatar / icon buttons → **0.9**
- chips / connect / category → **0.96**
- primary button / FAB → **0.97**
Haptic on primary actions (on web, the scale alone).

## The Map (graph) treatment
Nodes = students, sized by influence, colored by cohort from the categorical palette (muted). Edges = hairline connections in `--border` / a low-opacity foreground. Cross-discipline edges can brighten on toggle. Lives on `--background` so it reads in both light and dark. This is the one surface allowed to feel cinematic; keep the chrome around it dead simple.

## Where this came from
- Colors: `apps/ios/junto/Core/Theme/AppTheme.swift`
- Type: `Core/Theme/Typography.swift` (SF Pro system + Bricolage)
- Spacing / Radius: `Core/Theme/Spacing.swift`, `Radius.swift`
- Components: `Core/Components/*` + `Features/*/Components/*` (PrimaryButton, ConnectionButton, JuntoTextField, AvatarView, EmptyStateView, SkeletonView, TopicTag, CategoryPill, SelectableChip, CategoryChip, BrandTopNav, FeedCard) and `PressableScaleStyle`.
- Categorical palette: `Core/Theme/SkillCategoryStyle.swift`.
