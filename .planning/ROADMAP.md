# Roadmap: Empowered Accounts

## Milestones

- ✅ **v1.0 MVP** — Phases 1–8 (shipped 2026-02-28)
- ✅ **v1.1 XP & Progression** — Phases 9–11 (shipped 2026-03-04)
- ✅ **v1.2 CompassV2 Integration & Alpha Hardening** — Phases 12–16 (shipped 2026-03-07)
- 🚧 **v1.3 Alpha Launch & Location Infrastructure** — Phases 17–24 (in progress)

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

### 🚧 v1.3 Alpha Launch & Location Infrastructure (In Progress)

**Milestone Goal:** Get Alpha live (migrations to production, CompassV2 contract), establish the location privacy infrastructure (encrypted lat/lng, PostGIS jurisdiction resolution), expand the empowered_profiles politician schema for VQ readiness, extend the gem system to three currencies, centralize the profile page in accounts with admin tier-promotion tooling, and transform accounts into the universal Connected Account portal with public signup flow.

#### Phase 17: Live Alpha Deployment
**Goal:** The production Supabase instance is verified live with all v1.2 migrations applied, confirmed by a full smoke test suite.
**Depends on:** Phases 1–16 (prior work)
**Requirements:** DEPLOY-01, DEPLOY-02, DEPLOY-03
**Success Criteria** (what must be TRUE):
  1. Migrations 026–029 are applied to the production Supabase instance and all pre/post verification queries pass.
  2. A deployment runbook exists with migration order, rollback steps, environment checklist, and PostGIS + pgcrypto enablement steps — sufficient for a cold-start re-deploy.
  3. The production smoke test suite passes: health check returns 200, a test auth flow succeeds, compass endpoints return data, the admin UI loads without errors, and the essentials politicians endpoint returns results.
  4. The production environment is demonstrably accessible to Alpha users — not just "migrations ran successfully in a dry run."
**Plans:** 3 plans

Plans:
- [x] 17-01-PLAN.md — Migration apply script (applyMigrations.ts) + deployment runbook (DEPLOY.md)
- [x] 17-02-PLAN.md — Smoke test suite (smokeTest.ts) with 5 endpoint checks
- [x] 17-03-PLAN.md — Production execution checkpoints (human-confirmed deploy)

---

#### Phase 18: CompassV2 API Contract
**Goal:** The accounts API fully satisfies the CompassV2 frontend contract so CompassV2 can authenticate and exchange data without workarounds.
**Depends on:** Phase 17
**Requirements:** CV2-01, CV2-02, CV2-03, CV2-04, CV2-05
**Success Criteria** (what must be TRUE):
  1. An authenticated request using `Authorization: Bearer <token>` (no cookie) succeeds on all authenticated routes — CompassV2 can use its existing token without session cookie setup.
  2. `GET /api/account/me` returns `completed_onboarding: boolean` and the structured `xp` object `{ total, level, xp_in_level, xp_to_next_level }` — the fields CompassV2 reads are present in the documented shape.
  3. `POST /api/auth/signup` accepts and stores the `email` field without error.
  4. Compass answer response shapes from `/api/compass/answers` and the batch endpoint match the CompassV2 repo contract (verified against the contract document, not assumed).
  5. `GET /api/admin/me` returns `{ id, email }` so the admin UI auth store has a non-empty user id.
**Plans:** 4 plans

Plans:
- [x] 18-01-PLAN.md — Migration 030: NUMERIC(3,1) compass values + upsert_compass_answer update + migrate_guest_compass_state RPC
- [x] 18-02-PLAN.md — compass.ts: optionalAuth on 5 routes + decimal value Zod schema
- [x] 18-03-PLAN.md — account.ts: completed_onboarding at root; auth.ts: guest_state on signup
- [x] 18-04-PLAN.md — docs/COMPASS_CONTRACT.md: external-facing API contract for CompassV2

---

