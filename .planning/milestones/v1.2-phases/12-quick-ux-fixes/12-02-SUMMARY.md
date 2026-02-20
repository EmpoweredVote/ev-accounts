---
phase: 12-quick-ux-fixes
plan: 02
subsystem: database
tags: [postgres, supabase, compass, sql, topic-titles]

# Dependency graph
requires:
  - phase: 12-quick-ux-fixes
    plan: 01
    provides: question_text field on Topic model; getQuestionText helper reads question_text first
provides:
  - 7 compass topics with descriptive question_text values approved by user
  - short_name column added to compass.topics table in Supabase
  - All vague topic titles replaced with natural "Where do you stand on ___?" phrasing
affects:
  - CompassV2 Library cards (getQuestionText reads question_text → now shows rewritten values)
  - CompassV2 Quiz question headings
  - CompassV2 LibraryDrawer, ComparePanel topic framing

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "question_text column stores approved display phrasing; title column remains as internal identifier"
    - "short_name column holds radar chart label override, currently unpopulated (frontend falls back to short_title)"

key-files:
  created: []
  modified: []

key-decisions:
  - "question_text updated directly in database via SQL — no code changes needed since getQuestionText() already reads this field first"
  - "short_name column added via ALTER TABLE (GORM AutoMigrate hadn't run against Supabase DB yet)"
  - "Topic titles left unchanged in title column — only question_text updated per plan spec (display override, not rename)"
  - "Housing topic question_text set to match existing title 'Affordable Housing and Homelessness' — already descriptive, just needed question_text populated"

patterns-established:
  - "Direct SQL migration against Supabase for data-only changes with no code side-effects"

requirements-completed: [QFRM-02]

# Metrics
duration: 2min
completed: 2026-02-19
---

# Phase 12 Plan 02: Topic Title Rewrites Summary

**7 vague compass topic titles rewritten to descriptive action phrases in the database via question_text field, with short_name column added for future radar chart label overrides**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-02-19T03:05:18Z
- **Completed:** 2026-02-19T03:07:02Z
- **Tasks:** 3 (including checkpoint)
- **Files modified:** 0 (database-only changes)

## Accomplishments

- Applied 7 user-approved question_text rewrites to compass.topics in Supabase via direct SQL
- Added short_name column to compass.topics (ALTER TABLE — GORM AutoMigrate had not yet run against the Supabase instance)
- All 7 topics now read naturally in "Where do you stand on ___?" framing via the getQuestionText() helper (which already prioritizes question_text from Plan 01)

## Task Commits

This plan made no code file changes — all work was direct database SQL. No git commits apply.

Note: The database migration was applied interactively during execution. No migration script file was generated because the changes are already persisted in Supabase.

## Before / After: Approved Rewrites

| Topic (title) | short_title | Previous question_text | New question_text |
|---|---|---|---|
| Ukraine - Russia Conflict | Ukraine Support | (empty) | U.S. Support for Ukraine |
| Medicare / Medicaid | Medicare/aid | (empty) | Medicare and Medicaid |
| Deportation of Immigrants | Deportation | (empty) | Immigration Enforcement and Deportation |
| Artificial Intelligence Regulation | AI Regulation | (empty) | Regulating Artificial Intelligence |
| Affordable Housing and Homelessness | Housing | (empty) | Affordable Housing and Homelessness |
| Misinformation and the Role of Algorithms in Democracy | Misinformation | (empty) | Combating Online Misinformation |
| State Redistricting and Gerrymandering | Redistricting | (empty) | Gerrymandering and Redistricting |

## Files Created/Modified

None — all changes applied directly to Supabase via SQL.

## Decisions Made

- Updated question_text only, not the title column — consistent with plan spec that question_text is the display override layer
- Added short_name column via ALTER TABLE since AutoMigrate had not been run yet (Plan 01 added it to the Go model but the server hadn't been restarted against this Supabase instance)
- Housing topic got question_text populated to match its title — it was already well-named, but needed question_text set so the field is non-empty for consistency

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added short_name column via ALTER TABLE before applying updates**
- **Found during:** Task 2 (Apply approved topic title rewrites to database)
- **Issue:** The short_name column didn't exist in Supabase yet — GORM AutoMigrate from Plan 01 hadn't run (server not restarted). Queries would fail without the column existing.
- **Fix:** Added `ALTER TABLE compass.topics ADD COLUMN IF NOT EXISTS short_name text;` before the UPDATE statements
- **Files modified:** None (database DDL)
- **Verification:** Column confirmed present via `\d compass.topics`
- **Committed in:** N/A (database-only)

---

**Total deviations:** 1 auto-fixed (blocking — missing column)
**Impact on plan:** Minor. Added one DDL statement to the SQL block. No scope creep.

## Issues Encountered

- DATABASE_URL contains a `@` character in the password which breaks standard URL parsing — resolved by URL-encoding the `@` as `%40` when passing to psql

## User Setup Required

None — changes are already applied to Supabase. No environment variable changes required.

## Next Phase Readiness

- All 7 topic rewrites are live in Supabase. CompassV2 Library cards and Quiz headings will now show the descriptive phrasing via getQuestionText()
- short_name column exists but is unpopulated — admin can use the TopicEditor "Radar Chart Label" input (from Plan 01) to set per-topic radar labels as needed
- Phase 12 is complete — both plans executed

## Self-Check: PASSED

- Database verified: 21 topics unchanged (no corruption)
- All 7 question_text values confirmed via SELECT after UPDATE
- short_name column confirmed present via \d compass.topics
- .planning/phases/12-quick-ux-fixes/12-02-SUMMARY.md — FOUND (this file)

---
*Phase: 12-quick-ux-fixes*
*Completed: 2026-02-19*
