# Project Research Summary

**Project:** empowered-accounts — Foundational three-tier account infrastructure for Empowered Vote
**Domain:** Tiered civic identity system — Supabase + Express/TypeScript + Upstash Redis + Vite/React admin tool
**Researched:** 2026-02-24
**Confidence:** HIGH (architecture and pitfalls); MEDIUM-HIGH (stack — versions verified against documentation, not live npm)

---

## Executive Summary

`empowered-accounts` is not a generic auth system — it is the foundational identity layer of a civic platform where account tier determines what a user can say, how publicly they say it, and who is accountable for their presence. The three tiers (Inform → Connected → Empowered) map to increasing levels of civic commitment: anonymous access, pseudonymous verified identity, and public legal-name participation. The structural keystone of the system is that **tier is determined entirely by child record presence, never by a status flag** — a decision that eliminates invalid states by construction and makes rollback atomic. Everything downstream from that decision follows logically.

The recommended approach is to lean heavily on Supabase Auth, Supabase RLS, and PostgreSQL transaction functions (called via Supabase RPC) rather than building custom alternatives. The Express layer is thin: it validates JWTs, enforces tier guards as middleware, delegates business logic to a service layer, and coordinates atomic multi-table operations through Postgres functions. Upstash Redis handles caching for the hot-path `detectTier()` call. The admin React tool is internal-only and always proxies privileged operations through the Express backend — the service role key never leaves the server. In-process `node-cron` with UptimeRobot keepalive handles the calibration lapse enforcement scheduler at pilot scale.

The two overriding risks are data leakage and partial state. `tolerance_rating` and `legal_name` are internal-only fields that must never reach non-owner API responses — enforced at both the RLS layer and the Express serialization layer. Empowerment and demotion involve multiple tables and must always run inside a single Postgres transaction (RPC function); chained JavaScript `await` calls are explicitly forbidden for these flows. Both risks must be addressed in the foundation phase, before any feature work, because retrofitting them is dangerous and incomplete.

---

## Key Findings

### Recommended Stack

The stack is well-validated and matches the declared project constraints. Supabase handles auth and the database. Express 4.x (not 5.x, which is still in RC) is the API server. TypeScript strict mode enforces type discipline throughout. Raw `pg` is required specifically for atomic transaction patterns that bypass the Supabase JS client's limitations — the Supabase client does not expose `BEGIN`/`COMMIT`. `@upstash/redis` (HTTP-based) is the correct client for Upstash, not `ioredis` (TCP-based). Critical: the deprecated `@supabase/auth-helpers-*` packages must not be used; `@supabase/ssr` is the current server-side companion.

**Core technologies:**
- `@supabase/supabase-js` ^2.45.x + `@supabase/ssr` ^0.5.x: Auth and DB access — v2 stable, fully typed, RLS-integrated; `@supabase/ssr` replaces the deprecated `auth-helpers-*` packages
- `express` ^4.19.x: HTTP API server — Express 5.x is RC, ecosystem not validated; stay on 4.x
- `typescript` ^5.5.x (strict mode): Type system — mandatory per project constraints; 5.5+ has improved narrowing
- `pg` ^8.12.x: Raw Postgres driver — required for `BEGIN/COMMIT` in empowerment/demotion transactions; Supabase JS client cannot do this
- `@upstash/redis` ^1.31.x: HTTP-based Redis client — HTTP only, Upstash exposes no TCP; `ioredis` will not work here
- `jsonwebtoken` ^9.0.x + `jwks-rsa` ^3.1.x: Local JWT verification — avoids a network round-trip to Supabase on every request
- `zod` ^3.23.x: Request schema validation + TypeScript inference — source of truth for request shape
- `node-cron` ^3.0.x: In-process scheduler — for calibration lapse enforcement on Render free tier
- `vite` ^5.4.x + `react` ^18.3.x: Admin tool frontend — declared stack, concurrent features

**What not to use:** `@supabase/auth-helpers-*` (deprecated), `ioredis` (wrong protocol for Upstash), Express 5.x (RC), Prisma (conflicts with Supabase CLI schema ownership), `any` type (banned by strict mode), `SELECT *` on tables with sensitive fields.

See `STACK.md` for full installation commands and detailed code patterns.

