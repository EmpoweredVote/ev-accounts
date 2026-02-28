---
phase: 08-public-candidate-pages
plan: 01
subsystem: database, api
tags: [supabase, postgres, typescript, rls-bypass, candidate-pages, jurisdiction]

# Dependency graph
requires:
  - phase: 05-empower-flow
    provides: empower.empowered_profiles table with is_active, candidate_page_slug, demoted_at
  - phase: 04-compass-routes
    provides: inform.compass_responses table with visibility, topic_id, value, write_in_text
  - phase: 03-alpha-enrollment
    provides: connect.connected_profiles with selected_topic_ids
provides:
  - SQL migration adding 9 new columns to empower.empowered_profiles (jurisdiction + photo)
  - candidateService.ts with getCandidateBySlug, getCandidatesByZip, getCandidateAnswers, splitLegalName
  - supabaseAdmin RLS-bypass pattern for inactive candidate retrieval
  - database.types.ts updated with new empowered_profiles columns
affects: [08-02-candidate-routes, future admin tools for jurisdiction data entry]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "supabaseAdmin in lib/ service file bypasses RLS for public pages that must return inactive rows"
    - "Single string literal for .select() — never string concatenation (TypeScript cannot infer column types from concatenated strings)"
    - "Explicit field whitelist for all response objects — DB rows never spread"
    - "600s ZIP cache keyed on zip string, 900s slug cache keyed on candidate_page_slug"

key-files:
  created:
    - supabase/migrations/20260228000025_phase8_candidate_pages.sql
    - backend/src/lib/candidateService.ts
  modified:
    - tests/integration/architecture.test.ts
    - backend/src/types/database.types.ts

key-decisions:
  - "SELECT string must be a single string literal (not concatenation) — Supabase TS client infers column types at compile time and cannot parse runtime-concatenated strings"
  - "database.types.ts updated manually to reflect new columns — supabase gen types not run (no live DB in CI)"
  - "Architecture test pre-existing failures (routes/auth.ts, compass.ts, connect.ts, social.ts) are NOT a regression from this plan — they pre-dated Phase 8"
  - "getCandidateAnswers has no cache — invertedTopicIds parameter is caller-specific, making per-key caching impractical"

patterns-established:
  - "candidateService.ts: add all Phase 8 public endpoint data access here — never import supabaseAdmin in routes/"
  - "splitLegalName: split on first space only — multi-word last names preserved in last_name field"

# Metrics
duration: 7min
completed: 2026-02-28
---

# Phase 8 Plan 1: Public Candidate Pages — Schema and Service Layer Summary

**SQL migration adds 9 jurisdiction + photo columns to empowered_profiles; candidateService.ts provides supabaseAdmin-based RLS-bypass lookups for inactive candidate slugs, ZIP discovery, and compass answer inversion**

## Performance

- **Duration:** 7 min
- **Started:** 2026-02-28T16:00:10Z
- **Completed:** 2026-02-28T16:07:12Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Schema migration adds 8 jurisdiction columns (representing_city/state/zip, district_type/id, government_name, chamber_name, chamber_name_formal) plus photo_origin_url — all nullable TEXT, all ADD COLUMN IF NOT EXISTS
- Partial ZIP index (is_active = true AND representing_zip IS NOT NULL) optimizes the Essentials endpoint
- Named UNIQUE constraint on candidate_page_slug in exception-safe DO block (idempotent over migration 006 inline UNIQUE)
- candidateService.ts exports 4 functions: getCandidateBySlug, getCandidatesByZip, getCandidateAnswers, splitLegalName
- getCandidateBySlug uses supabaseAdmin to bypass RLS and return demoted/inactive candidates — inactive rows are hidden from non-owners by RLS but must still render with demotion notice
- getCandidatesByZip enforces is_active = true — inactive candidates never appear in local discovery
- getCandidateAnswers applies inversion formula (6 - value) for caller-specified topics
- database.types.ts updated with 9 new empowered_profiles columns to satisfy TypeScript strict mode
- candidateService.ts whitelisted in architecture test allowedFiles array

