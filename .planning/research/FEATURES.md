# FEATURES.md — Empowered Accounts

**Feature:** `empowered-accounts`
**Research type:** Project Research — Features dimension
**Milestone:** Greenfield — What does a production-grade tiered account system need?
**Date:** 2026-02-24
**Status:** Research complete

---

## Purpose of This Document

This document maps the feature surface of a production-grade tiered account/auth system and applies it to `empowered-accounts`. It distinguishes between what the system must have to be reliable and secure (table stakes), what is specific to this platform's values and architecture (differentiators), and what should be deliberately excluded from v1 to prevent scope creep (anti-features).

The research question: *What features does a tiered account/auth system need to be production-grade, specifically covering account lifecycle management, session handling, invite/referral systems, verification flows, admin tooling, audit logging, reputation/standing systems, and account recovery?*

---

## Summary Finding

A production-grade tiered account system has roughly three layers of complexity:

1. **Reliable auth primitives** — signup, login, session, token refresh, logout. Commodity. Supabase Auth handles this; we do not build it.
2. **Lifecycle and standing management** — tier transitions, verification flows, suspension, recovery. This is where most implementation risk lives.
3. **Platform-specific trust mechanisms** — invite chains, reputation systems, calibration lapse enforcement. This is where `empowered-accounts` is genuinely differentiated.

The biggest traps in v1 are: (a) building custom auth plumbing that Supabase already provides, (b) prematurely building self-serve recovery flows before the user base warrants it, and (c) adding social verification features (leaderboards, public invite stats) that introduce gameable incentive structures.

---

## Table Stakes

> Must have or the system is unreliable, insecure, or untrustworthy. These are not optional.

### 1. Account Lifecycle: Creation and Deletion

**What it covers:** Signing up, account initialization, and account removal (including data-retention-compliant deletion).

**Requirements for this system:**
- `auth.users` record created via Supabase Auth on signup.
- `public.users` row created in a post-signup trigger or handler (extends auth identity).
- Tier child records (`connected_profiles`, `empowered_profiles`) created only through their respective flows — never auto-created on signup.
- Soft delete vs. hard delete decision documented. For this platform, "Memory over Moderation" applies: user-facing content persists; PII (legal_name, verification_method) is scrubbed on deletion request.
- Account deletion must cascade correctly across all child tables without leaving orphaned records.

**Complexity:** Low–medium. Supabase Auth handles credential storage. The complexity is in the cascade behavior and the data-retention policy decision.

**Dependencies:** RLS policies, data schema finalization, GDPR/CCPA posture decision.

---

### 2. Session Handling

**What it covers:** Auth tokens, token refresh, session expiry, concurrent session behavior, and logout.

**Requirements for this system:**
- Supabase Auth manages JWT issuance and refresh. Do not reimplement.
- Service role key is server-side only. Anon key only to client. This is non-negotiable.
- Session expiry must be consistent with the sensitivity of data accessible per tier. Empowered users have higher exposure; session policy should reflect that.
- Logout must invalidate server-side session, not just clear the client cookie.
- Inactive session cleanup: Supabase handles this natively; verify configuration.
- Cold start awareness: Render free tier has ~50s restart. Session continuity through cold starts must be verified.

**Complexity:** Low. Supabase Auth handles the hard parts. Risk is misconfiguration (wrong key exposed, session not invalidated on logout).

**Dependencies:** Supabase Auth configuration, environment variable handling, Render deployment.

---

### 3. Verification Flow (Connect)

**What it covers:** The flow from anonymous → Connected. Identity confirmation, residency confirmation, pseudonym selection, and `verification_status` management.

**Requirements for this system:**
- `connect.verification_sessions` table stores resumable in-progress state. If a user abandons mid-flow, they return to where they were.
- `connected_profiles` created with `verification_status: 'pending'` initially; transitions to `'verified'` on confirmation.
- `verification_status` check constraint enforces only valid states: `('pending', 'verified', 'suspended')`.
- Duplicate detection: if verification signals a pre-existing account, surface this gracefully without revealing any PII of the existing account.
- Topic version mismatch handling in compass import: if a topic has changed since anonymous calibration, prompt user to re-calibrate rather than silently discarding.
- Session expiry on verification sessions: expired sessions should require restart, not be indefinitely resumable.
- **v1 trust mechanism:** Invite chain replaces third-party identity verification in Alpha. Third-party verification (Stripe Identity, Persona) is explicitly out of scope for v1.