#### Phase 19: Location Schema & RPCs
**Goal:** Encrypted coordinates can be written and read via SECURITY DEFINER RPCs, and Indiana TIGER/Line district boundaries are loaded and queryable via PostGIS.
**Depends on:** Phase 17 (production deployment context), Phase 18 (no blocker, but same milestone)
**Requirements:** LOC-01, LOC-02, LOC-03, LOC-04, LOC-05
**Success Criteria** (what must be TRUE):
  1. Calling `connect.upsert_user_location` with a real lat/lng writes encrypted `bytea` values to `connected_profiles`; a subsequent direct DB inspection confirms the columns contain ciphertext, not plaintext floats.
  2. Calling `connect.resolve_user_jurisdiction` for a known Bloomington, IN address returns the correct Indiana 9th congressional district identifier — confirming geometry, SRID, and `ST_Covers` logic are all correct.
  3. `ST_Covers` queries against the loaded boundary tables return the correct Monroe County districts (state senate, state house, county, school district) for that same Bloomington address.
  4. Raw coordinates never appear in the return value of `resolve_user_jurisdiction` — only the jurisdiction JSON struct is returned.
  5. The TIGER/Line data load runbook step is documented (not a migration): ogr2ogr flags, Indiana FIPS filter, SRID reprojection 4269→4326, and post-load SRID verification query.

**Note:** The TIGER/Line data load itself is a runbook step, not a migration. The migration creates the `inform.district_boundaries` table and schema; the runbook populates it.
**Plans:** 3 plans

Plans:
- [x] 19-01-PLAN.md — Migrations 031 + 032: connected_profiles columns, district_boundaries table, upsert_user_location + resolve_user_jurisdiction RPCs
- [x] 19-02-PLAN.md — docs/RUNBOOK-TIGER-LOAD.md: Vault secret, ogr2ogr commands, post-load verification
- [x] 19-03-PLAN.md — Apply migrations, execute runbook, smoke test (human checkpoint)

---

#### Phase 20: Location Endpoints & Validation
**Goal:** An authenticated user can set their address via the API and receive their jurisdiction back, with raw coordinates never appearing in any API response.
**Depends on:** Phase 19
**Requirements:** LOC-06, LOC-07, LOC-08, LOC-09
**Success Criteria** (what must be TRUE):
  1. `POST /api/connect/set-location` with a valid Monroe County address returns jurisdiction data and sets `location_consent = true` — the full flow from address string to jurisdiction works end-to-end.
  2. `POST /api/connect/set-location` with a PO Box address (`PO Box`, `P.O. Box`, or `POB`, case-insensitive) returns a user-facing validation error before any geocoding call is made.
  3. `GET /api/account/me/jurisdiction` returns 403 when `location_consent` is false or null; returns jurisdiction JSON when consent is true.
  4. An architecture test asserts that `encrypted_lat`, `encrypted_lng`, and any plaintext float coordinate representation never appear in route SELECT lists or API response objects — confirmed to pass with 0 violations.
  5. The full location flow (`set-location` → `jurisdiction`) can be exercised against the production environment without exposing plaintext coordinates at any layer (API response, server logs visible to application code, or returned RPC data).
**Plans:** 5 plans

Plans:
- [x] 20-01-PLAN.md — geocodingService.ts (PO Box + Google Maps + confidence filter) + env.ts GOOGLE_MAPS_API_KEY + RUNBOOK-TIGER-LOAD.md LA County section
- [x] 20-02-PLAN.md — connect.ts: POST /api/connect/set-location (geocode -> coverage -> upsert RPC -> jurisdiction RPC)
- [x] 20-03-PLAN.md — account.ts: GET /api/account/me/jurisdiction + location_consent on GET /me
- [x] 20-04-PLAN.md — backend/tests/architecture/coordinateLeakage.test.ts: static analysis test, 0 violations required
- [x] 20-05-PLAN.md — Gap closure: getLocationConsent helper extraction

---

#### Phase 21: empowered_profiles Politician Schema
**Goal:** `inform.politicians` carries the full politician field set (district, jurisdiction, vacancy) so Essentials and Validation Quests can consume representative data without schema gaps.
**Depends on:** Phase 17
**Requirements:** PROF-01, PROF-02, PROF-03
**Success Criteria** (what must be TRUE):
  1. `inform.politicians` contains all politician columns — migration 033 applies cleanly.
  2. `GET /api/essentials/politicians` returns all new fields with names that exactly match what `usePoliticianData.js` in the Essentials repo reads.
  3. `database.types.ts` reflects the updated schema and TypeScript strict compilation passes with 0 errors across backend and admin source.
**Plans:** 2 plans

Plans:
- [ ] 21-01-PLAN.md — Migration 033: 9 new columns on inform.politicians + admin_list_politicians RPC update + database.types.ts
- [ ] 21-02-PLAN.md — essentialsService.ts endpoint update (new fields + is_vacant filter) + seed script + runbook

---

