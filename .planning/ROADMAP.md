# Roadmap: Empowered Accounts

## Milestones

- ✅ **v1.0 MVP** — Phases 1–8 (shipped 2026-02-28)
- ✅ **v1.1 XP & Progression** — Phases 9–11 (shipped 2026-03-04)
- ✅ **v1.2 CompassV2 Integration & Alpha Hardening** — Phases 12–16 (shipped 2026-03-07)
- ✅ **v1.3 Alpha Launch & Location Infrastructure** — Phases 17–26 (shipped 2026-03-15)
- 🚧 **v1.4 Profile Hub & Verification Engine** — Phases 27–30 (in progress)

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

<details>
<summary>✅ v1.1 XP & Progression (Phases 9–11) — SHIPPED 2026-03-04</summary>

- [x] Phase 9: XP Schema & Core (2/2 plans) — completed 2026-03-04
- [x] Phase 10: XP API (2/2 plans) — completed 2026-03-04
- [x] Phase 11: Admin Tool XP View (1/1 plan) — completed 2026-03-04

Full details: `.planning/milestones/v1.1-ROADMAP.md`

</details>

<details>
<summary>✅ v1.2 CompassV2 Integration & Alpha Hardening (Phases 12–16) — SHIPPED 2026-03-07</summary>

- [x] Phase 12: Alpha Hardening (2/2 plans) — completed 2026-03-06
- [x] Phase 13: CompassV2 Backend Compatibility (4/4 plans) — completed 2026-03-06
- [x] Phase 14: Compass Admin Backend (3/3 plans) — completed 2026-03-06
- [x] Phase 15: Compass Admin React UI (5/5 plans) — completed 2026-03-07
- [x] Phase 16: v1.2 Gap Closure (1/1 plan) — completed 2026-03-07

Full details: `.planning/milestones/v1.2-ROADMAP.md`

</details>

<details>
<summary>✅ v1.3 Alpha Launch & Location Infrastructure (Phases 17–26) — SHIPPED 2026-03-15</summary>

- [x] Phase 17: Live Alpha Deployment (3/3 plans) — completed 2026-03-10
- [x] Phase 18: CompassV2 API Contract (4/4 plans) — completed 2026-03-10
- [x] Phase 19: Location Schema & RPCs (3/3 plans) — completed 2026-03-12
- [x] Phase 20: Location Endpoints & Validation (5/5 plans) — completed 2026-03-14
- [x] Phase 21: empowered_profiles Politician Schema (2/2 plans) — completed 2026-03-14
- [x] Phase 22: Multi-Currency Gem System (2/2 plans) — completed 2026-03-14
- [x] Phase 23: Central Profile Page + Admin Tier Promotion (3/3 plans) — completed 2026-03-14
- [x] Phase 24: Public Auth Hub (2/2 plans) — completed 2026-03-14
- [x] Phase 25: Deployment Runbook Completion (1/1 plan) — completed 2026-03-15
- [x] Phase 26: v1.3 Tech Debt Closure (1/1 plan) — completed 2026-03-15

Full details: `.planning/milestones/v1.3-ROADMAP.md`

</details>

### 🚧 v1.4 Profile Hub & Verification Engine (In Progress)

**Milestone Goal:** Make the platform usable end-to-end for a real Alpha user — a useful profile page, live CTC/VQ integrations verified, and a Verification Rating system that rewards good civic participation.

#### Phase 27: Verification Rating Schema

**Goal**: Users have a Verification Rating that reflects their VQ accuracy, and the API exposes it with hold state and Red Gem unlock status.
**Depends on**: Phase 26 (v1.3 complete)
**Requirements**: VR-01, VR-02, VR-03, VR-04
**Success Criteria** (what must be TRUE):
  1. `connected_profiles` has `verification_rating` (integer, default 60) and `vq_hold_until` (timestamptz) columns in production
  2. `GET /api/account/me` returns `verification_rating`, `vq_hold_active: boolean`, and `red_gem_quests_unlocked: boolean`
  3. A user with rating >= 90 gets `red_gem_quests_unlocked: true`; a user with `vq_hold_until` in the future gets `vq_hold_active: true`
  4. A user with rating at 0 and `vq_hold_until` set 30 days out cannot be confused with an unrestricted user — the API communicates hold state unambiguously
**Plans**: 1 plan

Plans:
- [x] 27-01-PLAN.md — Migration 037 (verification_rating + vq_hold_until columns) and /me API response update with derived booleans

#### Phase 28: VQ Confirmation Flow

