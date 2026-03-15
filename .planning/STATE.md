# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-15 after v1.3 milestone completion)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** v1.4 — Phase 27: Verification Rating Schema

## Current Position

Phase: 27 of 30 (Verification Rating Schema)
Plan: 0 of TBD in current phase
Status: Ready to plan
Last activity: 2026-03-15 — v1.4 roadmap created (4 phases, 18 requirements mapped)

Progress: [v1.3 shipped ✅] Starting v1.4 — Phase 27

## Performance Metrics

**v1.0 shipped:**
- Total plans: 18 plans, 8 phases, 4 days

**v1.1 shipped:**
- Plans: 5 (09-01, 09-02, 10-01, 10-02, 11-01)
- Phases: 3 (Phase 9–11)
- Timeline: 1 day (2026-03-04)

**v1.2 shipped:**
- Plans: 15 (12-01 through 16-01)
- Phases: 5 (Phase 12–16)
- Timeline: 2 days (2026-03-06 → 2026-03-07)

**v1.3 shipped:**
- Plans: 26 (17-01 through 26-01)
- Phases: 10 (Phase 17–26)
- Timeline: 8 days (2026-03-08 → 2026-03-15)
- 33/33 requirements satisfied

## Accumulated Context

### Key Decisions

Full key decisions log in PROJECT.md. All v1.3 decisions archived in milestones/v1.3-ROADMAP.md.

Recent decisions relevant to v1.4:
- **Bearer Authorization for service keys** — external services use standard Bearer semantics; pattern established in Phase 22, reused for VQ service key
- **Partial unique index on idempotency_key (WHERE NOT NULL)** — correct Postgres pattern for nullable dedup; established in Phase 22, apply to VQ confirm-stance
- **SET search_path = '' on all SECURITY DEFINER functions** — fully-qualified table refs required; established Phase 13, mandatory for any new RPC
- **Two-pass validation in admin atomic RPCs** — validate all inputs before any writes; established Phase 14, apply to confirm-stance bulk user processing

### Open Blockers

- **CTC + VQ service key setup** — Chris needs to set matching key values in both partner app Render environments and the accounts API env before INTEG-01/02 can be verified
- **CompassV2 frontend** — Accounts side complete (Phase 18). CompassV2 repo must implement its side using `docs/COMPASS_CONTRACT.md`

### Pending Todos

- **Phase 29**: Confirm CTC service key is set in Render env before running integration smoke test
- **Phase 30**: Profile Hub UI in accounts portal — depends on VR data available on `/me` (Phase 27 prerequisite)

## Session Continuity

Last session: 2026-03-15
Stopped at: v1.4 roadmap created — 4 phases (27–30), 18/18 requirements mapped, files written
Resume: Run `/gsd:plan-phase 27` to plan Phase 27 (Verification Rating Schema — migration + /me API update)