## Task Commits

Each task was committed atomically:

1. **Task 1: Schema migration — jurisdiction fields, photo_origin_url, ZIP index, named UNIQUE constraint** - `c5af34f` (feat)
2. **Task 2: candidateService.ts — service layer + architecture test update** - `5e5b925` (feat)

## Files Created/Modified
- `supabase/migrations/20260228000025_phase8_candidate_pages.sql` — Adds 9 columns, ZIP partial index, named UNIQUE constraint with BEGIN/COMMIT wrapper
- `backend/src/lib/candidateService.ts` — Data access layer for all Phase 8 candidate endpoints (supabaseAdmin, cache, inversion)
- `tests/integration/architecture.test.ts` — candidateService.ts added to supabaseAdmin allowedFiles
- `backend/src/types/database.types.ts` — empowered_profiles Row/Insert/Update types extended with 9 new columns

## Decisions Made

- **SELECT string literal pattern**: Supabase's TypeScript client infers column types at compile time from the `.select()` argument as a string literal type. String concatenation (`'col1, ' + 'col2'`) widens to `string` and loses type inference, causing `GenericStringError` on every column access. All select calls use a single string literal on one line.
- **database.types.ts manual update**: The `supabase gen types` command requires a live Supabase connection. New columns are added manually to match the migration. This is the established pattern for this project.
- **getCandidateAnswers uncached**: The invertedTopicIds Set parameter is per-caller state. Caching would require a cache key derived from the Set contents, which is complex and error-prone. No cache is the correct choice.
- **Pre-existing architecture violations noted**: routes/auth.ts, compass.ts, connect.ts, and social.ts import supabaseAdmin directly and fail the architecture test. These pre-date Phase 8 and are not regressions from this plan. candidateService.ts does not appear in the violations list.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] TypeScript GenericStringError from concatenated SELECT strings**
- **Found during:** Task 2 verification (TypeScript compilation)
- **Issue:** `.select('col1, ' + 'col2, ' + 'col3')` string concatenation produced `string` type, causing Supabase client to infer `GenericStringError` for every column access — 26 TypeScript errors
- **Fix:** Rewrote all `.select()` calls as single string literals on one line
- **Files modified:** backend/src/lib/candidateService.ts
- **Verification:** `npx tsc --noEmit` passes with no errors
- **Committed in:** 5e5b925 (Task 2 commit)

**2. [Rule 3 - Blocking] database.types.ts missing new empowered_profiles columns**
- **Found during:** Task 2 verification (TypeScript compilation)
- **Issue:** TypeScript strict mode failed because database.types.ts Row/Insert/Update types for empowered_profiles did not include the 9 columns added by the migration
- **Fix:** Added all 9 columns (representing_city/state/zip, district_type/id, government_name, chamber_name, chamber_name_formal, photo_origin_url) to Row, Insert, and Update shapes in database.types.ts
- **Files modified:** backend/src/types/database.types.ts
- **Verification:** `npx tsc --noEmit` passes with no errors
- **Committed in:** 5e5b925 (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)
**Impact on plan:** Both auto-fixes were required for TypeScript compilation. No scope creep — all fixes are mechanical corrections to enable the planned work.

## Issues Encountered
- Architecture test pre-existing failures: routes/auth.ts, compass.ts, connect.ts, and social.ts fail the `no file in src/routes/ imports supabaseAdmin` assertion. These files directly import supabaseAdmin (not just in comments). This is a pre-existing architectural debt from earlier phases, not a regression from Phase 8.

## Next Phase Readiness
- Schema migration ready for `supabase db push`
- candidateService.ts ready for Phase 8 route layer (08-02)
- Routes can import getCandidateBySlug, getCandidatesByZip, getCandidateAnswers, splitLegalName directly
- No blockers for 08-02

---
*Phase: 08-public-candidate-pages*
*Completed: 2026-02-28*