---

### Expected Features

A production-grade tiered civic account system has three complexity layers: (1) auth primitives that Supabase provides and we do not rebuild, (2) lifecycle and standing management where most implementation risk lives, and (3) platform-specific trust mechanisms that differentiate this platform. The critical path for v1 is: foundation auth → connected profiles + RLS → invite system → empowerment transaction → compass tables → gem ledger → roles → admin tool → calibration lapse scheduler.

**Must have (table stakes):**
- Account lifecycle (create + cascade delete with PII scrubbing) — everything depends on `auth.users` + `public.users`
- Session handling (Supabase-managed; risk is misconfiguration, not implementation) — non-negotiable
- Verification flow (Connected tier) — resumable session state, duplicate detection, compass import mismatch handling
- Atomic tier transitions (empowerment + demotion as Postgres RPC functions) — partial state is a platform integrity failure
- Authorization enforcement (RLS primary, middleware secondary) — `tolerance_rating` and `legal_name` never leave the server except to the owning user
- Admin tooling (invite management, account review, manual verification, invite chain visualization) — operational requirement for Alpha
- Audit logging (append-only: tier transitions, admin actions, gem ledger, compass change history) — "Memory over Moderation"
- Health check endpoint (`GET /api/health`) — first endpoint; UptimeRobot dependency
- Anonymous compass import (review-before-commit, version mismatch handling, optional) — bridges anonymous → Connected

**Should have (differentiators — all v1):**
- Invite-based Alpha enrollment with chain tracking and Tolerance Rating cascade — civic accountability mechanism, not growth hacking
- Tolerance Rating (private for Connected, internal-only) + Veracity Rating (public) — separates accuracy from engagement quality
- Calibration lapse enforcement (30-day grace, day-25 warning, automatic demotion via scheduled job) — ongoing civic commitment requirement
- Gem ledger (append-only, atomic balance enforcement, reserve cap) — closed civic economy; no purchases ever
- Role system (junction table, soft revocation, 8 roles, tier-gated eligibility) — civic function assignment
- Account standing field (`account_standing` — hook for Communal Council, owned by admin in v1)

**Defer to post-Alpha:**
- Third-party identity verification (Stripe Identity, Persona) — invite chain is the v1 trust mechanism
- Self-serve account recovery UI — admin handles this for small Alpha cohort
- Social login / OAuth — structural mismatch with one-person-one-account civic model
- Communal Council suspension logic — accounts system exposes the hook; Communal Council repo owns the logic
- Compass issue weighting — algorithm not yet defined; schema accommodates it
- End-user frontend in this repo — user-facing flows live in feature repos that call this API

See `FEATURES.md` for full feature dependency map and complexity ratings.

---

### Architecture Approach

The architecture is a layered defense system organized around two absolute rules: RLS is the primary data access gate at the database level, and Express middleware is a second independent gate at the application level. Neither layer is optional, and a bug in one should not expose data through the other. The service role key (which bypasses RLS entirely) is used exclusively on the server side for trusted writes and admin operations — never for reads that return data to users, never on the client side. The admin React tool is an internal application whose privileged operations are always proxied through Express.

**Major components:**
1. **Supabase Auth** — JWT issuance, session management, password flows; not customized, only configured
2. **RLS policies (per-table, per-schema)** — primary data access enforcement; written as migrations, never created interactively in Studio
3. **Express auth middleware** — local JWT validation via JWKS (avoids network round-trips), tier detection via child record join, attaches `req.user` with tier context
4. **Tier guard middleware factory** (`requireTier('connected' | 'empowered')`) — second layer; returns 403 before DB is touched
5. **Service layer** (TypeScript modules) — business logic, transaction orchestration; `AccountService`, `ConnectService`, `EmpowerService`, `CompassService`, `GemService`, `ConnectionService`
6. **Postgres RPC functions** (`execute_empowerment`, `execute_demotion`, `get_calibration_lapsed_users`) — atomic multi-table operations; defined in migrations, called via `supabase.rpc()`
7. **Supabase client** (service role singleton for writes; per-request user-scoped for RLS-enforced reads) — two distinct instances
8. **Upstash Redis** (with in-memory fallback) — tier lookup cache, rate limit state; Redis down must never crash the API
9. **Calibration lapse cron** (`node-cron` at startup, daily at 2am UTC) — idempotent; cron failures must never crash the server
10. **Admin router** (`/api/admin/*`) — separate Express router with separate middleware chain; never mixes with public routes
11. **Database schemas** (4 schemas: `public`, `connect`, `empower`, `inform`) — schema-level isolation enforces data boundaries structurally

