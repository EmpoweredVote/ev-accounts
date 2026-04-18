---
phase: 118-read-rank-verdict-badge-fix
plan: 01
subsystem: diagnosis
tags: [compass, read-rank, verdict-badges, diagnosis, essentials, ev-ui]

one-liner: "Two compounding bugs block all verdict badges: quote-to-topic UUID/slug mismatch in StanceAccordion + fetchUserVerdicts reads item.verdict but backend returns item.supported"

# Dependency graph
requires: []
provides:
  - 118-DIAGNOSIS.md with H1-H5 hypothesis results and root cause identification
affects:
  - 118-02 (fix plan — root cause layer drives file scope)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Hypothesis-first investigation: test likely causes in priority order before full bisection"
    - "Production API interrogation via curl as substitute for browser session when Chrome MCP unavailable"

key-files:
  created:
    - .planning/phases/118-read-rank-verdict-badge-fix/118-DIAGNOSIS.md
  modified: []

key-decisions:
  - "Canonical RR-01 surface is politician URL (72dd5219) — candidate UUID (7e768cda) returns NOT_FOUND from production API"
  - "Bug A (quote filter) blocks ALL badge rendering (guest + authed) — fix must land in either essentials/quotes endpoint or StanceAccordion"
  - "Bug B (verdict shape) blocks authed-only badge rendering — fix is one-line in fetchUserVerdicts: item.supported === true ? 'agreed' : 'disagreed'"
  - "Recommended fix for Bug A: change GET /essentials/quotes to return issue as topic_key slug instead of topic_id UUID"

# Metrics
duration_minutes: 35
tasks_completed: 2
tasks_total: 2
files_created: 1
files_modified: 0
completed_date: "2026-04-15"
---

# Phase 118 Plan 01: Verdict Badge Diagnosis Summary

## What Was Done

Diagnosed the verdict badge regression by running the hypothesis-first investigation (H1-H5) from 118-CONTEXT.md D-05/D-06. Used `curl` against production API, code reading, npm version checks, and git history analysis as a substitute for Chrome MCP tools (unavailable in parallel worktree).

## Hypothesis Results

| Hypothesis | Result | Evidence |
|-----------|--------|---------|
| H1 — ev-ui version mismatch | FAIL | ev-ui 0.4.0 installed in essentials has `verdictsByQuote` render branch (3 occurrences in dist) |
| H2 — CompassCard prop wiring drift | FAIL | Both call sites (:321 and :415) pass `verdictsByQuote={verdicts}` correctly |
| H3 — Fetch chain returns empty | PASS (authed) | `fetchUserVerdicts` reads `item.verdict` but backend returns `item.supported: boolean` — map becomes `{ [quote_id]: undefined }` |
| H4 — Backend /compass/verdicts response shape | PASS | Quotes endpoint returns `issue = topic UUID` but StanceAccordion compares to `topic.topic_key` (slug) — never matches, `topicQuotes` always `[]` |
| H5 — CSS/display regression | FAIL | Badges use conditional JSX render (not CSS hide) — they never mount due to H3/H4 bugs |

## Root Cause Declared

**Root cause layer:** `essentials-fetch` + `essentials-wiring`

Two compounding bugs, both required to fix:

**Bug A — Quote-to-topic matching failure (blocks ALL badge rendering)**
- `ev-accounts/backend/src/routes/essentials.ts` line 221: `issue: r.topic_id` (UUID)
- `ev-ui/src/StanceAccordion.jsx` lines 202-208: compares `q.issue === topic.topic_key` then `q.issue === topic.short_title`
- Compass topics API (`GET /api/compass/topics`) does not return `topic_key` — so fallback comparison runs: UUID vs "Abortion" — always false
- Result: `topicQuotes = []` for every expanded row → no quotes render → no verdict badges possible

**Bug B — Authed verdict shape mismatch (blocks authed badge rendering)**
- `essentials/src/lib/compass.js` line 269: reads `item.verdict`
- `ev-accounts/backend/src/lib/compassService.ts` lines 521-530: returns `{ quote_id, supported: boolean, ... }`
- `item.verdict` is `undefined` → `verdictsByQuote[quote_id] = undefined` → badge conditional (`verdict === 'agreed'`) never true

**One-line fix summary:**
1. Change `/essentials/quotes` to return `issue: topic_key` (slug) so StanceAccordion's primary comparison matches.
2. Change `fetchUserVerdicts` to map `item.supported === true ? 'agreed' : 'disagreed'`.

**Commit that introduced it:**
- Bug A: Design assumption gap between phase 50 (quotes endpoint built for Read & Rank with UUID keys) and phase 81 (StanceAccordion written expecting topic_key slug). Never validated end-to-end.
- Bug B: Phase 79 migrated backend verdicts schema from `verdict: string` to `supported: boolean`. Frontend `fetchUserVerdicts` client was not updated.

## Canonical Pierce RR-01 Surface

`https://essentials.empowered.vote/politician/72dd5219-490f-48bb-986e-183a6098d602`

Matt Pierce (Indiana House D-61) — 13 quotes in production, 10 compass topic answers.

The candidate UUID (`7e768cda`) returns NOT_FOUND from production API — not a valid test surface.

## Deviations from Plan

### Method Adaptation

**[Rule 3 - Blocking] Chrome MCP unavailable in parallel worktree**
- **Found during:** Task 1
- **Issue:** Chrome MCP tools (`mcp__claude-in-chrome__*`) are not available in the worktree execution environment. Browser-based DOM inspection and console execution were not possible.
- **Fix:** Substituted with `curl` against production API endpoints, direct code reading of all source files, npm version checks via `npm view`, and git history analysis. All hypothesis conclusions are grounded in code and API evidence — no speculative findings.
- **Impact:** Task 1 "Reproduction" section documents API-level findings rather than DOM/network tab captures. The evidence is equivalent in diagnostic value.

## Known Stubs

None. This is a diagnosis-only plan — no code was modified.

## Threat Flags

None. This plan writes only to `.planning/` (diagnosis docs). No code mutations, no new network surfaces introduced.

## Self-Check

### Files Created
- `.planning/phases/118-read-rank-verdict-badge-fix/118-DIAGNOSIS.md` — FOUND
- `.planning/phases/118-read-rank-verdict-badge-fix/118-01-SUMMARY.md` — FOUND

### Commits
- `057fdc0` — docs(118-01): diagnose verdict badge regression — FOUND

## Self-Check: PASSED
