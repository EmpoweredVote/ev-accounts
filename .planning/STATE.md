# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-17 after v1.4 milestone completion)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** v1.5 — Phase 31: Referral Dashboard Card

## Current Position

Phase: 31 of 33 (Referral Dashboard Card)
Plan: 0 of 1 in current phase
Status: Ready to plan
Last activity: 2026-03-19 — v1.5 roadmap created (Phases 31–33)

Progress: [v1.0 ✅][v1.1 ✅][v1.2 ✅][v1.3 ✅][v1.4 ✅][v1.5 🚧] 30/33 phases shipped ████████░░

## Performance Metrics

**v1.4 shipped:**
- Plans: 7 (27-01 through 30-02)
- Phases: 4 (Phase 27–30)
- Timeline: 2 days (2026-03-15 → 2026-03-17)
- 18/18 requirements satisfied

**v1.5 in progress:**
- Plans: 0/3 complete
- Phases: 0/3 complete
- Requirements: 0/16 satisfied

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

- **CompassV2 frontend** — Accounts side complete (Phase 18). CompassV2 repo must implement its side using the new `docs/COMPASSV2-INTEGRATION.md` (Phase 32 will produce this, replacing COMPASS_CONTRACT.md)

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 003 | Expose jurisdiction fields on GET /api/account/me for VQ | 2026-03-18 | 6932815 | [003-expose-jurisdiction-location-fields-on-g](./quick/003-expose-jurisdiction-location-fields-on-g/) |
| 004 | Implement POST /api/vq/adjust-vr endpoint for Yellow quest VR adjustment | 2026-03-18 | 6f78510 | [004-implement-post-api-vq-adjust-vr-endpoin](./quick/004-implement-post-api-vq-adjust-vr-endpoin/) |
| 005 | Fix double-login: hash-fragment SSO loop between accounts and profile apps | 2026-03-18 | 7b6be4a | [005-fix-double-login-accounts-to-profile](./quick/005-fix-double-login-accounts-to-profile/) |
| 006 | Configure /app for Render static site deploy (profile.empowered.vote) | 2026-03-18 | df0a9b7 | [006-configure-app-render-static-site-deploy](./quick/006-configure-app-render-static-site-deploy/) |

### Pending Todos

None.

## Session Continuity

Last session: 2026-03-19
Stopped at: v1.5 roadmap created — 3 phases, 3 plans, 16 requirements mapped
Resume: `/gsd:plan-phase 31` to start Referral Dashboard Card
