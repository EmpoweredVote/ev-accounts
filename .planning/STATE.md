# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-05 after v1.2 milestone start)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** Phase 14 — Compass Admin Backend

## Current Position

Phase: 14 — Compass Admin Backend
Plan: —
Status: Phase 13 complete, ready to plan Phase 14
Last activity: 2026-03-06 — Phase 13 CompassV2 Backend Compatibility executed and verified (6/6 criteria passed)

Progress: ████░░░░░░ 50% (v1.2: 2/4 phases complete)

## Performance Metrics

**v1.0 reference:**
- Total plans: 18 plans, 8 phases, 4 days

**v1.1 shipped:**
- Plans: 5 (09-01, 09-02, 10-01, 10-02, 11-01)
- Phases: 3 (Phase 9–11)
- Timeline: 1 day (2026-03-04)

**v1.2 progress:**
- Plans: 6 (12-01, 12-02, 13-01, 13-02, 13-03, 13-04)
- Phases: 2 (Phase 12–13)
- Timeline: 1 day each (2026-03-06)

## Accumulated Context

### Decisions

Full key decisions log in PROJECT.md. v1.1 decisions committed to decisions table.

### Pending Todos

None.

### Open Blockers

- **empowered_profiles missing columns:** representing_city, district_type, chamber_name etc. never migrated to live DB. Candidate ZIP discovery non-functional. Requires future migration.

Note: The inform schema blocker is RESOLVED — migration 026 repairs the inform namespace and is idempotent. Run migrations 026, 027, 028 against the live DB to activate all Phase 13 endpoints.

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
| Soft-delete via deleted_at on compass_responses | Preserves data for recovery; reset_compass_answers sets deleted_at = now(), import_compass_calibrations sets deleted_at = NULL on re-import |
| Two-pass validation in import_compass_calibrations | Full validation loop before any writes — all-or-nothing atomicity guarantee |
| SET search_path = '' on SECURITY DEFINER functions | Prevents search_path injection; all table references fully-qualified |
| Conditional requireAdmin via Promise wrapper | DELETE /answers/me ?full=true admin flag; middleware invoked programmatically with res.headersSent guard |
| essentialsService.ts uses supabaseAnon exclusively | inform.politicians is public reference data; no service-role needed |
| compass-import legacy path retains session guard | New direct-value path bypasses session for post-Connect users; stance_id-only path retains session requirement |
| as-any cast removed from essentialsService.ts | database.types.ts updated by 13-02 before 13-03 ran; is_candidate properly typed |

## Session Continuity

Last session: 2026-03-06
Stopped at: Phase 13 complete — all 6 success criteria verified, planning docs updated
Resume: Run `/gsd:discuss-phase 14` or `/gsd:plan-phase 14` to begin Compass Admin Backend
