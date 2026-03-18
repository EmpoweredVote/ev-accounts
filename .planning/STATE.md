# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-17 after v1.4 milestone completion)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** v1.5 — Planning next milestone

## Current Position

Phase: Not started
Plan: Not started
Status: Ready to plan v1.5
Last activity: 2026-03-18 - Completed quick task 004: Implement POST /api/vq/adjust-vr endpoint for Yellow quest VR adjustment

Progress: [v1.0 ✅][v1.1 ✅][v1.2 ✅][v1.3 ✅][v1.4 ✅] All 30 phases shipped ██████████

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

**v1.4 shipped:**
- Plans: 7 (27-01 through 30-02)
- Phases: 4 (Phase 27–30)
- Timeline: 2 days (2026-03-15 → 2026-03-17)
- 18/18 requirements satisfied

## Accumulated Context

### Key Decisions

Full key decisions log in PROJECT.md. All v1.4 decisions archived in milestones/v1.4-ROADMAP.md.

v1.4 patterns established (apply going forward):
- **No nested SECURITY DEFINER calls** — gem/XP writes must be done inline in RPCs, not via nested RPC calls
- **Advisory locks: combined + sorted UUID order** — all affected users locked before any writes; prevents deadlocks
- **Per-user idempotency sub-keys** — `main_key:uid` prevents double-writes in multi-user atomic RPCs
- **Idempotency pre-check before locks** — check result cache before acquiring any advisory locks
- **Server-side derived booleans** — compute `vq_hold_active`, `red_gem_quests_unlocked` on server; clients receive clean booleans

### Open Blockers

- **CompassV2 frontend** — Accounts side complete (Phase 18). CompassV2 repo must implement its side using `docs/COMPASS_CONTRACT.md`

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 003 | Expose jurisdiction fields on GET /api/account/me for VQ | 2026-03-18 | 6932815 | [003-expose-jurisdiction-location-fields-on-g](./quick/003-expose-jurisdiction-location-fields-on-g/) |
| 004 | Implement POST /api/vq/adjust-vr endpoint for Yellow quest VR adjustment | 2026-03-18 | 6f78510 | [004-implement-post-api-vq-adjust-vr-endpoin](./quick/004-implement-post-api-vq-adjust-vr-endpoin/) |

### Pending Todos

- **v1.5 milestone planning** — run `/gsd:new-milestone` to define v1.5

## Session Continuity

Last session: 2026-03-18
Stopped at: Completed quick task 004: POST /api/vq/adjust-vr
Resume: `/gsd:new-milestone` to define v1.5