#### Phase 22: Multi-Currency Gem System
**Goal:** The gem ledger supports three currencies (yellow/blue/red), CTC awards yellow gems through the API instead of direct RPC, and balances appear correctly on `/api/account/me`.
**Depends on:** Phase 17, Phase 18
**Requirements:** GEM-01, GEM-02, GEM-03, GEM-04, GEM-05, GEM-06, GEM-07
**Success Criteria** (what must be TRUE):
  1. Calling `POST /api/gems/award` with a valid service key awards yellow gems and the response includes `{ gem_type: 'yellow', amount, new_balance, is_duplicate }` — CTC can migrate off the direct RPC call to this endpoint.
  2. `GET /api/account/me` returns `gems: { yellow: number, blue: number, red: number }` — the structured object replaces the legacy integer `gem_balance` field.
  3. An integration test awards yellow gems via `POST /api/gems/award` and asserts `yellow_gem_balance` increments correctly on the subsequent `GET /api/account/me` response — the balance-always-0 bug is confirmed fixed.
  4. A service key configured for yellow gems only receives 422 if it attempts to award blue or red gems — per-key `permittedTypes` enforcement works.
  5. The admin tool account detail page displays three separate gem balances (yellow / blue / red) replacing the previous single balance display.
**Plans:** TBD

Plans:
- [ ] 22-01: TBD

---

#### Phase 23: Central Profile Page + Admin Tier Promotion
**Goal:** A single accounts-owned profile endpoint aggregates user data for any authenticated or public viewer, replacing per-feature profile views; and admins can manually promote a user from Inform → Connected with a full audit trail.
**Depends on:** Phase 22 (for gem data shape), Phase 20 (for location_consent field)
**Requirements:** PROFILE-01, PROFILE-02, PROFILE-03, PROMO-01, PROMO-02, PROMO-03
**Success Criteria** (what must be TRUE):
  1. `GET /api/account/profile/:userId` returns `{ username, tier, level, total_xp, selected_topic_ids, empowered_profile? }` for any valid userId without authentication — the public profile shape is accessible and contains no sensitive fields (no gems, no tolerance_rating, no location).
  2. `GET /api/account/profile/me` for an authenticated owner returns the public shape plus `{ gem_balances: { yellow, blue, red }, location_consent, email }` — the owner sees their full aggregated profile in one call.
  3. The profile page UI in the admin React app displays the aggregated profile data using the new endpoint — any previous per-feature profile views in the admin tool are replaced.
  4. An admin can search for a user by email OR username in the admin tool, see their current tier, and promote them from Inform → Connected after an explicit confirmation step — no one-click promotes.
  5. Every promotion writes a row to `connect.tier_promotion_log` with: `admin_id`, `target_user_id`, `previous_tier`, `new_tier`, `note` (optional), `created_at` — and the log is visible in the admin tool.
  6. Attempting to promote a user who is already Connected or Empowered returns a user-facing error without writing a log row.
**Plans:** TBD

Plans:
- [ ] 23-01: TBD

---

#### Phase 24: Public Auth Hub (Login Rebrand + Signup Flow)
**Goal:** `accounts.empowered.vote` becomes the universal Connected Account portal — the login page is rebranded for civic participants, a `/signup` route creates Connected Accounts, post-login routing reflects the user's actual tier, and other apps can redirect here with a `?redirect=` param.
**Depends on:** Phase 23 (profile infrastructure for post-login Connected dashboard)
**Requirements:** HUB-01, HUB-02, HUB-03, HUB-04
**Success Criteria** (what must be TRUE):
  1. The login page at `accounts.empowered.vote/login` shows Connected Account-centric language ("Sign in to your Connected Account") with a visible "Don't have an account? Create one" link — no admin-first framing visible to non-admins on first load.
  2. After login, users are routed by tier: first-time → onboarding; Connected → Connected dashboard; Empowered → Empowered view; Admin → admin panel. An admin account and a Connected account tested back-to-back land on different pages.
  3. `accounts.empowered.vote/signup` completes a Connected Account creation (email + password + required profile fields) and redirects to onboarding — Validation Quests can link here and users land back after auth.
  4. `?redirect=https://quests.empowered.vote/feed` on both `/login` and `/signup` routes the user to the provided URL after success — and a URL from an untrusted domain is ignored (redirects to default instead).
**Plans:** TBD

Plans:
- [ ] 24-01: TBD

---

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
| 21. empowered_profiles Politician Schema | v1.3 | 0/2 | Not started | - |
| 22. Multi-Currency Gem System | v1.3 | 0/? | Not started | - |
| 23. Central Profile Page + Admin Tier Promotion | v1.3 | 0/? | Not started | - |
| 24. Public Auth Hub (Login Rebrand + Signup Flow) | v1.3 | 0/? | Not started | - |
