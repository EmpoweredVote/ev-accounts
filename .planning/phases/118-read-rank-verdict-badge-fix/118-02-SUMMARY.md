---
phase: 118-read-rank-verdict-badge-fix
plan: 02
status: complete
started: 2026-04-15
completed: 2026-04-15
---

# Plan 118-02 Summary: Apply Minimal Fix

## What Was Built

Applied minimal fixes for two compounding bugs that prevented verdict badges from rendering on politician profile pages.

**Bug A fix (ev-accounts commit e71984d):**
- Changed `GET /essentials/quotes` to return `issue: topic_key` (slug) instead of `issue: topic_id` (UUID)
- Added `topic_key` to compass topics API response (`getCompassTopics` and `getCompassCategories`)
- Updated `issues[]` deduplication in quotes endpoint to key by `topic_key` for consistency with Read & Rank
- Added `topic_key` to Supabase generated types (`database.types.ts`)

**Bug B fix (essentials commit f444780):**
- Changed `fetchUserVerdicts()` to map `item.supported === true ? 'agreed' : 'disagreed'` instead of reading the nonexistent `item.verdict` field

## Key Files

### Created
- None

### Modified
- `ev-accounts/backend/src/lib/compassService.ts` — added `topic_key` to topics select queries
- `ev-accounts/backend/src/routes/essentials.ts` — quotes endpoint returns `topic_key` as `issue`
- `ev-accounts/backend/src/types/database.types.ts` — added `topic_key` to compass_topics type
- `essentials/src/lib/compass.js` — fixed verdict shape mapping in `fetchUserVerdicts()`

## Verification

- ev-accounts `npm run typecheck` passes clean
- essentials `npm run build` passes clean
- Both repos pushed to remote; Render auto-deploy triggered

## Deviations

- The diagnosis identified Bug A's root cause file as `ev-ui/src/StanceAccordion.jsx`, but the fix was applied on the backend side (Option A1+A2 from diagnosis) rather than changing ev-ui. This avoids triggering the auto-bump pipeline across 4 consumers for a backend-only data fix.
- Also fixed the `issues[]` array in the quotes endpoint to use `topic_key` as the key — this was not in the original diagnosis but is required for Read & Rank's `q.issue === issue.id` matching to continue working.

## Self-Check: PASSED

- [x] Fix commits exist in both repos
- [x] Typecheck/build pass
- [x] Both repos pushed, Render deploying
- [x] 118-DIAGNOSIS.md updated with fix commit SHAs
