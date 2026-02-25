# Roadmap: Empowered Accounts

## Overview

Eight phases that build the foundational three-tier account infrastructure for Empowered Vote from the ground up. Every phase depends on the previous: the database schema and security primitives must exist before any route is written; auth before any user flow; enrollment before real users can enter; compass before empowerment can be validated; empowerment before social graph and civic economy make sense; and the operational layer (admin, scheduler, public API) last — once there is real data to manage and enforce against.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation** - Complete Supabase schema, RLS policies, RPC functions, dual client pattern, JWT middleware, health check
- [ ] **Phase 2: Auth Routes and Account Core** - Sign up, login, logout, /api/account/me read and update
- [ ] **Phase 3: Alpha Enrollment** - Connect verification flow + invite system (the complete enrollment pipeline)
- [ ] **Phase 4: Compass Routes** - Topic calibration, change history, completeness check, compare endpoint
- [ ] **Phase 5: Empower Flow** - Preflight checks, atomic empowerment, atomic demotion, slug generation
- [ ] **Phase 6: Gems, Roles, and Social Graph** - Gem ledger, role system, peer connections, follows
- [ ] **Phase 7: Admin Tool and Calibration Cron** - React admin UI, /api/admin/* routes, daily lapse enforcement scheduler
- [ ] **Phase 8: Public Candidate Pages** - Unauthenticated /api/candidates/:slug with field projection enforcement

## Phase Details

### Phase 1: Foundation
**Goal**: The database is the source of truth for all tier logic, security, and atomic transitions — and it is fully defined, RLS-enforced, and tested before any application code runs
**Depends on**: Nothing (first phase)
**Requirements**: FOUND-01, FOUND-02, FOUND-03, FOUND-04, FOUND-05, FOUND-06, FOUND-07, FOUND-08, FOUND-09
**Success Criteria** (what must be TRUE):
  1. All Supabase migrations apply cleanly via CLI and produce the correct 4-schema structure (public, connect, empower, inform) with no manual Studio changes required
  2. RLS policy tests (SQL `SET LOCAL` impersonation) confirm that `tolerance_rating` and `legal_name` are inaccessible to any non-owning user role — not merely absent from a response but blocked at the database layer
  3. `supabase.rpc('execute_empowerment', ...)` and `supabase.rpc('execute_demotion', ...)` roll back all changes on a simulated exception — no partial state survives
  4. `GET /api/health` returns `{ status: 'ok', timestamp: <number> }` with a 200 status and the service starts with invalid env vars producing a startup error, not a silent misconfiguration
  5. The dual Supabase client pattern is enforced: `supabaseAdmin` is never used in any code path that returns data to a user; user-scoped client (anon key + user JWT) is used for all reads that feed API responses
**Plans**: TBD

Plans:
- [ ] 01-01: Schema migrations — all 4 schemas, all tables, all RLS policies, all RPC functions
- [ ] 01-02: Server bootstrap — project setup, dual Supabase client, JWT middleware, Zod env validation, health endpoint

### Phase 2: Auth Routes and Account Core
**Goal**: Users can create accounts, authenticate, and access their tier-appropriate profile — and the API enforces field-level privacy on every response
**Depends on**: Phase 1
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05
**Success Criteria** (what must be TRUE):
  1. A new user can sign up with email and password; a `public.users` record is created automatically via trigger with no separate API call required
  2. A logged-in user can call `GET /api/account/me` and receive their own `tolerance_rating`; a different authenticated user calling the same endpoint cannot see that field in the response
  3. A Connected user can call `PATCH /api/account/me` and change their display name; the update persists across sessions
  4. After calling `POST /api/auth/logout`, the session token is invalidated and subsequent authenticated requests return 401
**Plans**: TBD

Plans:
- [ ] 02-01: Auth routes (signup, login, logout) and public.users trigger
- [ ] 02-02: Account routes (GET /api/account/me, PATCH /api/account/me) with field-level privacy enforcement

### Phase 3: Alpha Enrollment
**Goal**: Invite-only access is enforced and the full enrollment pipeline — from receiving an invite to holding a verified Connected profile — is complete and abuse-resistant
**Depends on**: Phase 2
**Requirements**: CONN-01, CONN-02, CONN-03, CONN-04, INVT-01, INVT-02, INVT-03, INVT-04, INVT-05
**Success Criteria** (what must be TRUE):
  1. A user who abandons the Connect flow mid-way can resume it in a new session without restarting; the verification session state persists
  2. After completing the Connect flow, a `connected_profiles` record with `verification_status: 'verified'` exists; the user cannot repeat the flow to create a second record
  3. Anonymous compass calibration stored in localStorage is importable during Connect; topic version mismatches are flagged for user confirmation before saving; localStorage is cleared only after successful import
  4. An invite code cannot be claimed by two concurrent requests; self-invitation is blocked; a plus-addressed email variant of an existing address is treated as the same address
  5. When an invitee is sanctioned, the direct inviter's Tolerance Rating is adjusted; the adjustment does not propagate to the inviter's inviter
**Plans**: TBD

Plans:
- [ ] 03-01: Invite system (code generation, claim atomicity, chain storage, rate limiting, Tolerance Rating cascade)
- [ ] 03-02: Connect flow (verification session, status check, connected_profiles creation, compass import)

### Phase 4: Compass Routes
**Goal**: Users can calibrate their political compass, track changes over time, and compare stances with others — with visibility rules enforced at the API layer
**Depends on**: Phase 3
**Requirements**: COMP-01, COMP-02, COMP-03, COMP-04, COMP-05
**Success Criteria** (what must be TRUE):
  1. A user can view all live compass topics with their 5 stances and calibrate a response; a second calibration on the same topic updates the response and appends a new record to `compass_change_history`
  2. `GET /api/compass/progress` returns a completeness score that reflects the correct threshold for the user's role (city council candidate vs. US Congress candidate thresholds differ)
  3. `GET /api/compass/compare/:userId` returns stances only if the target user's `visibility` permits it — a user with `visibility: 'friends'` shares data only with accepted peer connections; the comparison response never includes `tolerance_rating`
  4. A user's own `GET /api/compass` returns their `inverted` preferences per topic
**Plans**: TBD

Plans:
- [ ] 04-01: Compass read routes (topic list, own responses, progress check with role filtering)
- [ ] 04-02: Compass write routes (calibrate, compare with visibility enforcement)

### Phase 5: Empower Flow
**Goal**: Empowerment and demotion are atomic — they succeed completely or fail completely — and the preflight check catches every invalid state before a transaction is attempted
**Depends on**: Phase 4
**Requirements**: EMPR-01, EMPR-02, EMPR-03, EMPR-04
**Success Criteria** (what must be TRUE):
  1. `POST /api/empower/preflight` returns a specific failure reason when any required condition is unmet (unverified status, incomplete calibration, missing legal name, missing consent) — not a generic error
  2. After a successful `POST /api/empower/confirm`, the user has an `empowered_profiles` record, all their compass responses have `visibility: 'public'`, and a `candidate_page_slug` exists — or none of those things exist (full rollback confirmed via simulated transaction failure)
  3. Two users with identical legal names who empower simultaneously each receive a unique slug; neither slug is a duplicate of an existing slug
  4. After demotion, the user's `empowered_profiles.is_active` is false and all their compass responses have `visibility: 'private'`; re-empowerment via the same preflight + confirm path is available after completing calibration
**Plans**: TBD

Plans:
- [ ] 05-01: Empower flow (preflight, confirm via execute_empowerment RPC, slug collision handling)
- [ ] 05-02: Demotion flow (execute_demotion RPC, re-empowerment path)

### Phase 6: Gems, Roles, and Social Graph
**Goal**: The civic economy (gem ledger), civic function assignment (role system), and social connections are fully operational — with the peer connection table enabling compass visibility enforcement from Phase 4
**Depends on**: Phase 5
**Requirements**: CIVIC-01, CIVIC-02, CIVIC-03, CIVIC-04, SOCL-01, SOCL-02, SOCL-03
**Success Criteria** (what must be TRUE):
  1. A gem debit that would take the balance negative is rejected atomically — a concurrent debit and a check that passes simultaneously cannot both succeed
  2. A stipend that would push a user's gem balance above the reserve cap silently caps at the reserve; no error is returned, no excess gems are granted
  3. A role with tier eligibility requirements (e.g., Maven requires Empowered) cannot be granted to a Connected user; the API returns a clear rejection
  4. Two Connected users can send, accept, decline, and block peer connection requests; after blocking, neither user can send a new request to the other
  5. A Connected user can follow an Empowered account and unfollow it; following does not require approval from the Empowered account
**Plans**: TBD

Plans:
- [ ] 06-01: Gem ledger (append-only transactions, atomic debit enforcement, reserve cap at stipend)
- [ ] 06-02: Role system (grant, revoke with soft revocation, conflict enforcement, tier eligibility)
- [ ] 06-03: Social graph (peer connections with full state machine, follows)

### Phase 7: Admin Tool and Calibration Cron
**Goal**: Administrators can manage the Alpha cohort through a secure internal UI, and the platform automatically enforces calibration commitments via a daily scheduled job — with every action and every automated event logged
**Depends on**: Phase 6
**Requirements**: ADMN-01, ADMN-02, ADMN-03, ADMN-04, ADMN-05, ADMN-06, CRON-01, CRON-02, CRON-03, CRON-04
**Success Criteria** (what must be TRUE):
  1. An admin can log in, view an account's `tolerance_rating` and `legal_name` in the admin UI, and every such access is recorded in `admin_audit_log` with actor, action, target, and timestamp — no admin action can be performed without an audit log entry
  2. Being an authenticated user with a valid JWT is not sufficient to access any `/api/admin/*` route; only users present in `admin_users` can proceed
  3. An admin can create an invite code, view the full invite chain for any account, revoke an active code, and trace the invite tree — all through the React admin UI
  4. The daily 2am UTC cron job runs exactly once per calendar day even across server restarts or deploys; running it twice on the same day produces no additional demotions
  5. An Empowered user who has not calibrated a new live topic for 25 days receives a warning event; at 30 days, `execute_demotion` is called and the user is notified of the specific topic(s) requiring calibration
**Plans**: TBD

Plans:
- [ ] 07-01: Admin API routes (/api/admin/* with requireAdmin middleware, audit logging on every action)
- [ ] 07-02: Admin React UI (Vite app — invite management, account review, cohort enrollment, invite chain visualization)
- [ ] 07-03: Calibration lapse cron (node-cron scheduler, idempotency table, day-25 warning event, day-30 demotion)

### Phase 8: Public Candidate Pages
**Goal**: Anyone on the internet can look up an Empowered candidate's public compass stances and legal name — with `tolerance_rating` enforced absent from every response, and inactive candidate pages returning a consistent, non-reassignable state
**Depends on**: Phase 7
**Requirements**: CAND-01, CAND-02, CAND-03
**Success Criteria** (what must be TRUE):
  1. `GET /api/candidates/:slug` returns the candidate's legal name, candidate page metadata, and public compass stances without requiring any authentication header
  2. No response from `GET /api/candidates/:slug` includes `tolerance_rating` — confirmed by integration test asserting the field is absent, not merely null, at both the RLS layer and the serialization layer
  3. A slug belonging to a demoted (inactive) Empowered account returns a consistent inactive state response; the slug cannot be claimed by a new user with the same legal name
**Plans**: TBD

Plans:
- [ ] 08-01: Public candidate page route with field projection enforcement and inactive state handling

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 0/2 | Not started | - |
| 2. Auth Routes and Account Core | 0/2 | Not started | - |
| 3. Alpha Enrollment | 0/2 | Not started | - |
| 4. Compass Routes | 0/2 | Not started | - |
| 5. Empower Flow | 0/2 | Not started | - |
| 6. Gems, Roles, and Social Graph | 0/3 | Not started | - |
| 7. Admin Tool and Calibration Cron | 0/3 | Not started | - |
| 8. Public Candidate Pages | 0/1 | Not started | - |