**Complexity:** Medium. The resumable session state, duplicate detection, and compass import mismatch handling are the highest-risk pieces.

**Dependencies:** `verify_sessions` table, `connected_profiles` table, anonymous compass import flow, invite system.

---

### 4. Atomic Tier Transitions

**What it covers:** Tier upgrades (Connected → Empowered) and downgrades (Empowered → Connected), including the calibration lapse demotion path.

**Requirements for this system:**
- Empowerment is a database transaction: `INSERT INTO empowered_profiles` + `UPDATE compass_responses SET visibility = 'public'` + slug generation — all in one `BEGIN/COMMIT` block. Any failure = full rollback. Partial empowerment is never a valid state.
- Demotion is a database transaction: `SET is_active = false` + `UPDATE compass_responses SET visibility = 'private'` — same atomicity requirement.
- Pre-flight checks before empowerment must be explicit and ordered: (1) `verification_status = 'verified'`; (2) all required compass topics calibrated; (3) legal_name provided; (4) explicit consent recorded.
- Calibration lapse demotion is triggered by a scheduled job, not user action. Must use the same atomic demotion transaction.
- Re-empowerment after lapse demotion: user completes missing calibration → requests re-empowerment → same empowerment transaction executes again.
- Candidate page slug must be unique. Slug generation must handle collisions (e.g., two users with the same legal name).

**Complexity:** High. The atomicity requirement across multiple tables is the core engineering challenge. The scheduled job adds operational complexity.

**Dependencies:** Database transaction support, `empowered_profiles` table, `compass_responses` table, calibration lapse scheduler.

---

### 5. Authorization Enforcement (RLS + Application Layer)

**What it covers:** Ensuring users can only access data they are permitted to access, enforced at the database level first and application level second.

**Requirements for this system:**
- RLS is primary. Application checks are a second layer — not the only layer.
- `tolerance_rating` RLS policy: only the account owner can read their own value. No exceptions. Not surfaced in any API response to other users, ever.
- `legal_name` RLS policy: never surfaced for Connected users. Only readable by the account owner and after empowerment.
- `verification_method` and raw verification data: internal-only. Never returned to any client.
- `compass_responses` with `visibility: 'private'`: only the owning user.
- `compass_responses` with `visibility: 'friends'`: only users with an accepted `peer_connections` record.
- `custom` stance text for Connected users: private-only. For Empowered users: public.
- Tier-gated API endpoints: `/api/empower/*` endpoints must verify `empowered_profiles` record exists. `/api/connect/*` endpoints must verify `connected_profiles` exists.

**Complexity:** High. RLS policies interact with the schema in ways that are easy to misconfigure. Every new endpoint and policy must be tested against adversarial scenarios.

**Dependencies:** All table schemas, Supabase RLS, API endpoint implementation.

---

### 6. Admin Tooling (Internal)

**What it covers:** The internal React application for managing the Alpha cohort.

**Requirements for this system:**
- Invite management: view all outstanding and used invite codes, trace invite chains, revoke invite codes.
- Account review: view account details (including `tolerance_rating` and `legal_name` — fields only accessible to admins), manually approve/suspend/reinstate accounts.
- Manual verification approval: for v1 (invite-only), admin marks `verification_status = 'verified'` after review.
- Pilot cohort management: view cohort membership, enrollment status, account standing.
- Invite chain visibility: given an account, trace the full chain of who invited whom. This is the "Memory over Moderation" principle applied to enrollment.
- Account standing: admin can set `account_standing` field (suspension, quarantine, reinstatement).
- The admin tool lives in this repo (not a separate repo) for the pilot. Auth for admin is separate from user auth — admin users are not platform users.

**Complexity:** Medium. The invite chain visualization is the most complex UI piece. The underlying data model is straightforward if the invite system is well-built.

**Dependencies:** Invite system, `connected_profiles`, `empowered_profiles`, `account_standing` field, admin auth mechanism.

---

### 7. Audit Logging

