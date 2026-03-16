# Phase 89: Coach Marks - Context

**Gathered:** 2026-03-15
**Status:** Ready for planning

<domain>
## Phase Boundary

First real issue is accompanied by a one-time 2-step coach mark tour that spotlights the swipe card area and the rank panel. The tour is permanently dismissed after completion (or any early dismissal). Users who have already completed sessions never see it.

</domain>

<decisions>
## Implementation Decisions

### Tour sequence & content
- 2-step tour: Step 1 spotlights the swipe card area, Step 2 spotlights the rank panel (sidebar on desktop, inline bottom sheet on mobile)
- Step 1 uses interactive spotlight (allowSpotlightInteraction) — user can swipe the card while it's spotlighted
- Step 1 auto-advances to step 2 when the user performs their first swipe (agree or disagree) — no explicit "Next" button needed
- Step 2 is deferred until the user first agrees with a quote and the rank panel becomes visible — if they disagree first, step 2 waits
- Step 2 requires explicit "Got it" button click to dismiss (standard tour pattern)
- Tooltip text is concise and action-oriented: e.g., "Swipe right to agree, left to disagree" / "Pick the stronger quote when matchups appear"
- Same tooltip text on both mobile and desktop — the spotlight target adapts, not the messaging

### Trigger timing
- Tour starts ~500ms after EvaluationPhase mounts and the first QuoteCard is visible on the first real issue
- Only fires on the first real issue after practice round completion (not during practice)

### Mobile vs desktop targets
- Step 1: Same target on both viewports — the QuoteCard / swipe area
- Step 2 desktop: Spotlight the AgreedQuotesSidebar
- Step 2 mobile: Spotlight the InlineRankPanel bottom sheet when it appears after 2nd agree

### Dismissal mechanism
- `coachMarksCompleted: boolean` flag in Zustand store, persisted via Zustand persist
- Store version bump to v6 with migration: existing users (version > 0) get `coachMarksCompleted: true`, new users get `false`
- Any dismissal action (complete tour, Skip All, Escape, tap outside) sets `coachMarksCompleted: true` permanently — no partial resume, no retry
- Matches the `practiceCompleted` pattern established in Phase 88

### Claude's Discretion
- Exact tooltip wording for each step
- CoachMark TypeScript port details (adapting JSX → TSX from CompassV2)
- Animation timing and delay values
- Whether step 2 spotlight targets the full sidebar/panel or just the header area
- How to detect "first swipe" to auto-advance step 1

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — ONBD-05 and ONBD-06 define coach mark acceptance criteria

### Source component
- `CompassV2/src/components/CoachMark.jsx` — Full-featured CoachMark component to TypeScript-port: SVG mask spotlight, allowSpotlightInteraction mode, tour mode (Next/Skip All), single hint mode (Got it), auto-positioning, ResizeObserver tracking

### Prior phase context
- `.planning/phases/88-practice-round/88-CONTEXT.md` — Practice round flow, store v5 migration pattern, practiceCompleted flag pattern
- `.planning/phases/87-unified-evaluatephase-inlinerankpanel/87-CONTEXT.md` — Inline ranking mechanic, sidebar/bottom sheet behavior, matchup flow

### State decisions
- `.planning/STATE.md` — Accumulated decisions: "CoachMark TypeScript-ported from CompassV2 directly into EV-readrank this milestone — not published to ev-ui (single consumer)"

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CompassV2/src/components/CoachMark.jsx`: Full CoachMark component (~435 lines) with `useCoachMark` hook, spotlight overlay (SVG mask + 4-rect interactive modes), tooltip positioning, caret arrows, tour mode, Escape key handling, ResizeObserver — needs TypeScript port
- `EvaluationPhase.tsx`: Core evaluation component — will host coach mark step 1 trigger and step 1→2 transition logic
- `AgreedQuotesSidebar.tsx`: Desktop rank panel — step 2 target on desktop
- `InlineRankPanel.tsx`: Mobile bottom sheet rank panel — step 2 target on mobile
- `QuoteCard.tsx`: Swipe card component — step 1 spotlight target

### Established Patterns
- Zustand persist with version + migrate: Store at v5, bump to v6 with `coachMarksCompleted` migration
- `practiceCompleted` flag pattern: boolean in store, set true for existing users via migration, `false` for new users
- `PhaseContainer.tsx`: Checks `practiceCompleted` to auto-redirect — similar pattern for coach marks gating
- Framer Motion `AnimatePresence` used throughout — CoachMark already uses this

### Integration Points
- `useReadRankStore.ts` line 91+: Add `coachMarksCompleted: boolean` to store interface
- `useReadRankStore.ts` line 146+: Add `coachMarksCompleted: false` to initial state
- `useReadRankStore.ts` line 570+: Bump to v6, migration sets `coachMarksCompleted: true` for existing users
- `EvaluationPhase.tsx`: Add coach mark rendering logic — detect first real issue, manage 2-step tour state
- `QuoteCard.tsx`: Expose ref for spotlight targeting
- `AgreedQuotesSidebar.tsx` / `InlineRankPanel.tsx`: Expose refs for step 2 spotlight targeting

</code_context>

<specifics>
## Specific Ideas

- Step 1 interactive spotlight is key — user learns by doing, not by reading. The swipe action itself dismisses step 1.
- Step 2 defers naturally until there's something to spotlight — no awkward "your quotes will appear here" on empty space.
- The whole tour should feel lightweight — 2 steps max, fast transitions, never blocks the user from exploring.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 89-coach-marks*
*Context gathered: 2026-03-15*
