# Junto — Component Specs (exact, from the iOS app)

> Per-component spec extracted from `apps/ios`. Build web components to these exact numbers. Companion to [DESIGN.md](./DESIGN.md).
> Radius: xs4 sm6 md8 lg10 xl12 xxl16 xxxl24 pill9999. Spacing: 2/4/6/8/12/16/20/24/32/36/40. All SF Pro except the Bricolage wordmark.
> Press: spring(response 0.3, damping 0.55). Scales: 0.9 nav/circle/avatar/tab · 0.96 connect/card · 0.97 primary/FAB.

## Buttons (the rounding matters — they are NOT all the same)
- **Primary CTA** (`PrimaryButton`): **Capsule pill, height 53**, full-width, fill `appAccent` (#333 / white), text `appOnAccent`, font 16 semibold, optional leading icon 20 (solid). Press 0.97. Disabled = opacity 0.6 + `appSurfaceSecondary` fill. Outlined variant = clear + 1px `appDivider` stroke, text `appPrimary`.
- **Action / Connect** (`ConnectionButton` fullWidth): **radius 8 (md)**, fill `appPrimary` + literal white text, vertical pad 16. Press 0.96. Connected/Pending = clear + 1px `appDivider` stroke, `appSecondary` text.
- **Connect compact** + **Save** (EditProfile): Capsule. Save = `appAccent`, pad h16 v6, press 0.95.
- **In-card button** (AskJunto): radius 8 (md), `appPrimary` fill, `appOnAccent` text, 15 medium, press 0.96.
- **Icon / circle button** (`DiscoverCircleButton`): **40×40 circle**, fill `appSurfaceSecondary`, icon 16 `appPrimary`. Press 0.9.
- **FAB**: 64×52, **radius 16 (xxl)**, fill `appPrimary`, icon 20 `appOnAccent` (solid).
- **Filter tab** (Events): radius 12, height 32. Selected `appPrimary`+`appOnAccent` / unselected `appSurfaceSecondary`+`appSecondary`.

## AI input — Ask Junto composer (`AskJuntoComposer`)
- **Shape: Capsule (pill).** Fill: **#E5E5E5 light / #262626 dark** (hardcoded, NOT a token). **No border.**
- min-height 32. Padding: leading 16 (while typing) / 8 (idle), trailing 8, vertical 8. HStack gap 8.
- **Leading = the Junto mark in a circle:** circle fill white (light) / #3A3A3A (dark); glyph `tab.junto` tinted `appPrimary`, **20×20 in a 32 circle** idle; shrinks to **14 in a 24 circle and SPINS** while thinking; **HIDES once the user types** (text non-empty, not on focus).
- Text: SF Pro 16 regular `appPrimary`. Placeholder: **"Ask any question…"** 16 `appSecondary`.
- **No send button** — keyboard Return submits.
- Outer placement: horizontal pad 12, bottom 72.

## Inputs (no border, fill-only)
- **JuntoTextField**: fill `appInputFill` (#F2F2F2 / #262626), **height 53**, **radius 16 (xxl)**, h-pad 12, optional leading icon 16 `appSecondary`, text 16, **no border**. Label above = 16 semibold.
- **JuntoTextArea**: same fill/radius, pad h8 v6, min-height 60, text 16 lineSpacing 3, char counter 11.
- **Auth email field**: **radius 12 (xl)** (the exception), height 53, centered 16 semibold.
- **Search bars**: inline search = radius 12 `appSurfaceSecondary`; Messages/MakerSearch = **Capsule height 37** `appSurfaceSecondary`; DiscoverSearchBar = white pill radius 16 + 0.5px border + arrow-up send (28×28 rounded 12).
- **OTP box**: 50×62, radius 12, `appSurfaceSecondary`, char 28 semibold.

## Cards & lists
- **THE card** (`.cardStyle()`): `appSurface` fill + **1px `appDivider` border** + **radius 12 (xl)**, continuous, **no shadow**. (profile widgets, panels)
- **Feature card**: radius 24 (xxxl) + 1px `appBorder`, outer margin h12 v8. (hero match / event)
- Compact carousel card: radius 16, no border. Search masonry: radius 10 + 0.5px border. SearchResult: radius 10, no border. AskJunto cards / response bubble: `appSurfaceSecondary` fill + radius 16.
- **Lists = FLAT ROWS**: no radius/border, surface bg, padding h12 v16 (events h16 v12), separated by a **1px `appDivider`** between rows. (Feed, Discover, Conversations, Settings, Attendees.)
- **Inner content box**: `appSurfaceSecondary` fill + radius 16, no border.

## Message bubble (`MessageBubble`)
- **Radius 18** (hardcoded). Padding h16 v12. Max width = container − 60.
- **Sent**: fill `appPrimary` + white text → on web use `bg-primary` + `text-primary-foreground`. **Received**: `appSurfaceSecondary` + `appPrimary`.
- Deleted = italic, no fill, 1px `appDivider`. GIF radius 16. Reaction pills = Capsule.

## Chips / tags / labels
- **TopicTag**: flat icon 14 + label 14, all `appSecondary` (gray). No background.
- **CategoryChip**: radius 12 + 1px `appBorder`, **colored** category icon 20 + label 14 `appPrimary`. Press 0.96.
- **CategoryPill**: filled Capsule, colored bg + text, height 28, h-pad 10, icon 14.
- **SelectableChip**: radius 16, selected `appAccent`+`appOnAccent` / unselected `appInputFill`+`appPrimary`, no border, scale 1.03 + spring on select, +/x icon.
- **FeedbackImprovementChip**: Capsule. Unselected = `appPrimary` text + 1px `appDivider` + clear. Selected = white text + `appPrimary` bg.
- **FeedTypeLabel**: flat colored icon 12 + text 12, no bg. Ask #FF0023, Opportunity #6A1B9A, Match #0051FF.
- Status "Going": `appSuccess` 12% bg + `appSuccess` text, Capsule. Confirmed pill #D3F9D8 / #2B8A3E.
- Token/interest pills: `appSurfaceSecondary` + Capsule, text 10-11 `appSecondary`.

## Nav / segmented
- **BrandTopNav**: avatar 40 (press 0.9) + center wordmark (Bricolage 24/800) or title (SF 24 semibold) + trailing icon 28 in a 40 tap target (press 0.9). pad h16, bottom 8.
- **TabBar**: 5 icons 24 (selected uses the **.fill / solid** variant, `appPrimary`; unselected `appSecondary`), center mark 28 in 60×44 radius 12 `appSurfaceSecondary`. Press 0.9. Notif dot = 8 red.
- **Segmented** (`DiscoverSegmentedControl`): pill track `appSurfaceSecondary` + selected pill `appSurface`, each option 86×32.

## Avatars
Circle. Fallback = `appSurfaceSecondary` circle + initial (size×0.4, medium, `appSecondary`). Sizes: **44 default list** · 40 nav · 36 compact · 56 hero · 32 small · 14 inline.

## Icons
**Line by default; SOLID when contained** (inside a button / circle / frame) or **selected/active** (tab `.fill`, ExperienceCard `feed.opportunity.fill`, EditProfile `nav.grid.fill` in a circle). Streamline Flex (ships line + solid). Sizes: nav 24 · trailing 28 · button leading 20 · input 16 · tag 14 · type-label 12 · badge glyph 10 · empty-state 48.

## Status + category colors
- success #34C759 · error #FF3B30 (#FF4539 dark) · warning #FFC800 (#FFD60A) · link/unread = systemBlue #007AFF.
- 12-category palette (icons only; gray everywhere else): software #0051FF · ai #6741D9 · design #7C3AED · hardware #E8590C · data #0CA678 · business #2F9E44 · finance #B7791F · marketing #E8388A · content #AE3EC9 · science #4263EB · health #E03131 · impact #1098AD · leadership #F08C00.
