---
phase: 20-location-endpoints-validation
plan: 04
subsystem: testing
tags: [vitest, static-analysis, architecture-test, coordinates, privacy, typescript]

# Dependency graph
requires:
  - phase: 20-02
    provides: POST /api/connect/set-location route — lat/lng only passed to adminRpc, never to res.json()
  - phase: 20-03
    provides: GET /me/jurisdiction route — jurisdiction keys never include lat/lng
provides:
  - Permanent regression guard: any future route file that introduces coordinate leakage fails CI immediately
  - Static analysis test scanning 15 route files with 4 forbidden patterns (61 checks total)
affects: [all future phases that add route files — will be automatically scanned]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Architecture tests via static file scan: fs.readdirSync + fs.readFileSync on src/routes/*.ts"
    - "Negative lookahead to exclude TypeScript type annotations from object-key pattern matches"
    - "tests/architecture/ directory for non-integration, non-unit static analysis guards"

key-files:
  created:
    - tests/architecture/coordinateLeakage.test.ts
  modified: []

key-decisions:
  - "Object-key pattern \\blat\\s*: uses negative lookahead excluding TS type names (number|string|boolean|...) followed by [,;)>\\s] — avoids false positives on `lat: number` type annotations while catching `lat: someValue` response shapes"
  - "Test file lives in tests/architecture/ (project root), not backend/tests/ — vitest.config.ts include pattern is ../tests/** relative to backend/"
  - "Multiline res.json() regex from plan discarded — too broad, would false-positive across function bodies; replaced with \\blat\\s*: object-key pattern which is more precise and catches the actual leakage form"

patterns-established:
  - "Architecture test pattern: place static analysis guards in tests/architecture/, named {concern}.test.ts"
  - "Coordinate privacy enforcement: two layers — (1) route code never assigns lat/lng to response objects, (2) this test catches violations statically before merge"

# Metrics
duration: 12min
completed: 2026-03-13
---

# Phase 20 Plan 04: Coordinate Leakage Architecture Test Summary

**Vitest static analysis test scanning all 15 route files for encrypted_lat/encrypted_lng column refs and lat:/lng: object keys, with TypeScript-aware negative lookahead — 61 checks, 0 violations**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-03-13T17:42:00Z
- **Completed:** 2026-03-13T17:54:00Z
- **Tasks:** 1
- **Files modified:** 1 created

## Accomplishments

- Created `tests/architecture/coordinateLeakage.test.ts` with 4 forbidden pattern checks across all 15 `backend/src/routes/*.ts` files
- Patterns detect `encrypted_lat`/`encrypted_lng` column references (hard prohibition) and `lat:`/`lng:` as object value keys (coordinate leakage in response shapes)
- Negative lookahead excludes TypeScript type annotations (`lat: number`, `lng: number`) to avoid false positives on `connect.ts` function parameter declarations and variable type annotations
- 61 total checks pass with 0 violations

## Task Commits

1. **Task 1: coordinateLeakage.test.ts — static analysis architecture test** - `f8f70bf` (test)

## Files Created/Modified

- `tests/architecture/coordinateLeakage.test.ts` - Static analysis Vitest test; scans `backend/src/routes/*.ts` for 4 forbidden coordinate patterns; 61 checks across 15 files

## Decisions Made

- **Test location is `tests/architecture/`, not `backend/tests/`** — vitest.config.ts `include` pattern is `../tests/**` relative to `backend/`, resolving to project root `tests/`. Placing the file in `backend/tests/` caused it to be silently uncollected.
- **Multiline `res.json()` regex discarded** — The plan's suggested `res\.json\([\s\S]*?\blat\b[\s\S]*?\)` pattern with lazy quantifiers would false-positive: a `res.json()` call early in the file followed by `lat` anywhere in the file body could match across hundreds of lines. Replaced with `\blat\s*:` object-key pattern which precisely targets the leakage form.
- **Negative lookahead character class includes `;`** — `let lat: number;` (variable declaration) ends with `;`. The initial lookahead `[,\s\)>]` missed this, causing a false positive on connect.ts. Added `;` to the character class: `[,\s\);>]`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Multiline res.json() regex replaced due to false positive risk**
- **Found during:** Task 1 (pattern design and testing)
- **Issue:** Plan's `res\.json\([\s\S]*?\blat\b[\s\S]*?\)` regex would match from any `res.json(` call to any subsequent `lat` in the file, causing false positives in connect.ts which has both `res.json()` calls and `lat` variable declarations
- **Fix:** Replaced with `\blat\s*:` object-key pattern using negative lookahead to exclude TypeScript type annotations; catches `{ lat: value }` leakage forms without spanning irrelevant file content
- **Files modified:** tests/architecture/coordinateLeakage.test.ts
- **Verification:** `connect.ts: must not contain "lat as object key"` passes; pattern correctly ignores `lat: number` and `let lat: number;` type annotations
- **Committed in:** f8f70bf (task commit)

**2. [Rule 1 - Bug] Negative lookahead extended to include `;` terminator**
- **Found during:** Task 1 (test run against connect.ts)
- **Issue:** `let lat: number;` matched the `\blat\s*:` pattern because `;` was not in the negative lookahead character class `[,\s\)>]`
- **Fix:** Added `;` to character class: `[,\s\);>]`
- **Files modified:** tests/architecture/coordinateLeakage.test.ts
- **Verification:** connect.ts passes all 4 forbidden pattern checks
- **Committed in:** f8f70bf (task commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 - bug fixes to pattern precision)
**Impact on plan:** Pattern refinements necessary for a test that passes cleanly — overly broad patterns produce false positives that would block CI on valid code. Final patterns are more precise than the plan's proposal with no reduction in detection capability.

## Issues Encountered

- **Wrong test directory** — Initially created file in `backend/tests/architecture/` but vitest.config.ts scans `../tests/**` from `backend/`, which is the project root `tests/`. File was silently uncollected. Fixed by creating at `tests/architecture/coordinateLeakage.test.ts` and removing the backend/tests/ directory.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 20 is complete. All 4 plans done:
- 20-01: geocodingService.ts (address → coordinates, privacy contract)
- 20-02: POST /api/connect/set-location (PO box guard, coverage filter, upsert + resolve RPCs)
- 20-03: GET /api/connect/me/jurisdiction (consent gate, jurisdiction response)
- 20-04: Coordinate leakage architecture test (permanent regression guard)

The location feature is complete. Any future developer who accidentally includes `encrypted_lat`, `encrypted_lng`, or `lat:`/`lng:` as response object keys in a route file will get a failing test before merge.

---
*Phase: 20-location-endpoints-validation*
*Completed: 2026-03-13*
