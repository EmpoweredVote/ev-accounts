# Requirements: Empowered Accounts

**Defined:** 2026-02-24
**Core Value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.

## v1 Requirements

### Foundation (FOUND)

- [x] **FOUND-01**: Complete Supabase schema across all 4 schemas (public, connect, empower, inform) delivered as numbered CLI migrations — no manual Studio changes, ever
- [x] **FOUND-02**: RLS policies on every table enforced at the database level; `tolerance_rating` and `legal_name` never accessible to non-owning users via any policy
- [x] **FOUND-03**: Postgres RPC functions for empowerment (`execute_empowerment`), demotion (`execute_demotion`), and calibration lapse query (`get_calibration_lapsed_users`) — SECURITY DEFINER, full rollback on any exception
- [x] **FOUND-04**: Dual Supabase client pattern: `supabaseAdmin` (service role, trusted writes only — never used for reads that feed API responses) + per-request user-scoped client (anon key + user JWT, RLS enforced)
- [x] **FOUND-05**: JWT middleware with local JWKS verification (avoids network round-trip per request); JWT verification includes issuer and audience validation
- [x] **FOUND-06**: `GET /api/health` returns `{ status: 'ok', timestamp: Date.now() }` — first endpoint built
- [x] **FOUND-07**: Env var validation at startup via Zod; service role key validated as present, never logged, never returned in any response
- [x] **FOUND-08**: `admin_audit_log` table scaffolded in schema (populated by admin routes in Phase 7)
- [x] **FOUND-09**: `account_standing` field on `connected_profiles` with values `('active', 'suspended', 'quarantined')` — default `'active'`; Communal Council integration deferred to that feature repo

### Auth (AUTH)

- [x] **AUTH-01**: User can sign up with email and password via Supabase Auth; `public.users` record created via trigger on `auth.users` insert
- [x] **AUTH-02**: User can log in and receive a session token
- [x] **AUTH-03**: User can log out, invalidating their session
- [x] **AUTH-04**: `GET /api/account/me` returns tier-appropriate fields — `tolerance_rating` only returned to the owning user, `legal_name` only returned to Empowered account owner; never to other users
- [x] **AUTH-05**: `PATCH /api/account/me` allows updates to display name and preferences for Connected+ users

### Connect Flow (CONN)

- [x] **CONN-01**: User can begin the Connect verification flow; progress stored in `verification_sessions` (resumable if user abandons mid-flow)
- [x] **CONN-02**: User can check their current `verification_status` (`pending` / `verified` / `suspended`)
- [x] **CONN-03**: User can complete the Connect flow, creating a `connected_profiles` record with `verification_status: 'verified'`
- [x] **CONN-04**: User can import anonymous compass calibration from localStorage; import handles topic version mismatches gracefully and requires user confirmation before saving; localStorage cleared after successful import

### Invite System (INVT)

- [x] **INVT-01**: Invite codes are 64-character cryptographically random tokens, single-use, and expire after a configurable TTL
- [x] **INVT-02**: Invite chain is permanently recorded (inviter_id → invitee_id) and never deleted
- [x] **INVT-03**: When an invitee's account is sanctioned, the direct inviter's Tolerance Rating is adjusted (one level only — does not propagate further up the chain)
- [x] **INVT-04**: Invite send is rate-limited per `user_id`; self-invitation is blocked; email is normalized (lowercased, plus-addressing stripped) before uniqueness check
- [x] **INVT-05**: Invite claim is atomic via Postgres `FOR UPDATE` row lock — no two users can claim the same code simultaneously

### Compass (COMP)

- [x] **COMP-01**: User can view all live compass topics with pre-written stances (5 per topic)
- [x] **COMP-02**: User can calibrate a topic — creates or updates `compass_responses`, appends to `compass_change_history`; `inverted` preference stored per topic
- [x] **COMP-03**: User can check their calibration completeness; result is role-filtered (city council candidate threshold differs from US Congress candidate threshold) and used by empowerment preflight
- [x] **COMP-04**: User can view their own compass responses including `inverted` preferences
- [ ] **COMP-05**: User can compare compass with another user — respects `visibility` field (`private` / `friends` / `public`); `friends` visibility enforced via `peer_connections` join; `tolerance_rating` never included in any compare response

### Empower Flow (EMPR)