**What it covers:** The permanent record of security-relevant events and tier transitions.

**Requirements for this system:**
- Tier transitions must be logged with timestamp, actor (user or system), and prior state. The invite chain is itself a form of audit log for enrollment.
- Sanction events (Tolerance Rating changes due to invitee sanctions) must be logged with inviter and invitee reference.
- Compass change history (`inform.compass_change_history`) is already modeled — this is the audit log for calibration changes. It must be append-only. No updates, no deletes.
- Admin actions (manual verification, suspension, invite revocation) must be logged with admin actor ID and timestamp.
- Failed empowerment transaction attempts should be logged (not just silently rolled back).
- Gem transactions (`connect.gem_transactions`) are append-only ledger — every gem has a memory. This is audit logging for the closed economy.

**Complexity:** Low for database-level event logging. Medium for admin action logging, which requires a dedicated log table and middleware.

**Dependencies:** All tier tables, compass change history table, gem ledger, admin tool.

---

### 8. Health Check Endpoint

**What it covers:** `GET /api/health`.

**Requirements:**
- Returns `{ status: 'ok', timestamp: Date.now() }`.
- Must be the first endpoint implemented. UptimeRobot depends on it.
- Should optionally include database connectivity check in response (useful for diagnosing cold-start issues).

**Complexity:** Trivial.

**Dependencies:** Express server setup.

---

### 9. Anonymous Compass Import

**What it covers:** Migrating localStorage calibration data into the database when a user creates a Connected account.

**Requirements for this system:**
- Import flow shows user their saved stances before committing — no silent migrations.
- User can review, update, or discard individual stances before import.
- Topic version mismatch handling: if a topic's stance options have changed since calibration, flag it. Do not silently import a now-invalid stance value.
- After successful import, localStorage is cleared.
- Import is optional — user can decline and start fresh.
- The import endpoint (`POST /api/connect/import-compass`) is authenticated and only available to `verification_status: 'pending'` or `'verified'` users.

**Complexity:** Medium. The mismatch handling and the user review step are the engineering complexity. The import itself is a straightforward bulk insert.

**Dependencies:** `connect.verification_sessions`, `inform.compass_responses`, `inform.compass_topics`, `inform.compass_stances`.

---

## Differentiators

> Features specific to this platform's values, architecture, or civic mission. Not found in generic account systems.

### 10. Invite-Based Alpha Enrollment with Chain Tracking

**What it covers:** Access-gated Alpha using invite codes, with the invite chain stored as a permanent record that affects inviter standing.

**Why it differentiates:**
- Not just invite codes — the chain has civic consequence. An inviter's Tolerance Rating is impacted when their invitee is sanctioned. This creates genuine skin in the game for who people invite.
- The invite chain is a trust graph, not just an access gate. It is a permanent, append-only record — "Memory over Moderation" applied to enrollment.

**Requirements for this system:**
- Invite codes are single-use, time-limited, and tied to the inviting account.
- The chain is stored: invitee → inviter → inviter's inviter, etc. At least one level of chain is required; full chain depth is useful for admin tooling.
- When an invitee is sanctioned, a cascade update to the inviter's Tolerance Rating is triggered. The sanction event and Tolerance Rating adjustment are both logged.
- Invite code revocation: admin can revoke an outstanding code. Already-used codes remain in the chain record (cannot rewrite history).
- Admin can view the full invite tree from any account.

**Complexity:** Medium. The data model is straightforward (invite_codes table with inviter_id, invitee_id, used_at). The Tolerance Rating cascade is the complex piece — it must be transactional and logged.

**Dependencies:** `connected_profiles.tolerance_rating`, admin tooling, sanction mechanism (partially out of scope — Communal Council — but the Tolerance Rating field and adjustment mechanism must exist in this repo).

---

### 11. Tolerance Rating and Veracity Rating Systems

**What it covers:** Two distinct reputation dimensions tracked per user.

**Why it differentiates:**
- Most platforms have a single reputation score. Empowered Vote separates *accuracy* (Veracity Rating — public, shown on all posts) from *civic engagement quality* (Tolerance Rating — private for Connected, public for Empowered).
- Tolerance Rating is never sold, never gamed via purchases, and never visible to peers for Connected accounts. This is a deliberate privacy-preserving design.
- Decreasing Tolerance Rating triggers a private, specific notification. The user knows what happened and why.