**Build order from ARCHITECTURE.md:** Schema + migrations first (foundation for everything) → DB client + auth middleware → health check → auth routes → account routes → Connect flow → Compass routes → Empower flow → social graph → calibration cron → admin routes → public candidate pages.

See `ARCHITECTURE.md` for full system diagram, data flow diagrams, and anti-patterns.

---

### Critical Pitfalls

1. **RLS policy gaps — anon key / service role boundary** — The service role client bypasses all RLS by design. Any route using `supabaseAdmin` for reads that return data to users leaks every column in the result. Prevention: two client instances with explicit rules — admin client for trusted writes only; user-scoped client (JWT injected) for any read that feeds a response. Never `SELECT *` on tables with sensitive fields. Column allowlists are mandatory.

2. **RLS never actually tested** — Writing policies that look correct and never verifying they block what they should. For this platform, an untested RLS policy is no defense. Prevention: SQL `SET LOCAL` impersonation tests for every sensitive table (`tolerance_rating`, `legal_name`), plus Express integration tests asserting that cross-user requests return neither field. This is an acceptance gate on every migration that introduces sensitive data.

3. **Atomic transaction failures — partial empowerment state** — Chaining `.from().insert()` calls in JavaScript is not atomic. A crash or network error between steps leaves the user in an impossible partial state. Prevention: all multi-table state changes go through Postgres RPC functions (`supabase.rpc()`). The `BEGIN`/`COMMIT` is inside the SQL function; any exception rolls back everything. This rule is established in the foundation phase and never relaxed.

4. **Session and token edge cases** — Tier stored in JWT claims goes stale on demotion; suspended accounts remain valid for up to 1 hour after suspension; service role key logged or committed to git destroys every RLS policy. Prevention: tier decisions always come from the database, never JWT claims alone; suspension check middleware on each authenticated request; service role key validated at startup, never logged.

5. **Invite system abuse vectors** — Token enumeration, replay attacks, self-invitation loops, quota bypass via race conditions, email aliasing. Prevention: 64-character cryptographic tokens; atomic invite claim via `FOR UPDATE` inside RPC function; email normalization before uniqueness check; rate limits on invite send keyed by `user_id`; invite expiration (`expires_at` column); full audit log.

6. **Cron job reliability on Render free tier** — Render free instances spin down after 15 minutes; in-process timers are lost on restart; double-execution is possible during deploys. Prevention: idempotency key (date-keyed `calibration_lapse_runs` table prevents double runs); UptimeRobot keeps the instance warm; plan to migrate to Render Cron Jobs (paid) or Supabase `pg_cron` when the platform grows.

See `PITFALLS.md` for warning signs, prevention code, and phase assignments for all 10 pitfalls.

---

## Implications for Roadmap

The research produces a clear dependency graph. The schema is the foundation for everything — no routes can be built without it. Auth middleware is the gateway all routes depend on. The Connect flow must precede the Empower flow (Empowered requires Connected). Compass tables must precede the Empower preflight check. The admin tool can begin once account + connect + empower flows exist. Calibration lapse cron is the last server-side piece, dependent on the completed demotion RPC.

### Phase 1: Foundation — Schema, Security Primitives, Health
**Rationale:** Nothing else can be built without the database schema. RLS and the service role boundary must be established before any route is written — retrofitting these is unsafe. The admin audit log table scaffolds here even though admin routes don't exist yet.
**Delivers:** Complete Supabase schema across all 4 schemas (public, connect, empower, inform) with all migrations; RLS policies on every table; RPC functions for empowerment, demotion, and calibration lapse query; dual Supabase client pattern (admin + user-scoped); JWT middleware with JWKS verification; `GET /api/health`; env var validation at startup; `admin_audit_log` table scaffold.
**Addresses:** Features 1 (lifecycle schema), 4 (transaction functions), 5 (RLS), 7 (audit log schema), 8 (health check)
**Avoids:** Pitfalls 1 (RLS gaps), 2 (JOIN leaks), 3 (partial state), 7 (migration mistakes), 8 (token edge cases), 10 (untested RLS)
**Research flag:** Standard patterns — well-documented Supabase + Postgres. Skip `/gsd:research-phase`. RLS policy testing (pgTAP) may benefit from targeted research if team is unfamiliar.