**Goal**: VQ can call a single authenticated endpoint to resolve a question — awarding Red Gems to correct answerers, adjusting Verification Ratings in both directions, writing the confirmed stance, and doing nothing on replay.
**Depends on**: Phase 27 (VR schema and columns must exist)
**Requirements**: VQ-01, VQ-02, VQ-03, VQ-04, VQ-05, VQ-06
**Success Criteria** (what must be TRUE):
  1. `POST /api/vq/confirm-stance` accepts a service-key-authenticated payload with correct/incorrect user ID lists and returns a confirmation result
  2. Correct answerers each receive Red Gems; incorrect answerers do not
  3. Correct answerers' `verification_rating` increases by 3 (max 150); incorrect answerers' decreases by 10; a rating that hits 0 sets `vq_hold_until` 30 days out
  4. The confirmed stance value is written to `inform.politician_answers` as the authoritative record
  5. Replaying the same `idempotency_key` returns the original result with no additional gem awards or rating changes
**Plans**: 2 plans

Plans:
- [x] 28-01-PLAN.md — Migration 038 (vq_confirmation_results table + confirm_vq_stance RPC) + route + service file + registration
- [x] 28-02-PLAN.md — Integration tests covering all 6 VQ requirements

#### Phase 29: Admin Controls & Integration Verification

**Goal**: Admins can override Verification Ratings in the tool, and CTC + VQ integrations are confirmed live end-to-end with documentation updated.
**Depends on**: Phase 28 (VQ flow must exist to verify it)
**Requirements**: VR-05, INTEG-01, INTEG-02, INTEG-03
**Success Criteria** (what must be TRUE):
  1. Admin can view and manually edit a user's `verification_rating` and clear `vq_hold_until` via the admin tool UI
  2. A real CTC game event produces XP and yellow gem records on a live user account (visible in admin ledger view)
  3. A test VQ confirmation event via `POST /api/vq/confirm-stance` produces Red Gem and rating changes on live user accounts
  4. `docs/ONBOARDING-VQ.md` documents the `/vq/confirm-stance` endpoint contract for VQ developers
**Plans**: TBD

Plans:
- [ ] 29-01: Admin VR controls UI
- [ ] 29-02: Integration smoke tests + docs update

#### Phase 30: Profile Hub UI

**Goal**: A Connected user visiting their profile page sees their full civic identity — tier, progression, Verification Rating, gem balances, location form, and a hub of all live Empowered Vote features.
**Depends on**: Phase 27 (VR data on /me must be available before displaying it)
**Requirements**: PROFILE-01, PROFILE-02, PROFILE-03, PROFILE-04
**Success Criteria** (what must be TRUE):
  1. Profile page displays tier, level, total XP, yellow/blue/red gem balances, and Verification Rating for the logged-in user
  2. User can enter their address in a form on the profile page; submitting calls `POST /connect/set-location` and confirms success
  3. Profile page shows a feature hub with cards for CTC, VQ, Essentials, Read & Rank, and Treasury Tracker — each with description and link
  4. Feature hub cards communicate "explore freely, connect to save" — the user understands which features are available without a Connected account
**Plans**: TBD

Plans:
- [ ] 30-01: Profile stats + location form
- [ ] 30-02: Feature hub cards

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
| 10. XP API | v1.1 | 2/2 | Complete | 2026-03-05 |
| 11. Admin Tool XP View | v1.1 | 1/1 | Complete | 2026-03-06 |
| 12. Alpha Hardening | v1.2 | 2/2 | Complete | 2026-03-06 |
| 13. CompassV2 Backend Compatibility | v1.2 | 4/4 | Complete | 2026-03-06 |
| 14. Compass Admin Backend | v1.2 | 3/3 | Complete | 2026-03-06 |
| 15. Compass Admin React UI | v1.2 | 5/5 | Complete | 2026-03-07 |
| 16. v1.2 Gap Closure | v1.2 | 1/1 | Complete | 2026-03-07 |
| 17. Live Alpha Deployment | v1.3 | 3/3 | Complete | 2026-03-10 |
| 18. CompassV2 API Contract | v1.3 | 4/4 | Complete | 2026-03-10 |
| 19. Location Schema & RPCs | v1.3 | 3/3 | Complete | 2026-03-12 |
| 20. Location Endpoints & Validation | v1.3 | 5/5 | Complete | 2026-03-14 |
| 21. empowered_profiles Politician Schema | v1.3 | 2/2 | Complete | 2026-03-14 |
| 22. Multi-Currency Gem System | v1.3 | 2/2 | Complete | 2026-03-14 |
| 23. Central Profile Page + Admin Tier Promotion | v1.3 | 3/3 | Complete | 2026-03-14 |
| 24. Public Auth Hub (Login Rebrand + Signup Flow) | v1.3 | 2/2 | Complete | 2026-03-14 |
| 25. Deployment Runbook Completion | v1.3 | 1/1 | Complete | 2026-03-15 |
| 26. v1.3 Tech Debt Closure | v1.3 | 1/1 | Complete | 2026-03-15 |
| 27. Verification Rating Schema | v1.4 | 1/1 | Complete | 2026-03-15 |
| 28. VQ Confirmation Flow | v1.4 | 2/2 | Complete | 2026-03-15 |
| 29. Admin Controls & Integration Verification | v1.4 | 0/— | Not started | — |
| 30. Profile Hub UI | v1.4 | 0/— | Not started | — |
