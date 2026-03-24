# Roadmap: Empowered Accounts

## Milestones

- ✅ **v1.0 MVP** — Phases 1–8 (shipped 2026-02-28)
- ✅ **v1.1 XP & Progression** — Phases 9–11 (shipped 2026-03-04)
- ✅ **v1.2 CompassV2 Integration & Alpha Hardening** — Phases 12–16 (shipped 2026-03-07)
- ✅ **v1.3 Alpha Launch & Location Infrastructure** — Phases 17–26 (shipped 2026-03-15)
- ✅ **v1.4 Profile Hub & Verification Engine** — Phases 27–30 (shipped 2026-03-17)
- ✅ **v1.5 Partner Integration & Referrals** — Phases 31–33 (shipped 2026-03-19)
- 🔄 **v1.6 Platform Consolidation** — Phases 34–43 (in progress)
- 📋 **v1.7 Cross-App SSO** — Phases 44–48 (planned)

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

<details>
<summary>✅ v1.5 Partner Integration & Referrals (Phases 31–33) — SHIPPED 2026-03-19</summary>

- [x] Phase 31: Referral Dashboard Card (1/1 plan) — completed 2026-03-19
- [x] Phase 32: CompassV2 Integration Guide (1/1 plan) — completed 2026-03-19
- [x] Phase 33: Essentials Integration Guide (1/1 plan) — completed 2026-03-19

Full details: `.planning/milestones/v1.5-ROADMAP.md`

</details>

### v1.6 Platform Consolidation (Phases 34–43)

---

#### Phase 34: Database Schema Migration

**Goal:** The ev-accounts Supabase project contains all EV-Backend tables with RLS enforced and grants correctly scoped — no application code changes yet, just schema parity.

**Dependencies:** None (pre-flight work; all subsequent phases depend on this)

**Requirements:** CONS-01, CONS-02, CONS-03, CONS-04

**Plans:** 3 plans

Plans:
- [x] 34-01-PLAN.md — Pre-flight verification: enumerate tables, detect user_id columns, capture row counts
- [x] 34-02-PLAN.md — RLS migrations for 5 public-read schemas (essentials, meetings, treasury, transparent_motivations, compass)
- [x] 34-03-PLAN.md — RLS migration for staging (authenticated-only read) + comprehensive verification

**Success Criteria:**

1. All six schemas (`essentials`, `staging`, `treasury`, `meetings`, `validation_quests`, `trivia`) exist in the ev-accounts Supabase project and are visible in the dashboard.
2. Row counts in ev-accounts match row counts in EV-Backend for every imported table (52 tables verified).
3. `SELECT * FROM pg_policies WHERE schemaname IN ('essentials','staging','treasury','meetings','validation_quests','trivia')` returns at least one policy per table — zero unprotected tables.
4. Service role and anon role GRANT statements are applied; a request authenticated as anon cannot read rows that require auth on any migrated table.

---

#### Phase 35: Politician Deduplication

**Goal:** `essentials.politicians` is the single source of truth for all politician records — compass answers, context, and VQ confirmation all reference the unified ID space with no data loss.

**Dependencies:** Phase 34 (essentials schema must exist and be populated)

**Requirements:** CONS-05, CONS-06, CONS-07

**Plans:** 2 plans

Plans:
- [x] 35-01-PLAN.md — Atomic migration: bridge table, FK reassignment, RPC rebuilds, DROP inform.politicians
- [x] 35-02-PLAN.md — Application code updates: schema switch to essentials + PostgREST fix

**Success Criteria:**

1. `public.politician_id_bridge` exists and contains one row per politician, mapping both the former `inform` ID and the `essentials` ID.
2. `GET /api/compass/politicians/:id/answers` returns correct stances after the FK migration — results match the pre-migration baseline.
3. `\dt inform.*` in psql returns no `politicians` table; all join paths through `inform.politician_answers` and `inform.politician_context` resolve against `essentials.politicians`.
4. The VQ confirmation RPC (`confirm_vq_stance`) completes without FK violation errors when called with valid `essentials.politicians` IDs.