### Phase 2: Auth Routes and Account Core
**Rationale:** Every user-facing flow requires a user. Auth routes and the `public.users` extension of `auth.users` must exist before any tier-specific flow can be built or tested.
**Delivers:** `POST /api/auth/signup`, `POST /api/auth/login`, `POST /api/auth/logout`; `GET /api/account/me`, `PATCH /api/account/me`; `public.users` trigger on Supabase Auth signup; session handling validation.
**Addresses:** Features 1 (account creation), 2 (session handling)
**Avoids:** Pitfall 8 (service role key hygiene, JWT verification options with issuer/audience check)
**Research flag:** Standard patterns. Skip `/gsd:research-phase`.

### Phase 3: Connect Flow (Verification + Compass Import)
**Rationale:** Connected tier is the prerequisite for Empowered tier and for the invite system. Compass import lives here because it occurs during the Connect flow. This is the first phase with meaningful engineering complexity (resumable session state, mismatch handling, duplicate detection).
**Delivers:** `POST /api/connect/start`, `GET /api/connect/status`, `POST /api/connect/complete`, `POST /api/connect/import-compass`; `connect.verification_sessions` flow; `connected_profiles` creation with `verification_status` state machine; anonymous compass import with version mismatch detection.
**Addresses:** Features 3 (verification flow), 9 (anonymous compass import)
**Avoids:** Pitfall 6 (topic version mismatch on import — `topic_version` column must be in schema from Phase 1)
**Research flag:** Resumable session state patterns are well-documented. Skip `/gsd:research-phase`.

### Phase 4: Invite System (Alpha Enrollment Gate)
**Rationale:** The Alpha is invite-only. Until the invite system exists, the Connect flow cannot be exercised with real users. The Tolerance Rating cascade mechanism must be established here because it affects the data model for Phase 5 (Empowerment).
**Delivers:** `public.invite_codes` (64-char cryptographic tokens, expiry, single-use atomic claim); invite chain storage (inviter → invitee permanent record); Tolerance Rating adjustment mechanism; invite revocation in admin; rate limits on invite send.
**Addresses:** Feature 10 (invite chain with standing cascade)
**Avoids:** Pitfall 4 (all abuse vectors: token enumeration, replay, self-invitation, quota bypass, email aliasing)
**Research flag:** Invite system patterns are well-documented. Skip `/gsd:research-phase`. The Tolerance Rating cascade depth question (one level vs. full chain) must be resolved with product owner before implementation.

### Phase 5: Compass Routes
**Rationale:** The empowerment preflight check requires all live topics to have compass responses. Compass routes must be complete and testable before the Empower flow can be built.
**Delivers:** `GET /api/compass/topics`, `PUT /api/compass/:topicId` (calibrate), `GET /api/compass/progress` (completeness with role-filtered threshold), `GET /api/compass` (own responses), `GET /api/compass/compare/:userId` (visibility-gated); `inform.compass_change_history` append-only logging; calibration completeness calculation.
**Addresses:** Feature 12 (calibration completeness tracking — the data foundation), Feature 9 (compass change history audit)
**Avoids:** Pitfall 2 (compass compare query must never expose `tolerance_rating` through a visibility JOIN)
**Research flag:** Standard patterns. Skip `/gsd:research-phase`. Role-filtered completeness calculation (via `compass_topic_roles`) is specific to this domain — implementation should be stubbed before full role system exists.

