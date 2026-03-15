# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-15 after v1.3 milestone completion)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** v1.4 — Phase 28: VQ Confirmation Flow

## Current Position

Phase: 28 of 30 (VQ Confirmation Flow)
Plan: 2 of 2 in current phase
Status: Phase complete
Last activity: 2026-03-15 — Completed 28-02-PLAN.md

Progress: [v1.3 shipped ✅] v1.4 in progress — Phase 28 complete ██

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
- **verification_rating default 60** — baseline unverified score; 90+ threshold unlocks Red Gem quests; Phase 28 adjusts on confirmed stances
- **vq_hold_until excluded from public view** — internal enforcement state (same privacy pattern as tolerance_rating); owner self-view nested object only
- **Server-side VR derived booleans** — vq_hold_active and red_gem_quests_unlocked computed on server before response; clients receive clean booleans
- **Advisory locks in sorted UUID order** — combine correct + incorrect users, dedup, sort, lock all before any writes; prevents deadlocks in concurrent VQ calls (Phase 28)
- **Per-user idempotency sub-key for gem_transactions** — p_idempotency_key || ':' || uid::text prevents double-crediting when user appears in multiple concurrent confirmation calls (Phase 28)
- **Idempotency pre-check before lock acquisition** — cached result returned immediately before any advisory locks or writes; cheapest replay path (Phase 28)
- **No nested SECURITY DEFINER calls** — gem INSERT + balance UPDATE done inline in confirm_vq_stance, not via credit_gems RPC; nested SECURITY DEFINER unreliable in Postgres (Phase 28)
- **VQ live test fixtures via env vars** — INTEGRATION_TEST_POLITICIAN_ID + INTEGRATION_TEST_TOPIC_ID required; tests skipIf absent rather than creating inline data (Phase 28)

### Open Blockers

- **CTC + VQ service key setup** — Chris needs to set matching key values in both partner app Render environments and the accounts API env before INTEG-01/02 can be verified
- **CompassV2 frontend** — Accounts side complete (Phase 18). CompassV2 repo must implement its side using `docs/COMPASS_CONTRACT.md`

### Pending Todos

- **Phase 29**: Confirm CTC service key is set in Render env before running integration smoke test
- **Phase 30**: Profile Hub UI in accounts portal — depends on VR data available on `/me` (Phase 27 prerequisite)

## Session Continuity

Last session: 2026-03-15
Stopped at: Completed 28-02-PLAN.md — VQ integration tests (vq.test.ts)
Resume: Run `/gsd:plan-phase 29` to plan Phase 29 (VQ Integration Smoke Test)
