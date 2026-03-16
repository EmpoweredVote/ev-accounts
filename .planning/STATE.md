---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: planning
stopped_at: Phase 90 context gathered
last_updated: "2026-03-16T01:04:32.915Z"
last_activity: "2026-03-15 - Completed quick task 15: Update compass stance language — 21 changes across 10 topics"
progress:
  total_phases: 7
  completed_phases: 5
  total_plans: 10
  completed_plans: 10
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-14)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** Phase 86 — Chrome Cleanup + Store Migration

## Current Position

Phase: 86 of 91 (Chrome Cleanup + Store Migration)
Plan: 0 of TBD in current phase
Status: Ready to plan
Last activity: 2026-03-15 - Completed quick task 15: Update compass stance language — 21 changes across 10 topics

Progress: [░░░░░░░░░░] 0% (v2026.3.6 phases)

## Performance Metrics

**Velocity (v2026.3.5):** 3 phases, 5 plans, 1 day
**Velocity (v2026.3.4):** 6 phases, 13 plans, 1 day
**Velocity (v2026.3.3):** 5 phases, 6 plans, 2 days

*Updated after each plan completion*

## Accumulated Context

### Decisions

- [v2026.3.6]: Zustand store version must be bumped to v2 with clean-reset migrate as the very first commit — old `phase: 'ranking'` in localStorage will silently break the app
- [v2026.3.6]: Practice state lives entirely outside `issueProgress` — no contamination of verdict POST payloads; skip action must be atomic
- [v2026.3.6]: CoachMark TypeScript-ported from CompassV2 directly into EV-readrank this milestone — not published to ev-ui (single consumer, cross-repo overhead unjustified)
- [v2026.3.6]: Location filtering is client-side only — `POST /essentials/politicians/search` + client filter; no backend changes required
- [Phase 86-chrome-cleanup-store-migration]: migrate() returns hardcoded initial state regardless of version — guarantees returning users with old localStorage land on hub cleanly
- [Phase 86-chrome-cleanup-store-migration]: nextQuote caps index at quotesToEvaluate.length rather than auto-transitioning to 'ranking' — phase transitions delegated to EvaluationPhase.handleComplete
- [Phase 86-chrome-cleanup-store-migration]: matchingAlgorithm uses rank-position scoring only: rank 1 = N pts, rank N = 1 pt, max = N*(N+1)/2 (no badge bonuses)
- [Phase 86-chrome-cleanup-store-migration]: EvaluationPhase.handleComplete goes directly to 'results' unconditionally — device-type branching removed along with 'ranking' phase
- [Phase 86-chrome-cleanup-store-migration]: CandidateAlignmentPage and PhaseNavigation auto-fixed — they had badgeAssignments and flat field reads not in the plan's files_modified but were blocking TypeScript build
- [Phase 87-unified-evaluatephase-inlinerankpanel]: agreedQuotes field removed entirely — rankedQuotes is the single source of truth for agreed quotes with positional ranks
- [Phase 87-unified-evaluatephase-inlinerankpanel]: AgreedQuotesSidebar type-fixed in-place (reorderRankedQuotes + RankedQuote) for TypeScript build; rename to RankedQuotesSidebar deferred to Plan 02
- [Phase 87-unified-evaluatephase-inlinerankpanel]: AgreedQuotesSidebar filename kept, exports RankedListSidebar as primary + alias — minimizes import churn
- [Phase 87-unified-evaluatephase-inlinerankpanel]: QuickConfirmation removed entirely — handleComplete goes straight to setPhase('results'); live sidebar ranking makes confirmation redundant (per user feedback)
- [Phase 87-unified-evaluatephase-inlinerankpanel]: showInlinePanel guards require 2+ ranked quotes to avoid double-panel on first agree
- [Phase 87-unified-evaluatephase-inlinerankpanel]: Mobile InlineRankPanel rendered as fixed bottom sheet with backdrop — ensures visibility regardless of viewport height
- [Phase 87-unified-evaluatephase-inlinerankpanel]: Desktop rank gate uses blur filter + pointer-events:none on next card + inline dismiss prompt when pendingRankQuoteId set and 2+ ranked
- [Phase 87-unified-evaluatephase-inlinerankpanel]: Quote text in ranking UI (sidebar cards, inline panel) uses Manrope normal — Fraunces italic reserved for decorative/display headings only
- [Phase 87.1-head-to-head-matchup-ranking]: Store version bumped to 4 — returning users with v3 localStorage are wiped to hub cleanly
- [Phase 87.1-head-to-head-matchup-ranking]: completedMatchupPairs stored as string[] not Set — Zustand/localStorage cannot serialize Set objects
- [Phase 87.1-head-to-head-matchup-ranking]: activeMatchupPair set eagerly in agreeWithQuote — UI can begin showing matchup prompt immediately after 2nd agree
- [Phase Phase 87.1-head-to-head-matchup-ranking]: MatchCard uses raw CSS transform for 3D tilt (not Framer Motion) — better performance for continuous mouse move tracking
- [Phase Phase 87.1-head-to-head-matchup-ranking]: drag-rank gate (blur overlay + pending bottom sheet) removed entirely — matchup flow replaces the ranking UX
- [Phase Phase 87.1-head-to-head-matchup-ranking]: Results button gated on activeMatchupPair === null to ensure all matchups complete before results are shown
- [Phase 88-practice-round]: Store v5 migration uses version > 0 check to set practiceCompleted: true for existing users, false for brand-new users
- [Phase 88-practice-round]: PracticeProgress stored at top-level store (not inside issueProgress) to prevent practice data from polluting real issue verdict POST payloads
- [Phase 88-practice-round]: QuoteCard onAgree/onDisagree use ?? fallback to store actions — backward-compatible, EvaluationPhase passes zero new props
- [Phase 88-practice-round]: PracticeRound reads from practiceProgress directly (not getCurrentIssueProgress) — keeps practice isolated from real issue data
- [Phase 88-practice-round]: Results sub-phase tracked via local showResults state (not store phase) — completePractice() sets phase to 'hub' directly, never to 'results'
- [Phase 88-practice-round]: PhaseContainer auto-redirect calls startPractice() not setPhase('practice') — startPractice initializes practiceProgress; bare setPhase would leave it null
- [Phase 88-practice-round]: Practice splash added (user-requested): leads with Read & Rank feature value prop before pizza practice warm-up
- [Phase 88-practice-round]: Character emoji avatars added (user-requested): emoji + avatarColor in PRACTICE_CHARACTERS; disagreed cards desaturated
- [Phase 89-coach-marks]: useCoachMark hook intentionally NOT ported from CompassV2 — Zustand store handles persistence (locked decision from phase context)
- [Phase 89-coach-marks]: CoachMark stays in EV-readrank/src/components/, not published to ev-ui — single consumer, cross-repo overhead unjustified
- [Phase 89-coach-marks]: Tour state (tourStep) is local to EvaluationPhase not the store — ephemeral per-session, only coachMarksCompleted needs Zustand persistence
- [Phase 89-coach-marks]: Step 1 uses allowSpotlightInteraction=true so users can swipe the card through the spotlight — proves the interaction works
- [Phase 89-coach-marks]: swipeAreaRef wraps QuoteCard + ActionButtons div so step 1 spotlight covers the full interactive zone including agree/disagree buttons
- [Phase 89-coach-marks]: tourStep included in handleButtonSwipe useCallback dependency array to prevent stale closure silently skipping tour advancement on button press