**Requirements for this system:**
- `veracity_rating` on `connected_profiles`: NUMERIC(4,2), public. Returned in post attribution contexts.
- `tolerance_rating` on `connected_profiles`: NUMERIC(4,2), private for Connected. **Never returned to other users via API.** Returned in full for Empowered users' public profiles.
- RLS must enforce this distinction. The API must enforce it redundantly.
- Tolerance Rating changes must trigger a private notification to the affected user with specific context (what happened, which event caused the change).
- Invite-chain Tolerance Rating cascade: described in Feature 10. The mechanism for applying a cascade adjustment must be in this repo even if the trigger logic lives in future repos.
- Volatility tracking on compass changes: 3+ changes to a single topic in 30 days, or extreme position swings without context annotation, should flag for backend review. Stored as a flag or computed metric — not exposed in v1 UI, but the data must be captured now.

**Complexity:** Medium. The data model is in place. The complexity is in (a) maintaining RLS discipline across all query paths, (b) the notification mechanism, and (c) the Tolerance Rating cascade from invite sanctions.

**Dependencies:** `connected_profiles`, `empowered_profiles`, invite chain system, notification system (out of scope for this repo — but the trigger event must fire).

---

### 12. Calibration Completeness Tracking and Lapse Enforcement

**What it covers:** Enforcing that Empowered Accounts maintain full compass calibration as topics evolve, with automatic demotion on lapse.

**Why it differentiates:**
- This is not a one-time verification — it's ongoing. Empowered civic leaders must keep their public stances current as new policy topics go live.
- The 30-day grace period, escalation warning at day 25, and automatic demotion are a scheduled enforcement system that most auth systems don't have.

**Requirements for this system:**
- When a new `inform.compass_topics` row is inserted with `status = 'live'`, all active Empowered Accounts must be identified and their calibration deadline recorded.
- Day 25: warning notification to affected users.
- Day 30: automatic demotion job fires. Uses same atomic demotion transaction as voluntary demotion.
- Re-empowerment path: after completing missing calibration, user can request re-empowerment via `POST /api/empower/confirm`. System re-runs pre-flight checks.
- `GET /api/compass/progress` endpoint returns calibration completeness — which topics are answered, which are missing, and whether the user is in a lapse window.
- Role-filtered completeness: a city council candidate's "fully calibrated" threshold differs from a US Congress candidate's. `inform.compass_topic_roles` drives this filter.

**Complexity:** High. The scheduled job is operationally complex. The role-filtered completeness calculation requires joins across multiple tables. The demotion transaction must be idempotent (safe to run twice without creating corrupt state).

**Dependencies:** `inform.compass_topics`, `inform.compass_topic_roles`, `inform.compass_responses`, `empower.empowered_profiles`, scheduled job infrastructure (Render cron-in-process), demotion transaction.

---

### 13. Gem Ledger (Closed Economy Enforcement)

**What it covers:** The full transaction history for Empowered Gems, balance enforcement, and reserve cap logic.

**Why it differentiates:**
- Gems are never sold, never traded outside the platform, and every gem has a memory of where it's been. This is a civic economy, not a virtual currency.
- The reserve cap (excess above cap is use-it-or-lose-it at next stipend) prevents hoarding and keeps the economy active.
- The ledger is append-only. No corrections, no deletions — only compensating transactions.

**Requirements for this system:**
- `connect.gem_transactions` is append-only. `amount` can be negative (debit) or positive (credit). `balance_after` is recorded on every transaction for fast balance reads.
- Balance enforcement: debit transactions must fail if `balance_after` would go below zero. This check must be atomic (check + debit in a single transaction).
- Reserve cap enforcement: at stipend time, balance is capped. Excess is recorded as an `'expired'` transaction before the new stipend credit.
- `feature_context` and `reference_id` fields allow tracing a gem transaction back to the specific feature and object that originated it.
- The ledger is visible to the account owner only. No social sharing of gem balances.
- The ledger is visible to admins for fraud review.

**Complexity:** Medium. The append-only ledger with atomic balance enforcement is the engineering challenge. The rest is bookkeeping.

