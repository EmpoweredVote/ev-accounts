---
phase: 29-validation-polish-key-removal
plan: 01
subsystem: api
tags: [go, provider, cleanup, config, ballotready]

# Dependency graph
requires:
  - phase: 27-cache-only-candidates-warmer-cleanup
    provides: Removed BallotReady warmer goroutines, deprecated bulk-import CLI
provides:
  - BallotReady cannot be accidentally re-enabled without deliberate code changes to provider/
  - provider/config.go cleaned of ProviderBallotReady, BallotReadyKey, BallotReadyEndpoint
  - provider/provider.go cleaned of ErrMissingBallotReadyKey
  - .env.local cleaned of BALLOTREADY_KEY and POLITICIAN_PROVIDER=ballotready
affects: [any phase adding a new politician data provider]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Dead code isolation: remove provider/ config hooks so a dead package cannot be accidentally re-enabled"

key-files:
  created: []
  modified:
    - EV-Backend/internal/essentials/provider/config.go
    - EV-Backend/internal/essentials/provider/provider.go
    - EV-Backend/internal/essentials/admin.go
    - EV-Backend/cmd/bulk-import/main.go
    - EV-Backend/.env.local (local only, not committed)

key-decisions:
  - "provider/config.go switch statement simplified to only handle default case after ballotready branch removed — no ProviderBallotReady constant remains"
  - "ballotready/ package intentionally left as dead code (failing to compile) — confirms it has no active imports from main codebase"
  - ".env.local POLITICIAN_PROVIDER and BALLOTREADY_KEY removed; server defaults to cicero provider when POLITICIAN_PROVIDER is unset"

patterns-established:
  - "Dead package isolation: remove the configuration hooks (provider type constants, config fields, validation branches) so dead packages cannot be accidentally re-enabled"

requirements-completed: [CLEAN-01, CLEAN-02]

# Metrics
duration: 8min
completed: 2026-02-22
---

# Phase 29 Plan 01: Validation Polish Key Removal Summary

**BallotReady provider config removed from provider/ package; cicero-only config enforced with zero active BallotReady references in Go source files**

## Performance

- **Duration:** 8 min
- **Started:** 2026-02-22T00:00:00Z
- **Completed:** 2026-02-22T00:08:00Z
- **Tasks:** 2
- **Files modified:** 5 (4 in git, 1 local-only)

## Accomplishments
- Removed ProviderBallotReady constant, BallotReadyKey/Endpoint struct fields, DefaultBallotReadyEndpoint, case "ballotready" branches from LoadFromEnv() and Validate() in provider/config.go
- Removed ErrMissingBallotReadyKey from provider/provider.go
- Updated admin.go log string and cmd/bulk-import/main.go deprecation message to remove BallotReady references
- Cleaned .env.local of BALLOTREADY_KEY and POLITICIAN_PROVIDER=ballotready (local file only)
- Confirmed ballotready/ dead package now fails to compile — proves it has no active imports
- All 6 plan verifications pass: audit returns zero active references, build succeeds, config clean, yaml/json/toml clean

## Task Commits

Each task was committed atomically:

1. **Task 1: Run codebase audit and clean provider/ package of BallotReady references** - `32c4ded` (chore)
2. **Task 2: Remove BALLOTREADY_KEY and POLITICIAN_PROVIDER from .env.local** - local file edit only, not committed (file is gitignored)

**Plan metadata:** (see final commit below)

## Files Created/Modified
- `EV-Backend/internal/essentials/provider/config.go` - Removed ProviderBallotReady, BallotReadyKey, BallotReadyEndpoint, DefaultBallotReadyEndpoint, case "ballotready" in LoadFromEnv() and Validate()
- `EV-Backend/internal/essentials/provider/provider.go` - Removed ErrMissingBallotReadyKey, updated OfficialProvider comment
- `EV-Backend/internal/essentials/admin.go` - Updated log string to remove "BallotReady warmer" reference
- `EV-Backend/cmd/bulk-import/main.go` - Updated deprecation message to generic text without BallotReady mention
- `EV-Backend/.env.local` - Removed POLITICIAN_PROVIDER=ballotready and BALLOTREADY_KEY lines (local only, gitignored)

## Decisions Made
- provider/config.go switch statement now has only `default` case (no `case "ballotready"` branch) — cicero is the sole recognized provider type
- ballotready/ package intentionally kept but now fails to compile — this is the desired state, confirming it's truly dead code
- .env.local edit is local-only per plan spec — no commit for Task 2

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated admin.go log.Printf string to remove BallotReady mention**
- **Found during:** Task 1 (final audit step)
- **Issue:** `log.Printf("[BulkImport] job=%s BallotReady warmer removed..."` was an active string literal (not a comment) — audit grep caught it
- **Fix:** Updated to `"[BulkImport] job=%s bulk import via live API is no longer supported — a new pipeline is required"`
- **Files modified:** EV-Backend/internal/essentials/admin.go
- **Verification:** Audit grep returns zero results after fix
- **Committed in:** 32c4ded (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - active log string literal caught by audit)
**Impact on plan:** Fix was necessary to achieve zero-result audit. No scope creep.

## Issues Encountered
- EV-Backend is its own git sub-repository (not tracked by the workspace root git) — committed to EV-Backend/.git directly

## User Setup Required
None - no external service configuration required. BALLOTREADY_KEY has been removed from .env.local; the server now defaults to cicero provider.

## Next Phase Readiness
- Phase 29 Plan 02 can proceed: provider/ is clean, audit confirms zero active BallotReady references
- cicero provider is the sole active provider — no accidental BallotReady re-activation possible without deliberate code changes
- ballotready/ package is isolated dead code; can be deleted in a future cleanup phase if desired

## Self-Check: PASSED

- FOUND: EV-Backend/internal/essentials/provider/config.go
- FOUND: EV-Backend/internal/essentials/provider/provider.go
- FOUND: .planning/phases/29-validation-polish-key-removal/29-01-SUMMARY.md
- FOUND: commit 32c4ded (chore(29-01): remove BallotReady constants and error from provider config)
- PASS: ProviderBallotReady removed from config.go
- PASS: ErrMissingBallotReadyKey removed from provider.go
- PASS: BALLOTREADY_KEY removed from .env.local
- PASS: Audit grep returns zero active BallotReady references
- PASS: go build -o /dev/null . succeeds

---
*Phase: 29-validation-polish-key-removal*
*Completed: 2026-02-22*
