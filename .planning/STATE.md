# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-05 after v1.2 milestone start)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** Phase 12 — Alpha Hardening

## Current Position

Phase: 12 — Alpha Hardening
Plan: 01 complete, 02 next
Status: In progress
Last activity: 2026-03-06 — Completed 12-01-PLAN.md (type regeneration + any-cast removal)

Progress: ░░░░░░░░░░ ~10% (v1.2: Phase 12 in progress, 12-01 done)

## Performance Metrics

**v1.0 reference:**
- Total plans: 18 plans, 8 phases, 4 days

**v1.1 shipped:**
- Plans: 5 (09-01, 09-02, 10-01, 10-02, 11-01)
- Phases: 3 (Phase 9–11)
- Timeline: 1 day (2026-03-04)

## Accumulated Context

### Decisions

Full key decisions log in PROJECT.md. v1.1 decisions committed to decisions table.

### Pending Todos

None.

### Open Blockers

- **inform namespace missing from live DB:** Migration 015 ran without creating the inform schema namespace. All compass routes are non-functional in production. Requires repair migration: `CREATE SCHEMA IF NOT EXISTS inform;` + re-run of 015 tables. Track in Phase 12 or as a prerequisite for Phase 13.
- **empowered_profiles missing columns:** representing_city, district_type, chamber_name etc. never migrated to live DB. Candidate ZIP discovery non-functional. Requires future migration.

### Recent Decisions (12-01)

| Decision | Context |
|----------|---------|
| inform schema appended manually to generated types | inform namespace not created in live DB despite migration 015 recorded as applied; keeps all schema('inform') calls compiling |
| candidateService columns stripped | representing_city, district_type, chamber_name etc. not in live empowered_profiles; old types had them hand-written ahead of migration |
| getCandidatesByZip ZIP filter removed | representing_zip column missing from live DB; function returns all active candidates until migration adds it |

### Recent Decisions (12-02)

| Decision | Context |
|----------|---------|
| HS256 test JWT pattern via SUPABASE_JWT_SECRET | Must set env var before dynamic import — auth.ts reads it at module eval time |
| iat = now-1s in test JWT | isTokenRevoked uses strict less-than; same-second collision would break revocation test |
| Skip stubs deleted, not converted to .todo | vitest 2.x counts .todo as skipped — both patterns inflate reported count |

## Session Continuity

Last session: 2026-03-06
Stopped at: Completed 12-01-PLAN.md — type regeneration, any-cast removal, tsc clean
Resume file: None
