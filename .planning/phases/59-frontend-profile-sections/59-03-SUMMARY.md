---
phase: 59-frontend-profile-sections
plan: "03"
subsystem: ev-ui, essentials
tags: [gap-closure, ui-fix, navigation, component-library]
dependency_graph:
  requires: [59-01, 59-02]
  provides: [inline-summary-card-embedded, voter-friendly-stats, navigation-loop-fix]
  affects: [essentials/Profile, ev-ui/LegislativeInlineSummary, ev-ui/PoliticianProfile]
tech_stack:
  added: []
  patterns: [callback-prop-for-spa-navigation, section-within-card-styling]
key_files:
  created: []
  modified:
    - ev-ui/src/LegislativeInlineSummary.jsx
    - ev-ui/src/PoliticianProfile.jsx
    - ev-ui/package.json
    - essentials/src/pages/Profile.jsx
    - essentials/package.json
    - essentials/package-lock.json
decisions:
  - LegislativeInlineSummary uses borderTop separator (not standalone card) — embedded inside topCard via section styling
  - onNavigateToRecord callback pattern chosen over react-router import in ev-ui — keeps ev-ui portable and framework-agnostic
  - navigate('/') for Profile back button — deterministic dashboard route prevents Profile<->Record loop
metrics:
  duration_minutes: 2
  tasks_completed: 2
  tasks_total: 2
  files_modified: 6
  completed_date: "2026-03-03"
---

# Phase 59 Plan 03: Frontend Gap Closure — Inline Summary Positioning, Stat Labels, Navigation Summary

Fixed three frontend gaps found during human testing of Phase 59: inline summary now renders inside the profile card with a subtle border separator, stats use voter-friendly descriptive sentences, and the back button navigates to dashboard (/) to prevent the Profile-Record loop.

## Objective

Close three specific UX gaps discovered during human testing:
1. LegislativeInlineSummary was rendering as a visually separate card below the profile card — design intent was embedded inside.
2. Stats used insider jargon ("attendance", "bills advanced") rather than descriptive voter-friendly language.
3. Profile back button used navigate(-1), causing a loop when coming from LegislativeRecord.

## Tasks Completed

### Task 1: Fix inline summary positioning, card styling, and stat labels in ev-ui

**ev-ui@0.1.38 — all four changes:**

1. **Moved LegislativeInlineSummary inside topCard div** (PoliticianProfile.jsx): Component now renders after the `topRow` div but before `</div>  {/* end topCard */}`, so it appears as a section within the card rather than a separate card below it.

2. **Removed standalone card styling** (LegislativeInlineSummary.jsx): Replaced `{ background, borderRadius, boxShadow, marginBottom }` with `{ borderTop: '1px solid ...', padding, marginTop }`. The component is now visually a section within the parent card.

3. **Rephrased stat labels for voters**: Changed from `{ value: '92%', label: 'attendance' }` format to self-contained descriptive sentences: `"Voted in 92% of roll calls"` and `"Authored 5 bills that advanced past introduction"`. Label field is now null; render logic updated to conditionally show it only when non-null.

4. **Converted `<a href>` to `<button onClick>`**: Added `onNavigateToRecord` prop to both `LegislativeInlineSummary` and `PoliticianProfile`. Button calls the callback if provided, falls back to `window.location.href` for non-SPA contexts — keeps ev-ui portable.

Built and published to GitHub npm registry as `@chrisandrewsedu/ev-ui@0.1.38`.

**Commit:** 484892f (ev-ui repo)

### Task 2: Fix back-button navigation and wire onNavigateToRecord in essentials

1. **Updated ev-ui dependency** to `^0.1.38` via `npm install @chrisandrewsedu/ev-ui@0.1.38`.

2. **Fixed Profile.jsx back button**: Changed `onBack={() => navigate(-1)}` to `onBack={() => navigate('/')}`. Now navigates to dashboard root, preventing the loop where Profile → Record → back would return to Profile instead of Dashboard.

3. **Wired onNavigateToRecord**: Added `onNavigateToRecord={(href) => navigate(href)}` prop to `PoliticianProfile` in Profile.jsx. The "View Full Legislative Record" button now uses react-router's navigate() for SPA navigation to `/politician/{id}/record`.

4. **Verified LegislativeRecord.jsx**: Already uses `navigate('/politician/${id}')` (deterministic, not navigate(-1)) — no change needed.

Both ev-ui and essentials builds succeeded without errors.

**Commit:** cb3f622 (essentials repo)

## Deviations from Plan

None - plan executed exactly as written.

## Success Criteria Verification

- Gap 1 CLOSED: LegislativeInlineSummary renders inside the topCard div as a section with a subtle `borderTop` separator, no `boxShadow`, no standalone card appearance. Verified by string position check: `pp.indexOf('LegislativeInlineSummary') < pp.indexOf('end topCard')`.
- Gap 2 CLOSED: Stats render as `"Voted in X% of roll calls"` and `"Authored N bills that advanced past introduction"` — full-sentence, voter-friendly language. No insider jargon labels.
- Gap 3 CLOSED: Profile.jsx `onBack` navigates to `'/'` (dashboard root). No `navigate(-1)` remains. LegislativeRecord.jsx back button was already correct.
- ev-ui@0.1.38 built and published to GitHub npm registry.
- essentials build succeeds with updated package.

## Self-Check: PASSED

Files verified to exist:
- ev-ui/src/LegislativeInlineSummary.jsx — FOUND
- ev-ui/src/PoliticianProfile.jsx — FOUND
- ev-ui/package.json (version 0.1.38) — FOUND
- ev-ui/dist/index.js — FOUND
- essentials/src/pages/Profile.jsx — FOUND
- essentials/package.json (ev-ui@^0.1.38) — FOUND

Commits verified:
- 484892f (ev-ui repo, Task 1) — FOUND
- cb3f622 (essentials repo, Task 2) — FOUND

All 13 automated verification checks: PASS
