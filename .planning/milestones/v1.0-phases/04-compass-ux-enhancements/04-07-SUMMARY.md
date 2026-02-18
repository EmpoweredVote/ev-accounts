---
phase: 04-compass-ux-enhancements
plan: "07"
subsystem: CompassV2/Library
tags: [guest-visibility, answer-hydration, auth-gated-fetch, library-drawer]
dependency_graph:
  requires: ["04-05", "04-06"]
  provides: ["guest-safe-library", "drawer-answer-highlight"]
  affects: ["CompassV2/src/pages/Library.jsx"]
tech_stack:
  added: []
  patterns: ["isLoggedIn-gated-fetch", "localStorage-fallback", "server-answer-hydration"]
key_files:
  modified:
    - path: CompassV2/src/pages/Library.jsx
      change: "Guest-safe answeredTopicIDs fetch + full answer value hydration for logged-in users"
decisions:
  - "answeredTopicIDs effect now has [isLoggedIn, topics, answers] dependency array — was [] (fired once before auth check resolved)"
  - "Guest path derives answeredTopicIDs from localStorage-backed answers context, sets answeredLoaded=true immediately"
  - "Logged-in path hydrates both answers and writeIns from /compass/answers response (was discarding value/write_in_text fields)"
  - ".catch() fallback also sets answeredLoaded=true so fetch failures never block the card grid"
metrics:
  duration: "2 min"
  completed: "2026-02-18"
  tasks_completed: 2
  files_modified: 1
---

# Phase 04 Plan 07: Guest Library Visibility and Answer Hydration Summary

One-liner: Guest-safe answeredTopicIDs fetch (immediate for guests, server-fetched for users) with full answer value hydration so LibraryDrawer correctly highlights previously-selected stances after login.

## What Was Built

Fixed two data-flow issues in `Library.jsx` that blocked guests from seeing the issue card grid and prevented the LibraryDrawer from highlighting selected stances after login/logout cycles.

### Task 1: Fix guest visibility — guard answeredTopicIDs fetch behind isLoggedIn

**Problem:** The `useEffect` fetching `/compass/answers` fired unconditionally with an empty `[]` dependency array. For guests (no session cookie), the backend returns 401. The `.then(res => res.json())` chain failed silently, so `setAnsweredLoaded(true)` never ran. Since `answeredLoaded` gates the entire category card grid (line 429), guests saw a completely blank Library page.

**Fix applied to `CompassV2/src/pages/Library.jsx`:**
- Added `isLoggedIn` check at the top of the effect
- For guests: derive `answeredTopicIDs` from localStorage-backed `answers` context, call `setAnsweredLoaded(true)` immediately, return early
- For logged-in users: continue with server fetch, but add `res.ok` check before `res.json()` to properly handle non-200 responses
- Added `.catch()` fallback that also sets `answeredLoaded=true` using localStorage-derived IDs
- Changed dependency array from `[]` to `[isLoggedIn, topics, answers]` so the effect re-derives when auth state or context changes

**Commit:** 9b15529

### Task 2: Hydrate full answer values for all topics on answeredTopicIDs fetch

**Problem:** After login, `Login.jsx` clears localStorage answers. The Library page fetched `/compass/answers` (GET) but only extracted `topic_id`, discarding the `value` and `write_in_text` fields. `getAnswer(topic)` reads from the `answers` context object (empty after login). Result: cards showed checkmarks (answeredTopicIDs populated) but the drawer did not highlight the selected stance (`answers[short_title]` was undefined).

**Fix applied to `CompassV2/src/pages/Library.jsx`:**
- In the logged-in branch's `.then((data) => { ... })` callback, after setting `answeredTopicIDs`, now also hydrate `answers` context from the response's `value` fields
- Maps `topic_id` to `short_title` via `topicsRef.current` (same pattern used by the selectedTopics batch fetch)
- Also extracts `write_in_text` entries and hydrates `writeIns` context
- Uses `setAnswers((prev) => ({ ...prev, ...entries }))` spread merge to preserve any concurrent local state
- `setAnsweredLoaded(true)` moved to after both hydration steps

**Commit:** ad380f0

## Verification

1. Build passes: `npm run build` succeeds with no errors in both tasks
2. Guest path: `!isLoggedIn` branch sets `answeredLoaded=true` immediately — card grid renders without requiring server fetch
3. Logged-in path: answer values from `/compass/answers` response now populate `answers` context — drawer's `getAnswer(topic)` returns correct value for any previously-answered topic
4. Fallback: `.catch()` ensures `answeredLoaded=true` even on network failures — card grid never permanently blocked

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check

### Files
- [x] CompassV2/src/pages/Library.jsx — modified

### Commits in CompassV2 repo
- [x] 9b15529 — fix(04-07): guard answeredTopicIDs fetch behind isLoggedIn for guest visibility
- [x] ad380f0 — fix(04-07): hydrate full answer values for all topics on answeredTopicIDs fetch