**Dependencies:** `connect.connected_profiles.gem_balance`, `connect.gem_transactions`, stipend scheduler.

---

### 14. Role System (Junction Table, Soft Revocation)

**What it covers:** Assigning and revoking the 8 platform roles, with time-based history and multi-role support.

**Why it differentiates:**
- Roles are civic functions, not permission levels. A user can be a Moderator and a Juror simultaneously but cannot wear both hats in the same feature context.
- Soft revocation (`revoked_at` timestamp rather than row deletion) preserves the history of who held which role and when. Memory over Moderation.
- Role eligibility is tier-gated: Maven, Guide, Scribe require Empowered. All others require at minimum Connected.

**Requirements for this system:**
- `public.user_roles` junction table with `user_id`, `role_type` (ENUM), `granted_at`, `revoked_at` (NULL = active).
- `UNIQUE (user_id, role_type)` constraint ensures no duplicate active role records. Revocation sets `revoked_at`; re-grant inserts a new record (or updates if the unique constraint is relaxed to allow history rows).
- Active role query: `WHERE user_id = $id AND revoked_at IS NULL`.
- Role eligibility enforcement: admin tool must prevent granting a role to a user who lacks the prerequisite tier.
- The "cannot wear two hats in the same feature" constraint is a runtime check, not a schema constraint. Each feature enforces this in its own context.

**Complexity:** Low–medium. The schema is clean. The complexity is in the role eligibility enforcement and the two-hat runtime check (which lives in downstream feature repos, not here).

**Dependencies:** `public.users`, `connected_profiles`, `empowered_profiles`, `role_type` ENUM.

---

### 15. Account Standing Field

**What it covers:** A field that downstream features (Communal Council, admin actions) use to reflect account status beyond the verification flow.

**Why it differentiates:**
- The accounts system exposes `account_standing` as a field but does not own the logic for setting it. The Communal Council feature implements suspension mechanics. This keeps the accounts system clean while providing the hook.
- Inform Pillar access remains open regardless of account standing — civic information access is not contingent on good standing.

**Requirements for this system:**
- `account_standing` field on `connected_profiles` with values: `('active', 'suspended', 'quarantined')` or similar. Exact enum values to be confirmed.
- Default: `'active'`.
- Admin tool can set this field manually (for pilot-phase manual moderation).
- API responses must respect account standing: suspended accounts cannot post, cannot Connect-gate features, etc. The exact restrictions per standing level are documented in the API layer, not enforced by the field itself.
- Inform Pillar features must NOT check account standing — they are open to everyone.

**Complexity:** Low. The field is trivial. The complexity is in downstream features that consume it.

**Dependencies:** `connected_profiles`, admin tooling, downstream feature repos.

---

## Anti-Features

> Things to deliberately NOT build in v1. Each entry explains why exclusion is correct, not just deferred.

### A1. Custom Auth (Rolling Your Own JWT / Session Management)

**Why not:** Supabase Auth is production-grade, actively maintained, and handles JWTs, refresh tokens, session expiry, and password reset flows. Building this manually introduces a high surface area for security vulnerabilities and wastes significant engineering time on solved problems. The one exception: do not let Supabase Auth be the only layer — RLS and application checks remain.

**What to do instead:** Configure Supabase Auth correctly. Use it. Extend `auth.users` via `public.users`.

---

### A2. Self-Serve Account Recovery UI

**Why not:** For an Alpha with a small, invite-only cohort, self-serve recovery (password reset, "forgot my pseudonym") is handled by Supabase Auth's built-in flows and admin tooling. Building a custom recovery UI before the user base warrants it adds complexity and attack surface without meaningful benefit. The risk of a bad-actor exploiting a recovery flow to hijack an account is higher than the inconvenience of directing a small Alpha cohort to admin support.

**What to do instead:** Lean on Supabase Auth's built-in password reset. Document the admin process for manual account recovery in the pilot phase. Revisit after Alpha.

---

### A3. Third-Party Identity Verification Integration

**Why not:** Stripe Identity, Persona, and similar services are explicitly deferred to post-Alpha. The invite chain is the v1 trust mechanism. Integrating a KYC service prematurely locks in a vendor, introduces cost, and introduces a PII storage question that is not yet resolved. The open question around accessibility (undocumented citizens, users without government ID) has not been answered — the wrong choice here is architecturally harmful.

