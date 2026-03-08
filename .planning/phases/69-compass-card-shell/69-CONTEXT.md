# Phase 69: Compass Card Shell - Context

**Gathered:** 2026-03-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the CompassCard component on Essentials profile pages with conditional rendering based on politician stance data availability. The card is a shell — Phase 70 adds the radar chart, Phase 71 adds the stance breakdown. This phase delivers the container, gating logic, and CTA fallback.

</domain>

<decisions>
## Implementation Decisions

### Card Placement
- Renders below PoliticianProfile as a sibling element in Profile.jsx — no ev-ui changes needed
- Section header: "Compass & Issues"
- Positioned after the full PoliticianProfile component output (below bio/legislative sections)

### Shell Appearance
- Placeholder layout with skeleton zones for left (chart) and right (breakdown) panels
- 2-column layout on desktop, stacked on mobile (chart area on top, breakdown below)
- White card with subtle shadow — matches existing profile page aesthetic
- Left/right skeleton zones indicate the 2-panel structure that Phase 70-71 will fill

### No-Compass Fallback
- When politician has stances but user has no compass data: show the card with a CTA to calibrate
- CTA includes greyed compass icon + prompt text + "Take the Quiz" button — mirrors existing CompassPreview CTA pattern
- CTA links to CompassV2 with return URL (?return={current_profile_url}) so user returns with data via fragment bridge (Phase 68)
- When politician has NO stances: card is hidden entirely (renders nothing)

### Component Location
- Built in essentials/src/components/CompassCard.jsx — local to Essentials app
- Can be moved to ev-ui later if other apps need it

### Claude's Discretion
- Whether gating logic (check politicianIdsWithStances) lives inside CompassCard or in Profile.jsx
- How compassLoading state is handled (self-contained vs parent-managed)
- Skeleton zone visual design (pulse animation, border style, sizing)
- Exact spacing between PoliticianProfile and CompassCard sections

</decisions>

<specifics>
## Specific Ideas

- Section header "Compass & Issues" chosen to capture both the radar chart and stance breakdown aspects
- CTA should feel like the existing CompassPreview CTA (greyed icon, prompt text, teal button) but sized for a full card rather than a popover
- User said "I don't love any of those" when offered Political Compass / Compass Comparison / Where You Align — preferred something that references both the chart and the issues

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `essentials/src/contexts/CompassContext.jsx`: Provides `politicianIdsWithStances` (Set), `userAnswers`, `compassLoading` via `useCompass()` hook — all gating inputs available
- `essentials/src/components/CompassPreview.jsx`: CTA mode (lines 285-350) with greyed compass SVG, prompt text, and teal button — pattern to mirror for the card fallback
- `CompassPreview` CTA link format: `${COMPASS_URL}?return=${encodeURIComponent(returnUrl)}` — reuse this exact pattern

### Established Patterns
- Profile.jsx renders PoliticianProfile as sole content in `<main>` container (max-w-6xl, container mx-auto)
- PoliticianProfile is from ev-ui and handles the full profile layout internally
- All compass data fetching happens in CompassContext at app root — Profile.jsx just consumes via hook
- Tailwind CSS 4 for styling throughout Essentials

### Integration Points
- `essentials/src/pages/Profile.jsx`: Add CompassCard as sibling after PoliticianProfile (line 74-98)
- `essentials/src/contexts/CompassContext.jsx`: Already provides all needed state — no changes required
- Politician ID available as `id` from useParams() in Profile.jsx — pass to CompassCard

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 69-compass-card-shell*
*Context gathered: 2026-03-08*
