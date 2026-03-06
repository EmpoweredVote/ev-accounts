# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-05 after v1.2 milestone start)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** Phase 13 — CompassV2 Backend Compatibility

## Current Position

Phase: 13 — CompassV2 Backend Compatibility
Plan: 13-02 (complete)
Status: In progress — 2/4 plans complete in Phase 13
Last activity: 2026-03-06 — Completed 13-02-PLAN.md (DELETE /api/compass/answers/me endpoint, resetCompassAnswers service, types update)

Progress: ████░░░░░░ 50% (v1.2: 1/4 phases complete; Phase 13: 2/4 plans)

## Performance Metrics

**v1.0 reference:**
- Total plans: 18 plans, 8 phases, 4 days

**v1.1 shipped:**
- Plans: 5 (09-01, 09-02, 10-01, 10-02, 11-01)
- Phases: 3 (Phase 9–11)
- Timeline: 1 day (2026-03-04)

**v1.2 progress:**
- Plans: 2 (12-01, 12-02)
- Phases: 1 (Phase 12)
- Timeline: 1 day (2026-03-06)

## Accumulated Context

### Decisions

Full key decisions log in PROJECT.md. v1.1 decisions committed to decisions table.

### Pending Todos

None.

### Open Blockers

- **inform namespace missing from live DB:** RESOLVED by migration 026. Run `backend/migrations/026_inform_schema_repair_and_candidates.sql` against live DB to clear this blocker.
- **empowered_profiles missing columns:** representing_city, district_type, chamber_name etc. never migrated to live DB. Candidate ZIP discovery non-functional. Requires future migration.

### Accumulated Decisions (Phase 12)

| Decision | Context |
|----------|---------|
| inform schema appended manually to generated types | inform namespace not created in live DB despite migration 015 recorded as applied; keeps all schema('inform') calls compiling |
| candidateService columns stripped | representing_city, district_type, chamber_name etc. not in live empowered_profiles; old types had them hand-written ahead of migration |
| getCandidatesByZip ZIP filter removed | representing_zip column missing from live DB; function returns all active candidates until migration adds it |
| HS256 test JWT pattern via SUPABASE_JWT_SECRET | Must set env var before dynamic import — auth.ts reads it at module eval time |
| iat = now-1s in test JWT | isTokenRevoked uses strict less-than; same-second collision would break revocation test |
| Skip stubs deleted, not converted to .todo | vitest 2.x counts .todo as skipped — both patterns inflate reported count |

### Accumulated Decisions (Phase 13)

| Decision | Context |
|----------|---------|
| Soft-delete via deleted_at on compass_responses | Preserves response data for recovery and re-import; reset_compass_answers sets deleted_at = now(), import_compass_calibrations sets deleted_at = NULL on re-import |
| Two-pass validation in import_compass_calibrations | Full validation loop before any writes — all-or-nothing atomicity guarantee |
| SET search_path = '' on SECURITY DEFINER functions | Prevents search_path injection; all table references fully-qualified |
| Conditional requireAdmin via Promise wrapper | DELETE /answers/me uses ?full=true admin flag; middleware invoked programmatically with res.headersSent guard rather than separate route |

## Session Continuity

Last session: 2026-03-06
Stopped at: Completed 13-02-PLAN.md — DELETE /api/compass/answers/me endpoint implemented
Resume: Execute 13-03-PLAN.md (essentials endpoints / politicians grouping)