---

#### Phase 36: Express Ports Wave 1 — Treasury and Meetings

**Goal:** Treasury and Meetings data is served by the ev-accounts Express API — the Go server is no longer the authoritative source for these routes.

**Dependencies:** Phase 34 (schemas and data must be in ev-accounts)

**Requirements:** CONS-08, CONS-09

**Plans:** 2 plans

Plans:
- [x] 36-01-PLAN.md — Treasury service layer and routes (5 public reads + 4 admin writes)
- [x] 36-02-PLAN.md — Meetings service layer and routes (5 public reads + 3 admin writes)

**Success Criteria:**

1. All Treasury endpoints (~9 routes) return well-formed responses designed from the Supabase schema when called against ev-accounts (Supabase-first design, not Go parity).
2. All Meetings endpoints (~8 routes) return correct data for public reads; admin write routes reject requests without a valid admin JWT.
3. A curl smoke test hitting each new route on the Render staging deployment returns HTTP 200 (or 201/204 where appropriate) with no 500 errors.
4. No Treasury or Meetings route requires the Go server to be running — ev-accounts handles all requests end-to-end.

---

#### Phase 37: Express Ports Wave 2 — Staging

**Goal:** The Staging review workflow runs entirely on ev-accounts — role-gated submission, review, and approval routes are operational and enforce the same access rules as the Go server.

**Dependencies:** Phase 34 (staging schema must exist); Phase 36 (establishes endpoint port pattern)

**Requirements:** CONS-10

**Plans:** 4 plans

Plans:
- [x] 37-01-PLAN.md — Migrations (staging_reviewer role + status defaults) + requireStagingReviewer middleware
- [x] 37-02-PLAN.md — Staging service: politician CRUD, review, lock, merge, auto-promotion
- [x] 37-03-PLAN.md — Staging service: stance + building photo CRUD, review, auto-promotion
- [x] 37-04-PLAN.md — Staging routes (18 handlers) + index.ts registration + smoke tests

**Success Criteria:**

1. All Staging endpoints (~15 routes) respond correctly; role-gated routes return 403 for requests without the required role claim.
2. A complete submission-to-approval flow can be executed end-to-end via the ev-accounts API with no Go server involvement.
3. The review workflow state machine (submit → review → approve/reject) transitions correctly and is reflected in database state after each step.

---

#### Phase 38: Express Ports Wave 3 — Essentials

**Goal:** Essentials address-to-politician lookup and all supporting routes are served by ev-accounts — including PostGIS-backed jurisdiction resolution using Census Geocoder — matching the Go server's public contract.

**Dependencies:** Phase 34 (essentials schema); Phase 35 (unified politician IDs); Phase 36/37 (endpoint port pattern established)

**Requirements:** CONS-11

**Plans:** 5 plans

Plans:
- [x] 38-01-PLAN.md — Schema investigation + Census Geocoder rewrite + env.ts update
- [x] 38-02-PLAN.md — Address-search endpoint + politicians list Go-parity rewrite
- [x] 38-03-PLAN.md — Politician detail endpoint (GET /politicians/:id)
- [x] 38-04-PLAN.md — Legislative subroutes (legislative, committees, bills, votes)
- [x] 38-05-PLAN.md — Entity routes (governments, chambers, districts) + index.ts registration

**Success Criteria:**

1. All Essentials core endpoints (~25 routes) respond with the same shape as Go equivalents.
2. The address-to-politician lookup flow — Census Geocoder → PostGIS boundary match → politician list — returns correct results for a known Indiana address.
3. Unauthenticated requests receive Inform-baseline responses; Connected users with jurisdiction receive enhanced responses — consistent with the ESSENTIALS-INTEGRATION.md contract.
4. `GET /api/essentials/politicians` returns all fields including the 9 `empowered_profiles` politician schema columns added in v1.3.

