---
phase: 59-frontend-profile-sections
plan: "01"
subsystem: ev-ui
tags: [react, components, legislative-data, ev-ui, npm-publish]
dependency_graph:
  requires: []
  provides: [LegislativeInlineSummary, LegislativeRecord, ev-ui@0.1.37]
  affects: [essentials, PoliticianProfile]
tech_stack:
  added: []
  patterns: [inline-styles-with-tokens, headless-content-component, guard-on-empty-data, year-filter-with-slice]
key_files:
  created:
    - ev-ui/src/LegislativeInlineSummary.jsx
    - ev-ui/src/LegislativeRecord.jsx
  modified:
    - ev-ui/src/PoliticianProfile.jsx
    - ev-ui/src/index.js
    - ev-ui/package.json
decisions:
  - "Use slice(0,4) for year extraction — avoids timezone bug from new Date() constructor"
  - "LegislativeInlineSummary returns null for empty data — local politicians see unchanged profile"
  - "LegislativeRecord is headless — no routing, no data fetching, page wrapper handles those"
  - "Normalize position strings (replace underscore + title-case) before comparison for attendance calculation"
metrics:
  duration: "4 minutes"
  completed: "2026-03-03"
  tasks_completed: 2
  files_created: 2
  files_modified: 3
---

# Phase 59 Plan 01: ev-ui Legislative Components Summary

**One-liner:** Two new ev-ui components for legislative data — inline profile card summary and full record page content — published as @chrisandrewsedu/ev-ui@0.1.37.

## What Was Built

### LegislativeInlineSummary (`ev-ui/src/LegislativeInlineSummary.jsx`)

Inline card embedded inside PoliticianProfile between the top card and children slot. Guards on empty data — returns `null` when `recent_bills` and `recent_votes` are both empty or null, preserving the current profile experience for local politicians with no legislative data.

When data exists, renders:
- Stats row: attendance % (derived from non-absent/non-abstain vote ratio) and bills advanced count — only stats with real values render, no N/A placeholders
- Most recent action line: one-line summary of the most recent bill or vote by date, with ellipsis overflow
- Topic tags placeholder div (deferred — no visible content until mapping table ships)
- "View Full Legislative Record >" link pointing to `/politician/{id}/record`

Position normalization replaces underscores with spaces and title-cases before comparison ("not_voting" becomes "Not Voting").

### LegislativeRecord (`ev-ui/src/LegislativeRecord.jsx`)

Headless content component for the `/record` page. Three sections always render in fixed order:

**Section 1: Committees & Leadership**
- Leadership roles shown as evCoral badges first (prominent)
- Committee list with role badges (Chair=evCoral, Vice Chair=evTealLight, Ranking Member=evTeal, Ex Officio=textMuted, Member=borderMedium)
- Default 25 items, "Show all N items" expands
- Empty state: "Committee information is not available for this office."

**Section 2: Sponsored Legislation**
- Year dropdown filter using `slice(0,4)` for safe year extraction
- Each row: bill number (bold), title, status badge (color-coded), introduction date, Sponsored/Cosponsored label
- Status colors: Became Law=green, Vetoed=red, Passed House/Senate=teal, others=muted
- Default 25 items with year-aware Show All

**Section 3: Voting Record**
- Year dropdown filter from `vote_date`
- Each row: topic (bill title or vote question), date, position badge (Yea=green, Nay=red, Not Voting/Absent=muted, Abstain=yellow), outcome text, Source link
- Default 25 items with year-aware Show All

All styles use tokens.js — zero Tailwind classNames.

### PoliticianProfile modifications

- Added `import LegislativeInlineSummary from './LegislativeInlineSummary.jsx'`
- Two new optional props: `legislativeSummary` and `politicianId`
- Renders `<LegislativeInlineSummary summary={legislativeSummary} politicianId={politicianId} />` between closing topCard div and children slot
- Existing CommitteeTable rendering in infoCol unchanged — BallotReady committees remain

### Package publication

- `index.js` exports `LegislativeInlineSummary` and `LegislativeRecord`
- Version bumped 0.1.36 → 0.1.37
- Built with tsup (ESM + CJS bundles)
- Published to GitHub npm registry as `@chrisandrewsedu/ev-ui@0.1.37`

## Task Commits (in ev-ui repo)

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 34bd3ee | feat(59-01): create LegislativeInlineSummary and LegislativeRecord components |
| 2 | 3b40303 | feat(59-01): embed LegislativeInlineSummary in PoliticianProfile, export new components, publish 0.1.37 |

## Deviations from Plan

None — plan executed exactly as written.

## Auth Gates

None encountered.

## Self-Check: PASSED

- ev-ui/src/LegislativeInlineSummary.jsx: FOUND
- ev-ui/src/LegislativeRecord.jsx: FOUND
- ev-ui/src/PoliticianProfile.jsx: modified with LegislativeInlineSummary import and render
- ev-ui/src/index.js: exports both new components
- ev-ui/package.json: version 0.1.37
- Commits 34bd3ee and 3b40303: FOUND in ev-ui repo
- npm publish: succeeded (@chrisandrewsedu/ev-ui@0.1.37)