**What to do instead:** Invite-only Alpha. Manual admin verification. Schema is designed to accommodate a verification service later (`verification_method` field exists but is empty for now).

---

### A4. Public Invite Leaderboards or Invite Count Visibility

**Why not:** "You've invited 12 people" stats, leaderboards, or social sharing of invite counts creates a gameable incentive structure. Users will maximize invites rather than vet them. The invite system's civic purpose is accountability (your Tolerance Rating is at stake), not growth hacking. Public metrics corrupt this.

**What to do instead:** Invite chain is visible to admins only. The inviter sees that their invite was used (private confirmation), not a running tally to optimize.

---

### A5. Gem Purchases or Premium Gem Tiers

**Why not:** Selling civic influence is architecturally prohibited. The platform's equity of opportunity principle means no user can buy a better standing, a higher reach, or a louder voice. This is not a deferred decision — it is a permanent exclusion. Building any payment-to-gem pipeline, even "just for premium features," is a corruption of the closed economy model.

**What to do instead:** Gems are earned through participation and distributed as stipend. Full stop. No exceptions.

---

### A6. Social Login (OAuth with Google/Apple/Twitter)

**Why not:** Social login creates a dependency on the provider's identity model. If a user's Google account is suspended, they lose access to their civic account. More critically, social login does not solve the one-person-one-account problem — it just shifts the identity question to a provider who has no civic stake in getting it right. For a platform where one account equals one civic voice, social login is a structural mismatch.

**What to do instead:** Email/password via Supabase Auth for v1. Revisit after identity verification strategy is settled.

---

### A7. Communal Council Suspension Mechanics in This Repo

**Why not:** The accounts system exposes `account_standing` as a field. The logic for *how* a Communal Council decision gets translated into a suspension is the Communal Council feature's responsibility. Building suspension logic here creates a circular dependency and pulls out-of-scope complexity into the foundational repo.

**What to do instead:** Admin tool supports manual suspension via `account_standing`. Communal Council feature calls an API endpoint on this service to update standing when a council decision is finalized.

---

### A8. Demotion Public Record Handling

**Why not:** When an Empowered user demotes to Connected, their compass goes private and their candidate page deactivates. What happens to their Symposium posts, Empowered Bills, and Awareness Exchange history is a policy question for each of those features — not for the accounts system. Building this here requires knowing the answers to questions that are not yet answered (pseudonymize? preserve? hide?).

**What to do instead:** Accounts system sets `empowered_profiles.is_active = false`. Each downstream feature decides attribution policy in its own context.

---

### A9. Compass Issue Weighting

**Why not:** A `weight` field on `compass_responses` is a future-state feature. The schema can accommodate it later (a single column addition). Building it now without knowing how the weighting algorithm works, how it affects matching, or how it is displayed adds dead weight to the schema and API.

**What to do instead:** Schema is designed to accommodate it. Do not build it. Add when the weighting algorithm is defined.

---

### A10. End-User Frontend in This Repo

**Why not:** User-facing flows (Connect flow, Empowerment flow, compass calibration UI) live in feature repos that call this API. Mixing a user-facing frontend into the accounts repo conflates two concerns and makes Framer integration more complex. The admin tool is the only UI that lives here.

**What to do instead:** Build clean, documented API endpoints. Feature repos build UI against those endpoints.

---

## Feature Dependency Map

```
Supabase Auth (auth.users)
    └── public.users [creation trigger]
        ├── connected_profiles [Connect flow]
        │   ├── verification_sessions [resumable verification]
        │   ├── peer_connections [mutual connections]
        │   ├── account_follows [1-way follows toward Empowered]
        │   ├── gem_transactions [closed economy ledger]
        │   ├── tolerance_rating [invite cascade target]
        │   └── account_standing [admin + Communal Council hook]
        │
        ├── empowered_profiles [atomic empowerment transaction]
        │   ├── compass_responses [batch visibility update on transition]
        │   ├── candidate_page_slug [generated at empowerment]
        │   └── calibration_lapse_enforcement [scheduled job]
        │
        ├── user_roles [junction table]
        │   └── role_type ENUM
        │
        └── invite_codes [Alpha enrollment gating]
            └── invite_chain [permanent record, affects tolerance_rating]

inform.compass_topics
    ├── compass_stances [5 preset stances per topic]
    ├── compass_topic_roles [role-filtered calibration requirements]
    ├── compass_responses [user calibration, visibility-gated]
    └── compass_change_history [append-only audit log]
```

