# Roadmap: Empowered Accounts

## Milestones

- ✅ **v1.0 MVP** — Phases 1–8 (shipped 2026-02-28)
- ✅ **v1.1 XP & Progression** — Phases 9–11 (shipped 2026-03-04)
- ✅ **v1.2 CompassV2 Integration & Alpha Hardening** — Phases 12–16 (shipped 2026-03-07)
- ✅ **v1.3 Alpha Launch & Location Infrastructure** — Phases 17–26 (shipped 2026-03-15)
- ✅ **v1.4 Profile Hub & Verification Engine** — Phases 27–30 (shipped 2026-03-17)
- ✅ **v1.5 Partner Integration & Referrals** — Phases 31–33 (shipped 2026-03-19)

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

<details>
<summary>✅ v1.4 Profile Hub & Verification Engine (Phases 27–30) — SHIPPED 2026-03-17</summary>

- [x] Phase 27: Verification Rating Schema (1/1 plan) — completed 2026-03-15
- [x] Phase 28: VQ Confirmation Flow (2/2 plans) — completed 2026-03-15
- [x] Phase 29: Admin Controls & Integration Verification (2/2 plans) — completed 2026-03-15
- [x] Phase 30: Profile Hub UI (2/2 plans) — completed 2026-03-16

Full details: `.planning/milestones/v1.4-ROADMAP.md`

</details>

### 🚧 v1.5 Partner Integration & Referrals (In Progress)

**Milestone Goal:** Ship referral code UI on the profile dashboard and write comprehensive integration guides for CompassV2 and Essentials so partner features can connect cleanly — with jurisdiction flowing automatically to Connected users, never asking for their address again.

#### Phase 31: Referral Dashboard Card

**Goal:** Connected users can see and use their referral code from the profile dashboard, with accurate locked/waiting/active states driven by the existing backend.
**Depends on:** Phase 30 (Profile Hub UI exists; `GET /api/referral` backend already shipped)
**Requirements:** REF-01, REF-02, REF-03, REF-04
**Success Criteria** (what must be TRUE):
  1. A Connected user at level 2+ sees their referral code on the dashboard with a one-click copy button that writes the code to the clipboard
  2. A Connected user at level < 2 sees a locked referral card explaining the level 2 requirement — no code is visible
  3. A Connected user whose invitee has not yet reached level 2 sees a distinct "waiting" state on the referral card
  4. The card state is determined entirely by `GET /api/referral` — refreshing the page produces the correct state without client-side guessing
**Plans:** 1 plan

Plans:
- [x] 31-01: Referral card component with locked/waiting/active states

#### Phase 32: CompassV2 Integration Guide

**Goal:** The CompassV2 team has a single, authoritative reference document covering auth, API endpoints, tier access, jurisdiction, and platform philosophy — replacing the outdated COMPASS_CONTRACT.md.
**Depends on:** Nothing (documentation, no code dependency)
**Requirements:** CDOC-01, CDOC-02, CDOC-03, CDOC-04, CDOC-05, CDOC-06
**Success Criteria** (what must be TRUE):
  1. A developer reading the guide can implement the full auth redirect flow (login/signup at accounts.empowered.vote → token back via hash fragment) without reading source code
  2. Every compass API endpoint is documented with its URL, auth requirement, request shape, and response shape
  3. The guide explains what anonymous/Inform users can do vs. what Connected users unlock — the degraded vs. enhanced experience is unambiguous
  4. The guide explains how to read `jurisdiction` from `/api/account/me` and use it to personalize compass content without prompting for an address
  5. `docs/COMPASS_CONTRACT.md` is replaced by `docs/COMPASSV2-INTEGRATION.md` as the canonical reference
**Plans:** 1 plan

Plans:
- [x] 32-01: Write docs/COMPASSV2-INTEGRATION.md (ground-up rewrite of COMPASS_CONTRACT.md)

#### Phase 33: Essentials Integration Guide

**Goal:** The Essentials team has a reference document covering the Inform Pillar access pattern, the "never ask address again" jurisdiction principle, and how to surface Connected enhancements as opt-in — enabling correct anonymous and authenticated experiences in one guide.
**Depends on:** Nothing (documentation, no code dependency; can run parallel to Phase 32)
**Requirements:** EDOC-01, EDOC-02, EDOC-03, EDOC-04, EDOC-05, EDOC-06
**Success Criteria** (what must be TRUE):
  1. A developer reading the guide knows exactly when to show a local address input (null jurisdiction) vs. use the Connected user's jurisdiction silently (non-null jurisdiction) — with a concrete code pattern
  2. The guide defines both UX states — anonymous/Inform (local address, no persistence) and Connected (automatic jurisdiction) — and specifies the transition between them
  3. The guide covers how to detect a Connected user without requiring auth, and how to surface a "connect your account" prompt for persistence
  4. All jurisdiction field names and their canonical string formats are listed with real examples from production data
  5. The guide specifies how Essentials can offer Connected enhancements (XP, gem awards, persistence) as opt-in on top of the anonymous experience
**Plans:** 1 plan

Plans:
- [x] 33-01: Write docs/ESSENTIALS-INTEGRATION.md (new file)

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
| 29. Admin Controls & Integration Verification | v1.4 | 2/2 | Complete | 2026-03-15 |
| 30. Profile Hub UI | v1.4 | 2/2 | Complete | 2026-03-16 |
| 31. Referral Dashboard Card | v1.5 | 1/1 | Complete | 2026-03-19 |
| 32. CompassV2 Integration Guide | v1.5 | 1/1 | Complete | 2026-03-19 |
| 33. Essentials Integration Guide | v1.5 | 1/1 | Complete | 2026-03-19 |
