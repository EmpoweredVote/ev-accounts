# Roadmap: Empowered Accounts

## Milestones

- ✅ **v1.0 MVP** — Phases 1–8 (shipped 2026-02-28)
- 🚧 **v1.1 XP & Progression** — Phases 9–11 (in progress)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1–8) — SHIPPED 2026-02-28</summary>

- [x] Phase 1: Foundation (2/2 plans) — completed 2026-02-24
- [x] Phase 2: Auth Routes and Account Core (2/2 plans) — completed 2026-02-25
- [x] Phase 3: Alpha Enrollment (3/3 plans) — completed 2026-02-25
- [x] Phase 4: Compass Routes (3/3 plans) — completed 2026-02-26
- [x] Phase 5: Empower Flow (2/2 plans) — completed 2026-02-27
- [x] Phase 6: Gems, Roles, and Social Graph (3/3 plans) — completed 2026-02-27
- [x] Phase 7: Admin Tool and Calibration Cron (3/3 plans) — completed 2026-02-27
- [x] Phase 8: Public Candidate Pages (2/2 plans) — completed 2026-02-28

Full details: `.planning/milestones/v1.0-ROADMAP.md`

</details>

### 🚧 v1.1 XP & Progression (In Progress)

**Milestone Goal:** Add a unified XP and leveling system — append-only ledger, atomic award RPC, level calculation, public XP profile endpoint, and admin ledger view — so any feature repo can read and award XP with idempotency guarantees.

#### Phase 9: XP Schema & Core

**Goal:** The XP ledger and level calculation exist in the database and are enforced by RLS — the infrastructure every upstream phase depends on.
**Depends on:** Phase 8 (v1.0 complete)
**Requirements:** XPLED-01, XPLED-02, XPLED-03, XPLED-04, XPLED-05, LEVEL-01, LEVEL-02
**Success Criteria** (what must be TRUE):
  1. A Connected user's XP award is persisted atomically — both the ledger row and the denormalized `total_xp` / `current_level` on `connected_profiles` update in the same transaction or neither updates.
  2. Calling `award_xp` twice with the same idempotency key inserts exactly one ledger row — the second call is a silent no-op, not an error.
  3. A Connected user querying `xp_transactions` via Supabase RLS sees only their own rows; an unauthenticated query returns zero rows.
  4. Level progression follows the defined thresholds (2k × 3, 3k × 6, 4k × 20, 5k thereafter), and `xp_in_level` plus `xp_to_next_level` are computable from any `total_xp` value.
**Plans:** 2 plans

Plans:
- [x] 09-01-PLAN.md — XP schema migration (xp_transactions table, connected_profiles columns, view update, RLS, grants)
- [x] 09-02-PLAN.md — calculate_level + award_xp RPC functions and SQL test file

#### Phase 10: XP API

**Goal:** Feature repos and authenticated users can read and award XP through the Express API — with idempotency enforcement, source validation, and XP data surfaced on the account/me response.
**Depends on:** Phase 9
**Requirements:** XPAPI-01, XPAPI-02, XPAPI-03, XPAPI-04, XPAPI-05, XPAPI-06
**Success Criteria** (what must be TRUE):
  1. A feature repo calling `POST /api/xp/award` with a valid `X-Service-Key` and a new idempotency key receives a 200 with the created transaction; repeating the same call returns 200 with the original transaction and no second ledger row.
  2. Calling `POST /api/xp/award` with an unrecognized source type is rejected with a 422 — the award is never written.
  3. `GET /account/me` for a Connected user includes an `xp` object containing `total`, `level`, `xp_in_level`, and `xp_to_next_level`.
  4. `GET /api/xp/:userId` returns `{ level, total_xp }` to an unauthenticated caller without exposing the full transaction ledger.
  5. `GET /api/xp/me/history` for an authenticated Connected user returns the caller's ledger entries (source, amount, metadata, created_at); an unauthenticated request is rejected with 401.
**Plans:** TBD

Plans:
- [ ] 10-01: `xpService.ts`, `POST /api/xp/award`, source enum validation, idempotency enforcement
- [ ] 10-02: `GET /api/xp/:userId`, `GET /api/xp/me/history`, `GET /account/me` XP extension

#### Phase 11: Admin Tool XP View

**Goal:** Admins can inspect any Connected user's XP standing and full transaction history from the existing account detail page without leaving the admin tool.
**Depends on:** Phase 10
**Requirements:** XPADM-01, XPADM-02
**Success Criteria** (what must be TRUE):
  1. The account header in the admin tool displays a Connected user's total XP and current level alongside existing account summary fields.
  2. Admin can navigate to an XP History tab on any Connected account detail page and see every ledger entry — source, amount, metadata, and timestamp — in reverse chronological order.
**Plans:** TBD

Plans:
- [ ] 11-01: Admin account detail XP summary header and XP History tab component

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.0 | 2/2 | Complete | 2026-02-24 |
| 2. Auth Routes and Account Core | v1.0 | 2/2 | Complete | 2026-02-25 |
| 3. Alpha Enrollment | v1.0 | 3/3 | Complete | 2026-02-25 |
| 4. Compass Routes | v1.0 | 3/3 | Complete | 2026-02-26 |
| 5. Empower Flow | v1.0 | 2/2 | Complete | 2026-02-27 |
| 6. Gems, Roles, and Social Graph | v1.0 | 3/3 | Complete | 2026-02-27 |
| 7. Admin Tool and Calibration Cron | v1.0 | 3/3 | Complete | 2026-02-27 |
| 8. Public Candidate Pages | v1.0 | 2/2 | Complete | 2026-02-28 |
| 9. XP Schema & Core | v1.1 | 2/2 | Complete | 2026-03-04 |
| 10. XP API | v1.1 | 0/2 | Not started | - |
| 11. Admin Tool XP View | v1.1 | 0/1 | Not started | - |