### Phase 6: Empower Flow (Atomic Transactions)
**Rationale:** Empowerment is the highest-risk operation in the system. It requires Phase 3 (Connected) and Phase 5 (Compass) to be complete. The empowerment RPC function is already scaffolded in Phase 1; this phase wires it into the API with pre-flight checks, consent recording, slug generation, and demotion.
**Delivers:** `POST /api/empower/preflight` (ordered pre-flight checks: verified status, full calibration, legal name, consent); `POST /api/empower/confirm` (calls `execute_empowerment` RPC, returns empowered profile); `POST /api/empower/demote` (calls `execute_demotion` RPC); slug collision handling; re-empowerment path after lapse.
**Addresses:** Feature 4 (atomic tier transitions — the core of the whole system)
**Avoids:** Pitfall 3 (partial state — both operations must be in the RPC transaction), Pitfall 8 (tier decisions from database, not JWT)
**Research flag:** Standard patterns — RPC function pattern is established in Foundation. Skip `/gsd:research-phase`.

### Phase 7: Gem Ledger and Role System
**Rationale:** These features can be built in parallel with or immediately after the Empower flow. They are differentiators that require the tier foundation to exist but don't block any other phase. The gem ledger's atomic balance enforcement uses the same RPC pattern established in Phase 1.
**Delivers:** `connect.gem_transactions` append-only ledger with atomic debit enforcement; balance reads via `balance_after`; reserve cap logic at stipend time; `public.user_roles` junction table; role grant/revoke with soft revocation (`revoked_at`); role eligibility enforcement (tier-gated); role type ENUM.
**Addresses:** Features 13 (gem ledger), 14 (role system)
**Avoids:** Pitfall 3 (gem debit must be atomic — check + debit in single transaction; balance cannot go negative)
**Research flag:** Standard patterns. Skip `/gsd:research-phase`.

### Phase 8: Social Graph (Connections + Follows)
**Rationale:** Peer connections enable the `visibility: 'friends'` compass sharing mode. Follows are one-way connections toward Empowered accounts (candidate pages). These can be built in parallel with Phase 7 — neither blocks the other.
**Delivers:** `POST /api/connections/request`, `POST /api/connections/:id/accept`, `POST /api/connections/:id/decline`, `POST /api/connections/:id/block`, `GET /api/connections`; `POST /api/follows/follow`, `DELETE /api/follows/unfollow`, `GET /api/follows`; `peer_connections` and `account_follows` tables with RLS.
**Addresses:** Feature 3 (peer connection dependency for `visibility: 'friends'`)
**Avoids:** Pitfall 2 (peer_connections JOIN in compass visibility query must not expose sensitive fields)
**Research flag:** Standard patterns. Skip `/gsd:research-phase`.

### Phase 9: Admin Tool
**Rationale:** The admin tool can be built once the account, connect, and empower flows are in place and producting real data. The `admin_audit_log` table and `requireAdmin` middleware were scaffolded in Phase 1; this phase builds the React UI and the full `/api/admin/*` route surface.
**Delivers:** React admin UI (Vite); `/api/admin/invites` (create, revoke, view chain, trace full invite tree); `/api/admin/accounts` (view with `tolerance_rating` + `legal_name`, approve/suspend/reinstate, set `account_standing`); `/api/admin/cohorts` (pilot enrollment management); admin auth flow (JWT → admin role check via `admin_users` table); every admin action logged to `admin_audit_log`.
**Addresses:** Feature 6 (admin tooling), Feature 15 (account standing), Feature 7 (admin action audit logging)
**Avoids:** Pitfall 9 (admin tool security: separate router, admin-only middleware, audit log on every action, dry-run for bulk operations)
**Research flag:** Admin UI patterns are standard React. The invite chain tree visualization may benefit from a targeted graph rendering research pass if a library is needed.

### Phase 10: Calibration Lapse Enforcement (Scheduler)
**Rationale:** The cron-based enforcement system is the last server-side piece. It depends on the completed demotion RPC (Phase 1) and the calibration completeness query (Phase 5). Building it last means the demotion path is fully tested before the automated job starts running it.
**Delivers:** `services/cron/calibrationLapse.ts` registered at startup; daily 2am UTC scan via `get_calibration_lapsed_users` RPC; atomic demotion for each lapsed user; `calibration_lapse_runs` idempotency table (prevents double runs); day-25 warning notification event (notification mechanism TBD — email or in-app); day-30 demotion event; UptimeRobot configuration documented.
**Addresses:** Feature 12 (calibration lapse enforcement — the scheduler piece), Feature 4 (re-empowerment path after lapse)
**Avoids:** Pitfall 5 (cron reliability: idempotency key, try/catch, no server crashes, keepalive documented)
**Research flag:** In-process `node-cron` pattern is well-documented. If Render Cron Jobs (paid) or Supabase `pg_cron` is adopted instead, research the migration path before this phase begins.