### Pending Todos

- 12 politicians have no Read & Rank quotes (carried from v1.8)

### Blockers/Concerns

- [Phase 90]: Confirm `POST /essentials/politicians/search` CORS allows `readrank.empowered.vote` before Phase 90 ships
- [Phase 90]: Add `VITE_GOOGLE_MAPS_API_KEY` to Cloudflare Pages env for EV-readrank before deploying location filter
- [Phase 89]: Verify CoachMark is still absent from ev-ui exports before manual port — if published, skip the port

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 11 | Fix Monroe County Council data: Liz Feitl at-large seat and missing district members | 2026-03-13 | 75045fd | [11-fix-monroe-county-council-data-liz-feitl](./quick/11-fix-monroe-county-council-data-liz-feitl/) |
| 12 | Extract treasury-tracker, empowered-badges, fallacy-finders to standalone GitHub repos; clean EV-prototypes | 2026-03-13 | aa5202c | [12-move-treasury-tracker-empowered-badges-a](./quick/12-move-treasury-tracker-empowered-badges-a/) |
| 13 | Normalize congressional district labels: House "District N", Senate full state name only | 2026-03-14 | 33292c6 | [13-standardize-congressional-district-names](./quick/13-standardize-congressional-district-names/) |
| 14 | Fix Monroe County Circuit Court judge names and relabel Seat N → Division N across districts, chambers, offices | 2026-03-14 | dd34707 | [14-fix-monroe-county-circuit-court-judge-na](./quick/14-fix-monroe-county-circuit-court-judge-na/) |
| 15 | Update compass stance language — 21 changes across 10 topics | 2026-03-15 | c46c1ff | [15-update-compass-stance-language-based-on-](./quick/15-update-compass-stance-language-based-on-/) |
| Phase 86-chrome-cleanup-store-migration P01 | 2 | 2 tasks | 2 files |
| Phase 86-chrome-cleanup-store-migration P02 | 4 | 2 tasks | 8 files |
| Phase 87-unified-evaluatephase-inlinerankpanel P01 | 2 | 2 tasks | 8 files |
| Phase 87-unified-evaluatephase-inlinerankpanel P02 | 3 | 3 tasks | 5 files |
| Phase 87.1-head-to-head-matchup-ranking P01 | 2 | 2 tasks | 2 files |
| Phase 88-practice-round P01 | 3 | 2 tasks | 3 files |
| Phase 88 P02 | 3 | 2 tasks | 3 files |
| Phase 88-practice-round P02 | 75 | 3 tasks | 4 files |
| Phase 89-coach-marks P01 | 3 | 2 tasks | 2 files |
| Phase 89-coach-marks P02 | 3 | 2 tasks | 5 files |

### Roadmap Evolution

- Phase 87.1 inserted after Phase 87: Head-to-Head Matchup Ranking — replace drag-to-rank with pairwise comparison flow (URGENT)
- Phase 90 scope expanded: fold real Compass topic data with 2+ quote filtering into location-based filtering phase

### Tech Debt Carried Forward

- Dead `ballotready/` package preserved (from v1.5)
- Orphaned `checkCacheStatus` in essentials `api.jsx` (from v1.5)
- 5 district-election cities treated as at-large (from v1.6)
- `fetchPoliticiansOnce` and `fetchPoliticiansProgressive` deprecated but not deleted (from v1.9)
- `leg_data_fetched_at` column unused (from v2026.3)
- Topic tags placeholder div in LegislativeInlineSummary (from v2026.3)
- ev-ui ships no .d.ts files — profileMenu prop uses spread cast in ReadRank (from v2026.3.5)
- Orphaned AuthIndicator.jsx in essentials (from v2026.3.5)

## Session Continuity

Last session: 2026-03-16T01:04:32.911Z
Stopped at: Phase 90 context gathered
Resume file: .planning/phases/90-location-based-filtering/90-CONTEXT.md