- [x] **EMPR-01**: Preflight check validates in order: active Connected account with `verification_status: 'verified'`, full compass calibration (all live Top Priority topics for user's role), legal name provided, explicit consent recorded — returns specific failure reason if any check fails
- [x] **EMPR-02**: Empowerment executes as a single atomic Postgres transaction: creates `empowered_profiles` record, batches `compass_responses.visibility` to `'public'` for this user, generates `candidate_page_slug` — rolls back entirely on any failure; partial empowerment is never a valid state
- [x] **EMPR-03**: Demotion executes as a single atomic Postgres transaction: sets `empowered_profiles.is_active = false`, batches `compass_responses.visibility` to `'private'` — fully reversible
- [x] **EMPR-04**: Candidate page slug generated as `kebab-case(legal_name)`; collisions resolved by appending a random 4-character alphanumeric suffix (e.g., `john-smith-a3b4`); slug uniqueness enforced at DB level

### Gems & Roles (CIVIC)

- [x] **CIVIC-01**: Gem transactions are append-only in `gem_transactions` ledger; debit balance enforcement is atomic (check + debit in single transaction — balance cannot go negative)
- [x] **CIVIC-02**: Reserve cap is enforced at stipend time; excess gems above cap expire; no gem purchases, no premium tiers — permanently excluded [NOTE: reserve cap deferred per CONTEXT.md — credit_gems has no cap logic, waived for Alpha]
- [x] **CIVIC-03**: Roles are granted and revoked with soft revocation (`revoked_at` timestamp, NULL = active); tier eligibility enforced at grant time (e.g., Maven requires Empowered)
- [x] **CIVIC-04**: API enforces that a user cannot hold two conflicting roles simultaneously in the same feature context

### Social Graph (SOCL)

- [x] **SOCL-01**: Connected users can send, accept, decline, and block peer connection requests; blocking prevents future requests
- [x] **SOCL-02**: Any Connected user can follow any Empowered account (1-way, no approval required); can unfollow
- [x] **SOCL-03**: `visibility: 'friends'` on compass responses is enforced via accepted `peer_connections` join — not guessable, not bypassable at API layer

### Admin Tool (ADMN)

- [ ] **ADMN-01**: Admin can create invite codes, revoke active codes, view the full invite chain, and trace the invite tree for any account
- [ ] **ADMN-02**: Admin can view account details including `tolerance_rating` and `legal_name` (internal-only fields — admin context only, logged to audit log on access)
- [ ] **ADMN-03**: Admin can approve, suspend, and reinstate accounts; can set `account_standing`
- [ ] **ADMN-04**: Admin can manage pilot cohort enrollment (assign cohort, view cohort membership)
- [ ] **ADMN-05**: Every admin action is appended to `admin_audit_log` with actor, action, target, and timestamp — no admin action is unlogged
- [ ] **ADMN-06**: Admin authentication uses a separate `admin_users` table keyed by `user_id`; being an authenticated user is not sufficient to access admin routes

### Calibration Lapse Enforcement (CRON)

- [ ] **CRON-01**: Daily scheduled job (2am UTC) identifies Empowered users who have not calibrated new live topics within the 30-day grace window
- [ ] **CRON-02**: At day 25, a warning notification is dispatched to at-risk Empowered accounts (delivery channel TBD — placeholder event emitted; wired to email or in-app in later phase)
- [ ] **CRON-03**: At day 30, automatic demotion executes via `execute_demotion` RPC for each lapsed user; user notified with specific topic(s) requiring calibration and re-empowerment path
- [ ] **CRON-04**: Job execution is idempotent — date-keyed `calibration_lapse_runs` table prevents double execution across server restarts or deploys

### Public Candidate Pages (CAND)

- [ ] **CAND-01**: Public `GET /api/candidates/:slug` returns legal name, candidate page metadata, and public compass stances for active Empowered accounts — no authentication required
- [ ] **CAND-02**: `tolerance_rating` never appears in any candidate page response — enforced at both RLS and serialization layers
- [ ] **CAND-03**: Demoted (inactive) candidate pages return a consistent inactive state; slug is reserved and not reassigned

## v2 Requirements

### Identity Verification

- **IDVT-01**: Third-party identity verification service integration (Stripe Identity, Persona, or equivalent)
- **IDVT-02**: Residency verification (state/district level)
- **IDVT-03**: Minor voter handling (17-year-olds eligible before election day)
- **IDVT-04**: Account recovery flow for users who lose access to verification credentials

### Account Standing (Communal Council)

- **STND-01**: Communal Council can set `account_standing` to `'quarantined'` (softer, reversible suspension)
- **STND-02**: Quarantined access model (which features remain accessible under quarantine)

### Notifications

- **NOTF-01**: In-app notification system for calibration warnings and demotion events
- **NOTF-02**: Email delivery for critical account events (empowerment, demotion, sanction)

### Self-Serve Recovery

- **RCVR-01**: Self-serve account recovery UI (admin handles this manually for Alpha)
- **RCVR-02**: Compass data export (JSON) for connected users

## Out of Scope

| Feature | Reason |
|---------|--------|
| End-user frontend (Framer components) | User-facing UI lives in feature repos that call this API; Framer is the production surface |
| OAuth / social login | Structural mismatch with one-person-one-account civic model; would complicate uniqueness enforcement |
| Gem purchases or premium tiers | Permanently excluded — selling civic influence is architecturally prohibited |
| Communal Council suspension logic | Accounts system exposes `account_standing` hook; Communal Council repo owns enforcement logic |
| Demotion public record attribution | Accounts sets `is_active = false`; each feature (Symposiums, Bills) decides attribution policy in its own context |
| Compass issue weighting (`weight` field) | Algorithm undefined; schema accommodates it when needed |
| Multi-candidate compass overlay | Rendering concern only; no schema changes required |
| Cross-feature gem transfer rules | Gem ledger is built; economy rules are per-feature |
| Tolerance Rating cascade beyond direct inviter | One level only (decided); full chain traversal deferred unless platform evidence warrants it |

## Traceability

*Populated during roadmap creation — 2026-02-24*

| Requirement | Phase | Status |
|-------------|-------|--------|
| FOUND-01 | Phase 1 — Foundation | Complete |
| FOUND-02 | Phase 1 — Foundation | Complete |
| FOUND-03 | Phase 1 — Foundation | Complete |
| FOUND-04 | Phase 1 — Foundation | Complete |
| FOUND-05 | Phase 1 — Foundation | Complete |
| FOUND-06 | Phase 1 — Foundation | Complete |
| FOUND-07 | Phase 1 — Foundation | Complete |
| FOUND-08 | Phase 1 — Foundation | Complete |
| FOUND-09 | Phase 1 — Foundation | Complete |
| AUTH-01 | Phase 2 — Auth Routes and Account Core | Complete |
| AUTH-02 | Phase 2 — Auth Routes and Account Core | Complete |
| AUTH-03 | Phase 2 — Auth Routes and Account Core | Complete |
| AUTH-04 | Phase 2 — Auth Routes and Account Core | Complete |
| AUTH-05 | Phase 2 — Auth Routes and Account Core | Complete |
| CONN-01 | Phase 3 — Alpha Enrollment | Complete |
| CONN-02 | Phase 3 — Alpha Enrollment | Complete |
| CONN-03 | Phase 3 — Alpha Enrollment | Complete |
| CONN-04 | Phase 3 — Alpha Enrollment | Complete |
| INVT-01 | Phase 3 — Alpha Enrollment | Complete |
| INVT-02 | Phase 3 — Alpha Enrollment | Complete |
| INVT-03 | Phase 3 — Alpha Enrollment | Complete |
| INVT-04 | Phase 3 — Alpha Enrollment | Complete |
| INVT-05 | Phase 3 — Alpha Enrollment | Complete |
| COMP-01 | Phase 4 — Compass Routes | Complete |
| COMP-02 | Phase 4 — Compass Routes | Complete |
| COMP-03 | Phase 4 — Compass Routes | Complete |
| COMP-04 | Phase 4 — Compass Routes | Complete |
| COMP-05 | Phase 4 — Compass Routes | Pending (user-to-user compare deferred to Phase 6) |
| EMPR-01 | Phase 5 — Empower Flow | Complete |
| EMPR-02 | Phase 5 — Empower Flow | Complete |
| EMPR-03 | Phase 5 — Empower Flow | Complete |
| EMPR-04 | Phase 5 — Empower Flow | Complete |
| CIVIC-01 | Phase 6 — Gems, Roles, and Social Graph | Complete |
| CIVIC-02 | Phase 6 — Gems, Roles, and Social Graph | Complete (reserve cap deferred per CONTEXT.md) |
| CIVIC-03 | Phase 6 — Gems, Roles, and Social Graph | Complete |
| CIVIC-04 | Phase 6 — Gems, Roles, and Social Graph | Complete |
| SOCL-01 | Phase 6 — Gems, Roles, and Social Graph | Complete |
| SOCL-02 | Phase 6 — Gems, Roles, and Social Graph | Complete |
| SOCL-03 | Phase 6 — Gems, Roles, and Social Graph | Complete |
| ADMN-01 | Phase 7 — Admin Tool and Calibration Cron | Pending |
| ADMN-02 | Phase 7 — Admin Tool and Calibration Cron | Pending |
| ADMN-03 | Phase 7 — Admin Tool and Calibration Cron | Pending |
| ADMN-04 | Phase 7 — Admin Tool and Calibration Cron | Pending |
| ADMN-05 | Phase 7 — Admin Tool and Calibration Cron | Pending |
| ADMN-06 | Phase 7 — Admin Tool and Calibration Cron | Pending |
| CRON-01 | Phase 7 — Admin Tool and Calibration Cron | Pending |
| CRON-02 | Phase 7 — Admin Tool and Calibration Cron | Pending |
| CRON-03 | Phase 7 — Admin Tool and Calibration Cron | Pending |
| CRON-04 | Phase 7 — Admin Tool and Calibration Cron | Pending |
| CAND-01 | Phase 8 — Public Candidate Pages | Pending |
| CAND-02 | Phase 8 — Public Candidate Pages | Pending |
| CAND-03 | Phase 8 — Public Candidate Pages | Pending |

**Coverage:**
- v1 requirements: 52 total
- Mapped to phases: 52
- Unmapped: 0

---
*Requirements defined: 2026-02-24*
*Last updated: 2026-02-27 after Phase 5 completion*