### Phase 11: Public Candidate Pages
**Rationale:** The final feature surface — public-facing read API for Empowered candidates. Requires the full Empower flow and real data. This is a read-only API; the complexity is in the field projection (legal_name is shown, but only for the Empowered profile owner and public consumers; tolerance_rating is not shown).
**Delivers:** `GET /api/candidates/:slug` (public candidate profile: legal name, candidate page, public compass stances); public read RLS policy for `empowered_profiles` (active only); field projection that never includes `tolerance_rating`.
**Addresses:** Feature 4 (public Empowered profile exposure), Feature 5 (RLS for public read)
**Avoids:** Pitfall 1 (column allowlist — `tolerance_rating` never in the select), Pitfall 3 (read-only phase, but field projection hygiene still applies)
**Research flag:** Standard patterns. Skip `/gsd:research-phase`.

---

### Phase Ordering Rationale

- **Schema before everything:** The additive child-table architecture means no route can be built or tested without the schema. All 4 schemas, all RLS policies, and all RPC functions are migration-defined from day one.
- **Security primitives before features:** RLS, dual-client pattern, and JWT middleware established in Phase 1 because they cannot be safely retrofitted. Every subsequent phase inherits this security posture automatically.
- **Connect before Empower:** The Empowered tier requires a verified Connected profile. No exceptions — this is a database-enforced constraint.
- **Compass before Empower preflight:** The preflight check requires full calibration coverage. Building the Empower flow without working compass routes produces an incomplete preflight.
- **Invites gating real users:** The invite system must exist before the Connect flow can be exercised with real Alpha users. Invite + Connect are the enrollment pipeline.
- **Cron last:** Automated enforcement of demotion should run only after the demotion path is fully tested through manual routes. Deploying the cron before demotion is proven would risk cascading unintended demotions.
- **Admin tool late, audit log early:** The audit log table is scaffolded in Phase 1 (so it exists when the first admin action occurs), but the admin React UI is Phase 9 (after there is data to manage).

---

### Research Flags

Phases needing deeper research during planning:
- **Phase 4 (Invite System):** The Tolerance Rating cascade depth question (one level vs. full chain traversal) is an open product decision. Resolve with product owner before writing the schema — cascade depth significantly affects query complexity.
- **Phase 10 (Calibration Lapse Scheduler):** If the decision is made to use Supabase `pg_cron` instead of `node-cron`, a targeted research pass is warranted. The `pg_cron` extension pattern differs significantly from the in-process approach documented in ARCHITECTURE.md.
- **Phase 9 (Admin Tool):** If invite chain tree visualization requires a graph rendering library, a brief library research pass is warranted before UI implementation.

Phases with standard patterns (skip `/gsd:research-phase`):
- **Phase 1 (Foundation):** Supabase schema, RLS policies, Express setup — extensively documented official patterns.
- **Phase 2 (Auth Routes):** Supabase Auth + Express auth middleware — standard, well-documented.
- **Phase 3 (Connect Flow):** Verification flow patterns are standard; the resumable session state is the only bespoke piece.
- **Phase 5 (Compass Routes):** Standard CRUD + visibility-gated reads — no novel patterns.
- **Phase 6 (Empower Flow):** RPC pattern established in Phase 1; wiring it into routes is straightforward.
- **Phase 7 (Gems + Roles):** Append-only ledger and junction table patterns are standard.
- **Phase 8 (Social Graph):** Connection/follow patterns are industry-standard.
- **Phase 11 (Candidate Pages):** Read-only public API — no novel patterns.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM-HIGH | Core technologies verified against official documentation; package versions based on knowledge cutoff Aug 2025 — run `npm info <package> version` before locking package.json |
| Features | HIGH | Derived directly from project design documents (`empowered-accounts-design.md`, `empowered-vote-primer.md`, `.planning/PROJECT.md`); feature list is authoritative, not inferred |
| Architecture | HIGH | Standard Supabase + Express patterns with no experimental dependencies; RPC transaction pattern is official Supabase documentation; additive child-table tier pattern is a deliberate design decision, not a community guess |
| Pitfalls | HIGH | Pitfalls derived from documented Supabase security patterns, PostgreSQL transaction documentation, and Render platform behavior — all verifiable sources with consistent guidance |