---

#### Phase 39: Compass Additions

**Goal:** The full compass feature set is complete — missing endpoints are implemented, the value range supports decimal stances, and CompassV2 can use every compass capability without hitting the Go server.

**Dependencies:** Phase 35 (unified politician IDs required for compare and batch politician answers)

**Requirements:** CONS-12, CONS-13

**Plans:** 3 plans

Plans:
- [x] 39-01-PLAN.md — Database migration: value range, verdicts table, updated RPCs
- [x] 39-02-PLAN.md — Public routes: compare, verdicts, batch politician answers
- [x] 39-03-PLAN.md — Admin compass routes at Go-compatible /api/compass/* paths

**Success Criteria:**

1. All missing compass endpoints are reachable: compare, verdicts, admin CRUD, and batch politician answers — each returns well-formed responses.
2. A compass response with `value = 0.5` and a response with `value = 5.5` both insert successfully; values outside the new range are rejected by the CHECK constraint.
3. Existing compass responses with integer values 1–5 remain valid after the constraint migration (no data loss).
4. The CompassV2 integration guide checklist passes end-to-end with no Go server dependency remaining for compass routes.

---

#### Phase 40: Frontend Auth Updates

**Goal:** All four frontend apps authenticate against ev-accounts using Bearer tokens and correct API URLs — cookie-based auth to the Go server is fully replaced.

**Dependencies:** Phase 36, Phase 37, Phase 38, Phase 39 (all endpoint ports must be complete before frontends switch targets)

**Requirements:** CONS-14, CONS-15, CONS-16, CONS-17

**Plans:** 5 plans

Plans:
- [x] 40-01-PLAN.md — Auth Hub redirect-after-login + re-auth banner
- [x] 40-02-PLAN.md — CompassV2 Bearer token migration (20+ files)
- [x] 40-03-PLAN.md — Essentials Bearer token migration + Sign In link
- [x] 40-04-PLAN.md — Read & Rank Bearer token migration + Treasury Tracker proxy update
- [x] 40-05-PLAN.md — Cutover runbook (three-party coordination)

**Status:** Complete — 2026-03-23

**Success Criteria:**

1. CompassV2 completes a full user session (login → calibration → compare) using `Authorization: Bearer` headers against the ev-accounts API URL with no cookie dependency.
2. Essentials app completes a full Inform-to-Connected flow using Bearer token auth against ev-accounts.
3. Read & Rank authenticates via Bearer token and all existing features function correctly.
4. Treasury Tracker loads public treasury data from the ev-accounts API URL; no requests reach the Go server's API URL.

---

#### Phase 41: VQ and Trivia Migration

**Goal:** Validation Quests and Civic Trivia databases are fully consolidated into ev-accounts — both apps point to the ev-accounts Supabase project and all FK references resolve against unified politician IDs.

**Dependencies:** Phase 34 (schemas exist); Phase 35 (essentials.politicians as FK target)

**Requirements:** CONS-18, CONS-19

**Plans:** 4 plans

Plans:
- [x] 41-01-PLAN.md — Pre-flight inspection: enumerate tables, row counts, FK gap analysis, Trivia connection model
- [x] 41-02-PLAN.md — trivia_service role creation + GET /api/trivia/leaderboard-profiles endpoint
- [x] 41-03-PLAN.md — RLS migration for validation_quests and trivia tables
- [x] 41-04-PLAN.md — Cutover: VQ anon key verified, CTC reconnected, smoke tests passed

**Success Criteria:**

1. `validation_quests` schema exists in ev-accounts with all imported tables; VQ's Render service `DATABASE_URL` points to ev-accounts and the VQ app connects successfully on startup.
2. `trivia` schema exists in ev-accounts; trivia politician foreign keys resolve against `essentials.politicians` with no FK violation errors.
3. A VQ confirmation flow (`POST /api/vq/confirm-stance`) completes successfully end-to-end after the migration with correct VR adjustments and gem awards.
4. RLS is active on all `validation_quests` and `trivia` tables; a smoke test confirms unauthenticated requests cannot access user-specific rows.

---

#### Phase 42: Decommission and DNS Cutover

**Goal:** EV-Backend is retired and `api.empowered.vote` resolves to the ev-accounts Express server — there is exactly one API for the entire Empowered Vote platform.

**Dependencies:** Phase 36, Phase 37, Phase 38, Phase 39, Phase 40, Phase 41 (all endpoints ported; all frontends updated; VQ/Trivia migrated)

**Requirements:** CONS-20, CONS-21, CONS-22

**Plans:** 2 plans

Plans:
- [ ] 42-01-PLAN.md — URL cleanup and decommission runbook creation
- [ ] 42-02-PLAN.md — Cutover execution (human-gated dashboard operations)

**Success Criteria:**

1. Go server request logs show zero traffic over a 24-hour monitoring window before cutover is initiated.
2. EV-Backend is scaled to zero on Render and the Go repo is archived on GitHub; the Go server does not respond to HTTP requests.
3. `api.empowered.vote` resolves to the ev-accounts server; `curl https://api.empowered.vote/api/health` returns `{"status":"ok"}` from the Express handler.
4. CORS headers on ev-accounts allow all production frontend origins; frontend env vars across all four apps point to `api.empowered.vote` with no lingering Go server URLs.

---

#### Phase 43: Integration Documentation

**Goal:** Chris Andrews' team has a single updated integration reference that accurately describes every API change made during the consolidation — auth model, unified politician IDs, new schemas, value range fix, and endpoint inventory.

**Dependencies:** Phase 42 (documentation reflects final state — only written after all changes are shipped)

**Requirements:** CONS-23

**Success Criteria:**

1. The integration doc covers all four fronts of change: auth model (Bearer token only), unified `essentials.politicians` ID format with bridge table note, compass value range (0.5–5.5), and new schema inventory (essentials, staging, treasury, meetings, validation_quests, trivia).
2. Each new or changed endpoint is listed with its method, path, auth requirement, and example request/response shape.
3. Anti-patterns from the migration are documented inline at the relevant section (e.g., "do not use the old Go server URL", "do not pass inform.politicians IDs — use essentials.politicians IDs").
4. A human reading only this doc can update a partner integration from Go-server state to ev-accounts state without needing to read source code.

---

### v1.7 Cross-App SSO (Phases 44–48)

---

#### Phase 44: Accounts API SSO Infrastructure

**Goal:** The ev-accounts API issues and reads the shared `ev_session` cookie — the foundation all other phases depend on. A user who logs in receives the cookie; any app can silently exchange it for fresh tokens; logout clears it everywhere.

**Dependencies:** None (all other v1.7 phases depend on this phase)

**Requirements:** SSO-01, SSO-02, SSO-03

**Plans:** 2 plans

Plans:
- [ ] 44-01-PLAN.md — Login cookie issuance: set httpOnly `ev_session` on `.empowered.vote` at login; `POST /api/auth/logout` clears cookie + revokes Supabase session
- [ ] 44-02-PLAN.md — `GET /api/auth/session` endpoint: CORS config for `*.empowered.vote`, cookie read, Supabase token exchange, 401 fast-fail on missing cookie

**Success Criteria:**

1. After `POST /api/auth/login`, the response includes `Set-Cookie: ev_session=...; Domain=.empowered.vote; HttpOnly; Secure; SameSite=Lax` with the Supabase refresh token as the cookie value.
2. `GET /api/auth/session` with a valid `ev_session` cookie returns `{ access_token, refresh_token }` (HTTP 200); without the cookie it returns HTTP 401 with no error body.
3. `POST /api/auth/logout` clears the `ev_session` cookie (Set-Cookie with Max-Age=0) and revokes the Supabase session — a subsequent `GET /api/auth/session` call returns 401.
4. `GET /api/auth/session` responds with correct CORS headers (`Access-Control-Allow-Origin: <requesting *.empowered.vote origin>`, `Access-Control-Allow-Credentials: true`) for requests from all EV app origins.

---

#### Phase 45: Profile Hub + CTC Silent SSO

**Goal:** Profile Hub and CTC automatically inherit an active session on load — a user already logged in at accounts.empowered.vote arrives at either app already authenticated without a re-login prompt. Logout at either app clears the shared cookie.

**Dependencies:** Phase 44 (session endpoint must exist before frontends can call it)

**Requirements:** SSO-04, SSO-05, SSO-06

**Plans:** 2 plans

Plans:
- [ ] 45-01-PLAN.md — Profile Hub (`app/src`): silent session check in AuthInitializer before rendering unauthenticated state; wire existing auth store to accept tokens from session exchange
- [ ] 45-02-PLAN.md — CTC (`C:\Project Test\frontend`): silent session check if no `ev_refresh_token` in localStorage; logout calls `POST /api/auth/logout` to clear shared cookie

**Success Criteria:**

1. A user authenticated at `accounts.empowered.vote` who navigates to `app.empowered.vote` (Profile Hub) in the same browser is shown their authenticated profile without a login prompt.
2. A user authenticated at `accounts.empowered.vote` who opens CTC in the same browser starts a game session as their authenticated user without re-entering credentials.
3. Logging out from CTC results in the `ev_session` cookie being cleared; a subsequent navigation to any EV app shows the unauthenticated (Inform-baseline) state.
4. If no shared session exists (cookie absent or expired), both apps render their unauthenticated state silently — no error message, no redirect loop.

---

#### Phase 46: Essentials + CompassV2 Silent SSO

**Goal:** Essentials and CompassV2 automatically inherit an active session on load using the same silent-check pattern — both apps degrade gracefully to Inform-baseline when no session exists.

**Dependencies:** Phase 44 (session endpoint must exist)

**Requirements:** SSO-07, SSO-08, SSO-11, SSO-12

**Plans:** 2 plans

Plans:
- [ ] 46-01-PLAN.md — Essentials (`C:\Transparent Motivations\essentials`): silent session check in auth bootstrap; logout calls `POST /api/auth/logout`
- [ ] 46-02-PLAN.md — CompassV2 (`C:\EV-CompassV2`): `git pull` first; silent session check in AuthInitializer / `publicFetch` flow; logout calls `POST /api/auth/logout`

**Success Criteria:**

1. A user authenticated at any EV app who navigates to Essentials receives Connected-enhanced responses (jurisdiction-aware politician list) without re-login.
2. A user authenticated at any EV app who opens CompassV2 loads their existing compass answers and calibration state without re-login.
3. Logging out from Essentials or CompassV2 clears the `ev_session` cookie; a subsequent navigation to any EV app shows the unauthenticated state.
4. Both apps degrade gracefully to full Inform-baseline functionality when no session exists — no error banner, no broken UI state.

---

#### Phase 47: Validation Quests Silent SSO

**Goal:** Validation Quests automatically inherits an active session using Supabase's native session API — a user already logged in elsewhere arrives at VQ with an active Supabase session initialized, without re-login.

**Dependencies:** Phase 44 (session endpoint must exist); VQ uses Supabase JS client directly, so the handoff mechanism is `supabase.auth.setSession()` rather than localStorage

**Requirements:** SSO-09, SSO-10

**Plans:** ~2 plans

Plans:
- [ ] 47-01-PLAN.md — VQ (`C:\Validation Quests`): on load, if `supabase.auth.getSession()` returns null, silently call `GET /api/auth/session` and initialize via `supabase.auth.setSession({ access_token, refresh_token })`
- [ ] 47-02-PLAN.md — VQ logout: call `POST /api/auth/logout` in addition to `supabase.auth.signOut()` to clear shared cookie; verify no double-signout errors

**Success Criteria:**

1. A user authenticated at any EV app who opens VQ has an active Supabase session (Supabase JS client reports `session !== null`) without re-entering credentials.
2. VQ's Supabase-native auth flows (RLS-gated queries, quest assignment reads) work correctly after SSO session initialization via `setSession()`.
3. Logging out from VQ clears the `ev_session` cookie; a subsequent visit to VQ or any other EV app shows the unauthenticated state.
4. If VQ calls `GET /api/auth/session` and receives a 401 (no cookie), VQ renders its unauthenticated state silently — no exception thrown, no error surfaced to the user.

---

#### Phase 48: Compliance + End-to-End Verification

**Goal:** The `ev_session` cookie is disclosed in the privacy policy as strictly necessary for authentication, and SSO works correctly end-to-end across all five apps in a real browser session.

**Dependencies:** Phases 44–47 (all apps must implement SSO before cross-app smoke test is meaningful)

**Requirements:** SSO-13

**Plans:** ~2 plans

Plans:
- [ ] 48-01-PLAN.md — Privacy disclosure: add `ev_session` cookie documentation to privacy policy / cookie disclosure on `accounts.empowered.vote`; classify as strictly necessary (no consent banner required)
- [ ] 48-02-PLAN.md — Cross-app smoke test: manual E2E verification — login at accounts, confirm session inheritance at all five apps, confirm single-logout clears session everywhere

**Success Criteria:**

1. The privacy policy or cookie disclosure page on `accounts.empowered.vote` names the `ev_session` cookie, describes its purpose (session continuity across EV apps), its domain (`.empowered.vote`), and classifies it as strictly necessary — no opt-in banner displayed.
2. A single login at `accounts.empowered.vote` results in authenticated state at Profile Hub, CTC, Essentials, CompassV2, and Validation Quests without any additional login prompts.
3. A single logout from any one app results in unauthenticated state at all apps — the `ev_session` cookie is absent and `GET /api/auth/session` returns 401.
4. All five apps render their full Inform-baseline experience when no session is present — no broken pages, no error states, no redirect loops.

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
| 34. Database Schema Migration | v1.6 | 3/3 | Complete | 2026-03-20 |
| 35. Politician Deduplication | v1.6 | 2/2 | Complete | 2026-03-20 |
| 36. Express Ports Wave 1 — Treasury + Meetings | v1.6 | 2/2 | Complete | 2026-03-20 |
| 37. Express Ports Wave 2 — Staging | v1.6 | 4/4 | Complete | 2026-03-20 |
| 38. Express Ports Wave 3 — Essentials | v1.6 | 5/5 | Complete | 2026-03-20 |
| 39. Compass Additions | v1.6 | 3/3 | Complete | 2026-03-20 |
| 40. Frontend Auth Updates | v1.6 | 5/5 | Complete | 2026-03-23 |
| 41. VQ and Trivia Migration | v1.6 | 4/4 | Complete | 2026-03-24 |
| 42. Decommission and DNS Cutover | v1.6 | 0/? | Pending | — |
| 43. Integration Documentation | v1.6 | 0/? | Pending | — |
| 44. Accounts API SSO Infrastructure | v1.7 | 2/2 | Complete | 2026-03-24 |
| 45. Profile Hub + CTC Silent SSO | v1.7 | 2/2 | Complete | 2026-03-24 |
| 46. Essentials + CompassV2 Silent SSO | v1.7 | 0/2 | Pending | — |
| 47. Validation Quests Silent SSO | v1.7 | 0/2 | Pending | — |
| 48. Compliance + End-to-End Verification | v1.7 | 0/2 | Pending | — |
