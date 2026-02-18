---
phase: 02-guest-first-auth
plan: 01
subsystem: auth
tags: [go, gorm, postgres, session, compass, guest-state]

# Dependency graph
requires:
  - phase: 01-auth-safety-audit
    provides: session middleware, auth patterns, route manifest
provides:
  - RegisterHandler accepts optional guest_state payload (answers + selected_topics)
  - RegisterHandler auto-creates session cookie on successful registration (no separate login needed)
  - DELETE /compass/answers/me endpoint (admin-only) clears user's compass data in a transaction
affects: [02-02-guest-first-auth, 02-03-guest-first-auth]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Use GORM Table() with anonymous structs to write cross-package DB records without creating circular imports"
    - "Auto-login on register: create session + SetCookie immediately after db.DB.Create(&user)"

key-files:
  created: []
  modified:
    - EV-Backend/internal/auth/handlers.go
    - EV-Backend/internal/compass/handlers.go
    - EV-Backend/internal/compass/routes.go

key-decisions:
  - "Avoided circular import (auth->compass->auth) by using GORM Table() with local anonymous structs instead of importing compass.Answer and compass.UserCompass"
  - "Session creation on register mirrors LoginHandler pattern: single session per user, no upsert needed since user is brand new"
  - "Guest answer insertion failures log but do not roll back registration — registration is the primary operation"

patterns-established:
  - "Cross-package GORM writes: use db.DB.Table('schema.table').Create(&localStruct) to avoid import cycles"

requirements-completed: [AUTH-05, AUTH-06]

# Metrics
duration: 2min
completed: 2026-02-17
---

# Phase 02 Plan 01: Guest-First Auth — Backend Changes Summary

**RegisterHandler extended to accept guest answers + auto-login on register; new admin DELETE /compass/answers/me clears user compass data transactionally**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-17T22:20:47Z
- **Completed:** 2026-02-17T22:23:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- RegisterHandler now accepts optional `guest_state` JSON body containing `answers[]` and `selected_topics[]`
- Session cookie is created immediately on successful registration so the user is logged in without a separate POST /auth/login call
- Guest answers are bulk-inserted into `compass.answers` in a transaction; invalid UUIDs are silently skipped; errors log but do not fail registration
- Guest selected topics are inserted into `compass.user_compasses`
- New `DeleteMyAnswersHandler` clears all `compass.answers` and `compass.user_compasses` for the authenticated user in a single transaction
- DELETE /compass/answers/me wired behind both `SessionMiddleware` and `AdminMiddleware`

## Task Commits

Each task was committed atomically (commits in EV-Backend repo):

1. **Task 1: RegisterHandler — accept guest_state and auto-login on register** - `4a97c9f` (feat)
2. **Task 2: Add DELETE /compass/answers/me endpoint (admin-only)** - `e490c97` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `EV-Backend/internal/auth/handlers.go` - Added GuestAnswer, GuestState, RegisterRequest types; rewrote RegisterHandler to use RegisterRequest, add auto-login session creation, and process guest_state via GORM Table() anonymous structs
- `EV-Backend/internal/compass/handlers.go` - Added DeleteMyAnswersHandler (transactional delete of answers + user_compasses)
- `EV-Backend/internal/compass/routes.go` - Added `r.Delete("/answers/me", DeleteMyAnswersHandler)` inside AdminMiddleware group

## Decisions Made

- **Circular import resolution:** The plan specified importing `compass.Answer` and `compass.UserCompass` from the auth package, but `compass` already imports `auth` (via `fetcher.go`). Resolved by using `db.DB.Table("compass.answers")` and `db.DB.Table("compass.user_compasses")` with local anonymous structs — no behavioral change, same data written to same tables.
- **Session creation pattern:** New session is always created (not upserted) since the user is brand new and cannot have an existing session.
- **Guest merge failure handling:** DB errors during guest answer insertion log via `log.Printf` and break the loop, but the transaction is committed up to that point and registration succeeds — the user account is the primary outcome.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Resolved circular import between auth and compass packages**
- **Found during:** Task 1 (RegisterHandler implementation)
- **Issue:** Plan specified `import "github.com/EmpoweredVote/EV-Backend/internal/compass"` in `auth/handlers.go`, but `compass/fetcher.go` already imports `auth`. Go prohibits circular imports — build failed immediately.
- **Fix:** Used `db.DB.Table("compass.answers").Create(&localAnonymousStruct)` and `db.DB.Table("compass.user_compasses").Create(&localAnonymousStruct)` instead of compass package types. Identical behavior; writes to the same Postgres tables with the same column names.
- **Files modified:** EV-Backend/internal/auth/handlers.go (imports removed, anonymous structs added)
- **Verification:** `go build -o /dev/null .` and `go vet ./...` both pass with no errors
- **Committed in:** `4a97c9f` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - circular import bug)
**Impact on plan:** Necessary fix for correctness. No behavior change — same data, same tables, same columns.

## Issues Encountered

None beyond the circular import, which was auto-fixed inline.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Backend API changes complete for guest-first auth flow
- `POST /auth/register` now accepts `guest_state` and returns a session cookie — frontend can send localStorage answers during registration and receive an active session
- `DELETE /compass/answers/me` available for admin "Clear compass" action
- Ready for Phase 02-02 (frontend guest state persistence) and 02-03 (save prompt modal)

---
*Phase: 02-guest-first-auth*
*Completed: 2026-02-17*

## Self-Check: PASSED

- FOUND: EV-Backend/internal/auth/handlers.go
- FOUND: EV-Backend/internal/compass/handlers.go
- FOUND: EV-Backend/internal/compass/routes.go
- FOUND: .planning/phases/02-guest-first-auth/02-01-SUMMARY.md
- FOUND: commit 4a97c9f (feat(02-01): RegisterHandler accepts guest_state and auto-login on register)
- FOUND: commit e490c97 (feat(02-01): add DELETE /compass/answers/me admin endpoint)