**Overall confidence:** HIGH

---

### Gaps to Address

These are open questions surfaced by research that must be resolved before or during specific phases — they are not blockers for planning but must not be left unresolved at implementation time.

- **`account_standing` enum values** (Phase 1 schema): The proposal is `('active', 'suspended', 'quarantined')`. Confirm with product owner before writing the migration — enum alterations on a populated table require a new migration.
- **Tolerance Rating cascade depth** (Phase 4): Does the invite sanction cascade one level (inviter only) or up the full chain? One level is a simple FK lookup; full chain requires a recursive CTE or iterative traversal. This decision must be made before the invite schema is finalized.
- **Soft delete vs. hard delete policy** (Phase 1 schema design): "Memory over Moderation" suggests PII scrubbing + de-identification rather than hard row deletion. The cascade behavior for account deletion must be designed before the schema is locked.
- **Session policy differentiation by tier** (Phase 2): Should Empowered users have shorter JWT session expiry than Connected users given higher data exposure? Document the decision in Supabase Auth configuration before deploying.
- **Slug collision strategy** (Phase 6): If two users with identical legal names empower simultaneously, slug generation must be deterministic. Decide: numeric suffix (`john-smith-2`) or random string suffix (`john-smith-a3b4f`) before implementing `execute_empowerment`.
- **Admin auth mechanism** (Phase 1 scaffold + Phase 9): How do admins authenticate? A separate `admin_users` table keyed by `user_id` is recommended in ARCHITECTURE.md. Confirm this is the chosen approach before scaffolding the middleware.
- **Notification mechanism** (Phase 10): Day-25 warning and demotion notifications require a delivery channel (email via Resend/SendGrid, or in-app). The notification service is TBD — this must be resolved before Phase 10 can be fully implemented.

---

## Sources

### Primary (HIGH confidence)
- `empowered-accounts-design.md` (project design document) — complete data model, tier definitions, feature requirements
- `empowered-vote-primer.md` (platform primer) — civic platform values, "Memory over Moderation" principle, Tolerance/Veracity Rating definitions
- `.planning/PROJECT.md` (project requirements) — declared stack, constraints, scope
- Supabase RLS documentation — policy syntax, `auth.uid()`, `USING`/`WITH CHECK`, RLS bypass via service role
- Supabase RPC / Postgres functions documentation — transaction control, `SECURITY DEFINER`, RPC call pattern
- PostgreSQL documentation — row-level security, transaction isolation, `FOR UPDATE`, `SECURITY DEFINER` vs `SECURITY INVOKER`
- Express 4.x documentation — middleware patterns, router composition
- `pg` (node-postgres) documentation — `Pool`, `BEGIN`/`ROLLBACK` pattern
- `node-cron` documentation — cron expression syntax, schedule API
- `jsonwebtoken` + `jwks-rsa` — RS256 JWT verification with JWKS key caching

### Secondary (MEDIUM confidence)
- `@supabase/supabase-js` ^2.45.x documentation — verified client API, Auth helpers deprecation notice (knowledge cutoff Aug 2025; confirm current version)
- `@supabase/ssr` ^0.5.x documentation — server-side auth replacement for deprecated `auth-helpers-*`
- `@upstash/redis` documentation — HTTP-based client, `ex` TTL option
- Render documentation — free tier cold start behavior (~50s restart, 15-min spin-down), `process.env.PORT` requirement
- Zod v3 documentation — `z.object()`, `.safeParse()`, type inference

### Tertiary (LOW confidence / needs verification before use)
- Package versions in STACK.md — all based on knowledge cutoff Aug 2025. Verify each with `npm info <package> version` before locking. Specific concern: `@supabase/supabase-js`, `@supabase/ssr`, `@upstash/redis` — these packages release frequently.

---

*Research completed: 2026-02-24*
*Ready for roadmap: yes*