**Critical path for v1:**
1. Supabase Auth + `public.users` (everything depends on this)
2. `connect.connected_profiles` + RLS (most features gate on this)
3. Invite system (Alpha enrollment gate)
4. `empower.empowered_profiles` + atomic transaction (Empowerment flow)
5. `inform.compass_*` tables (calibration completeness check for empowerment)
6. Gem ledger (economy)
7. Roles (feature enablement)
8. Admin tool (operational readiness for pilot)
9. Calibration lapse scheduler (ongoing enforcement)

---

## Complexity Summary

| # | Feature | Category | Complexity |
|---|---------|----------|------------|
| 1 | Account Lifecycle (create/delete) | Table Stakes | Low–Medium |
| 2 | Session Handling | Table Stakes | Low |
| 3 | Verification Flow (Connect) | Table Stakes | Medium |
| 4 | Atomic Tier Transitions | Table Stakes | High |
| 5 | Authorization Enforcement (RLS) | Table Stakes | High |
| 6 | Admin Tooling | Table Stakes | Medium |
| 7 | Audit Logging | Table Stakes | Low–Medium |
| 8 | Health Check Endpoint | Table Stakes | Trivial |
| 9 | Anonymous Compass Import | Table Stakes | Medium |
| 10 | Invite Chain with Standing Cascade | Differentiator | Medium |
| 11 | Tolerance + Veracity Rating Systems | Differentiator | Medium |
| 12 | Calibration Lapse Enforcement | Differentiator | High |
| 13 | Gem Ledger (Closed Economy) | Differentiator | Medium |
| 14 | Role System (Junction + Soft Revoke) | Differentiator | Low–Medium |
| 15 | Account Standing Field | Differentiator | Low |
| A1 | Custom Auth | Anti-Feature | — |
| A2 | Self-Serve Recovery UI | Anti-Feature | — |
| A3 | Third-Party KYC Integration | Anti-Feature | — |
| A4 | Public Invite Leaderboards | Anti-Feature | — |
| A5 | Gem Purchases / Premium Tiers | Anti-Feature | — |
| A6 | Social Login (OAuth) | Anti-Feature | — |
| A7 | Communal Council Suspension Logic | Anti-Feature | — |
| A8 | Demotion Public Record Handling | Anti-Feature | — |
| A9 | Compass Issue Weighting | Anti-Feature | — |
| A10 | End-User Frontend in This Repo | Anti-Feature | — |

---

## Open Questions Surfaced by This Research

These are not blockers for FEATURES.md but must be resolved before implementation:

1. **`account_standing` enum values:** What are the valid states? `('active', 'suspended', 'quarantined')` is a proposal; confirm with platform design before writing the schema.
2. **Tolerance Rating cascade depth:** Does the sanction cascade up the entire invite chain (inviter, inviter's inviter, etc.) or only one level? This affects the chain-traversal query complexity significantly.
3. **Soft delete vs. hard delete:** Does account deletion scrub all PII and de-identify content, or does it result in hard removal? The "Memory over Moderation" principle suggests de-identification, but this has not been formally decided.
4. **Session policy differentiation by tier:** Should Empowered users have shorter session expiry than Connected users given higher data exposure? A reasonable default is yes, but the specific duration should be documented.
5. **Slug collision handling at empowerment:** If two users with the same legal name empower simultaneously, the slug generation must be deterministic. The collision strategy (numeric suffix, random string) should be decided before implementation.
6. **Admin auth mechanism:** How do admins authenticate to the internal admin tool? Supabase Auth with a separate admin user type? A hardcoded admin flag on `auth.users`? This needs a decision before the admin tool is built.

---

*Research complete. Feed this document into requirements definition and phase planning.*
*Source documents read: `empowered-accounts-design.md`, `empowered-vote-primer.md`, `.planning/PROJECT.md`*
