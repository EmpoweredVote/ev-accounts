# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-24)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** Phase 1 — Foundation

## Current Position

Phase: 1 of 8 (Foundation)
Plan: 0 of 2 in current phase
Status: Ready to plan
Last activity: 2026-02-24 — Roadmap created (8 phases, 52 v1 requirements mapped)

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**
- Total plans completed: 0
- Average duration: —
- Total execution time: —

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

**Recent Trend:**
- Last 5 plans: —
- Trend: —

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Pre-Phase 1]: Tier determined by child record presence, never status flag — eliminates invalid states by construction
- [Pre-Phase 1]: RLS is primary defense; Express middleware is second layer — neither is optional
- [Pre-Phase 1]: Empowerment and demotion are Postgres RPC functions only — chained JS awaits are explicitly forbidden
- [Pre-Phase 1]: service role key used for trusted writes only, never for reads that return data to users

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 1 planning]: `account_standing` enum values — proposal is `('active', 'suspended', 'quarantined')`. Confirm before writing migration — enum alterations on a populated table require a new migration.
- [Phase 3 planning]: Tolerance Rating cascade depth (one level vs. full chain) must be confirmed before invite schema is finalized.
- [Phase 7 planning]: Notification delivery channel for day-25 warning and day-30 demotion events is TBD — email or in-app. Must be resolved before Phase 7 is implemented.

## Session Continuity

Last session: 2026-02-24
Stopped at: Roadmap created — ready to begin Phase 1 planning
Resume file: None
