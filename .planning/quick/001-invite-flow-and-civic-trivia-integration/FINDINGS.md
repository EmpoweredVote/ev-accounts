# Quick Task 001 — Findings

**Date:** 2026-02-28
**Questions answered:**
1. How does the invite flow work end-to-end? How do users enter a code?
2. What features/routes are currently integrated with the account system?
3. Can Civic Trivia Championships integrate, and what would that take?

---

## Section 1: Invite Flow (End-to-End)

### The Big Picture

The invite system is the trust gate for Alpha enrollment. A new account starts at the **Inform** tier — they can log in and use compass features, but they cannot participate in civic discussions, hold roles, or appear in the social graph. To level up to **Connected** tier, a user must receive an invite code from someone who is already Connected.

Critically: **invite codes are not collected at signup**. Email+password signup is open. The invite code is collected later, at the start of the Connect verification flow.

---

### Step 0 — Signup (open, no invite required)

```
POST /api/auth/signup
Body: { email, password }
Returns: { id, message: "Check your email to confirm your account" }
```

Any person can create an account. A Supabase Auth user is created, a `public.users` row is auto-created via database trigger, and no tier record exists yet. The user is at Inform tier by definition (no child records).

There is no invite code field on this endpoint. Invite codes are used later.

---

### Step 1 — How a Connected User Generates an Invite Code

```
POST /api/invites/send
Auth: Bearer token (requireAuth + requireConnected)
Returns: { code: "A3B7-XK29" }
```

**Code format:** 8 alphanumeric characters separated by a hyphen — `XXXX-XXXX` (e.g., `A3B7-XK29`). Uses a 32-character charset (`ABCDEFGHJKLMNPQRSTUVWXYZ23456789`) that omits visually ambiguous characters (no O, I, L, 0, 1). Uses `crypto.randomBytes` for cryptographically secure generation. No modulo bias.

**Business rules:**
- Only Connected users with `verification_status = 'verified'` can generate codes.
- A user may hold at most **5 unclaimed codes** at one time. If they already have 5 pending, the endpoint returns `409 INVITE_LIMIT_REACHED`.
- Rate limited: max **10 sends per user per 24-hour window**.
- Codes are stored in `connect.invite_codes` with `created_by = userId`.
- Expiration: `expires_at` is set by the `create_invite_codes` RPC (server-side).

**Implementation:** `POST /send` → `createInviteCodes(userId, 1)` in `inviteService.ts` → `create_invite_codes` SECURITY DEFINER RPC (handles collision retry server-side, up to 3 attempts per slot).

---

### Step 2 — How a User Inputs an Invite Code (Two Paths)

There are **two ways** to claim an invite code. They are functionally different.

#### Path A: Standalone Claim (pre-flow claim)

```
POST /api/invites/claim
Auth: Bearer token (requireAuth — no tier requirement)
Body: { code: "A3B7-XK29" }
Returns: { claimed: true, inviter_id: "<uuid>" }
```

This marks the code as used and returns the inviter's ID (e.g., so the UI can show "You were invited by Jane Doe"). It does NOT start the verification session. The user would still need to call `POST /connect/start` separately — but `/start` will fail if the code is already claimed.

Use case: a future flow where code entry and profile collection are on separate screens, or if you want to validate the code before collecting profile info.

#### Path B: Connect/Start (claim + start verification in one call) — MAIN PATH

```
POST /api/connect/start
Auth: Bearer token (requireAuth — no tier requirement)
Body: { code: "A3B7-XK29" }
Returns: { session_id, step_reached: "profile", drafts: {...} }
```

This is the primary path. It:
1. Checks the user is not already Connected (returns `409 ALREADY_CONNECTED` if so).
2. Checks for an existing verification session (allows resuming an abandoned flow).
3. Claims the invite code atomically (the `claim_invite_code` SECURITY DEFINER RPC uses `FOR UPDATE` locking — two concurrent claims on the same code cannot both succeed).
4. Creates or upserts a `connect.verification_sessions` row at step `'profile'`, recording the `invite_code_id`.

The code is normalized to uppercase before lookup, so users who type in lowercase are not rejected.

**Claim error codes:**
- `404 INVALID_CODE` — code not found
- `409 CODE_ALREADY_CLAIMED` — already used
- `410 CODE_EXPIRED` — past expiration
- `403 SELF_INVITE_BLOCKED` — cannot claim your own code

---

### Step 3 — Profile Collection (Connect Flow Step: profile)

```
PATCH /api/connect/step
Auth: Bearer token (requireAuth)
Body: {
  step: "profile",
  display_name: "Jane Doe",
  legal_name: "Jane Mary Doe",
  location: "California",
  home_address: "123 Main St, Sacramento CA 95814"
}
Returns: { session_id, step_reached: "profile"|"review", drafts: {...} }
```

The user fills in four required fields. The client can call this endpoint multiple times (fields are merged). When all four fields are present and the client sends `step: "review"`, the session advances to `'review'`.

**Field mapping note:** `location` in the request body maps to `region_draft` in the database schema.

---

### Step 4 — Review and Finalize (Connect Flow Step: review → complete)

```
POST /api/connect/complete
Auth: Bearer token (requireAuth)
Body: (empty)
Returns: { connected: true, verification_status: "verified", tier: "connected" }
```

This calls the `complete_connect_flow` SECURITY DEFINER RPC, which:
1. Locks the verification session with `FOR UPDATE`.
2. Validates step is `'review'` and all required fields are present.
3. Checks idempotency (existing `connected_profiles` row = already done).
4. **Atomically inserts** a `connect.connected_profiles` row.
5. Advances the session to `'complete'`.
6. Syncs `display_name` to `public.users`.

After this call, the user is at Connected tier. `tier: 'connected'` is determined by the presence of the `connected_profiles` row — not a status flag.

**Privacy note:** `tolerance_rating` and `legal_name` are never returned by this endpoint (serialization-layer enforcement beyond RLS).

---

### Optional: Compass Import During Connect Flow

```
POST /api/connect/compass-import
Auth: Bearer token (requireAuth — must have active verification session)
Body: { calibrations: [{topic_id, topic_version, stance_id, inverted?}], confirmed: boolean }
```

Two-phase import for anonymous compass calibrations done before account creation:
- Phase 1 (`confirmed: false`): validates topic versions against live server versions, returns `{ valid, mismatched, ready_to_import }`.
- Phase 2 (`confirmed: true`): stores calibrations as a JSON draft in `verification_sessions.compass_import_draft`.

The draft is lazily promoted to `inform.compass_responses` on the first call to `GET /api/compass/answers` after the Connect flow completes.

---

### Step 5 — Check Status at Any Time

```
GET /api/connect/status
Auth: Bearer token (requireAuth)
Returns one of:
  { status: 'not_started' }
  { status: 'in_progress', step_reached: 'profile'|'review'|'complete' }
  { status: 'verified'|'pending'|'suspended' }
```

---

### Invite Chain Accountability

When a code is claimed (successfully), the `claim_invite_code` RPC inserts a row into `connect.invite_chains`:
```
{ inviter_id, invitee_id, invite_code_id }
```
This is a permanent link. `UNIQUE(invitee_id)` enforces that each person has exactly one inviter in their history.

**Consequence:** If the invitee is later sanctioned (suspended for bad behavior), an admin calls `connect.adjust_inviter_tolerance_rating(invitee_id)`, which:
- Decrements the inviter's `tolerance_rating` by 0.10 (floors at 0.00).
- Auto-suspends the inviter's account if TR reaches 0.00.
- Inserts a notification event for the inviter.

Admin-generated codes have `created_by = NULL` in `invite_codes` — no chain record is inserted, so no TR adjustment applies.

---

### Invite Flow State Machine (Summary)

```
Signup (email+password, open)
    |
    v
Inform tier user (can use compass, cannot generate invites)
    |
    | [User has a code]
    v
POST /api/connect/start { code }     <- User inputs code HERE
    |
    v
Verification session created, step = "profile"
    |
    v
PATCH /api/connect/step (fill display_name, legal_name, location, home_address)
    |
    v
step = "review" (when all fields present)
    |
    v
POST /api/connect/complete
    |
    v
Connected tier (connected_profiles row exists, verification_status = 'verified')
```

---

## Section 2: Current API Surface

**Base URL:** `https://<host>/api`
**Auth header:** `Authorization: Bearer <access_token>`

Auth levels used below:
- **None** — no token required
- **Auth** — valid JWT required (`requireAuth`)
- **Auth+Standing** — valid JWT required + account must be active (not suspended)
- **Connected** — valid JWT + `connect.connected_profiles` row with `verification_status = 'verified'`
- **Empowered** — valid JWT + `empower.empowered_profiles` row with `is_active = true`
- **Admin** — valid JWT + admin role (`requireAdmin`)
- **Optional** — JWT processed if present, but not required

---

### Health (1 route)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/health` | None | Returns `{ status: "ok", timestamp }` |

---

### Auth (4 routes)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/auth/signup` | None | Create account (email+password). Rate limited: 10/15min/IP. Returns `{ id }`. |
| POST | `/api/auth/login` | None | Authenticate. Rate limited: 10/15min/IP. Returns `{ access_token, refresh_token, expires_in, user }`. |
| POST | `/api/auth/logout` | Auth | Invalidate session globally (all devices). Always returns 200. |
| POST | `/api/auth/complete-onboarding` | Auth | Sets `completed_onboarding = true` on `connected_profiles`. Requires Connected tier. Idempotent. |

---

### Account (2 routes)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/account/me` | Auth | Full profile: tier, standing, connected_profile (with tolerance_rating), empowered_profile. |
| PATCH | `/api/account/me` | Connected | Update `display_name` and/or `avatar_url`. Syncs to `connected_profiles`. |

**GET /account/me response shape:**
```json
{
  "id": "uuid",
  "email": "...",
  "display_name": "...",
  "avatar_url": null,
  "tier": "inform|connected|empowered",
  "empowerment_status": "empowered|demoted",  // only if empowered_profiles row exists
  "account_standing": "active|suspended",
  "connected_profile": {                        // only if Connected+
    "display_name": "...",
    "verification_status": "verified|pending|suspended",
    "tolerance_rating": 10.00,                  // owner only
    "xp": 0,
    "gem_balance": 0,
    "completed_onboarding": false,
    "created_at": "..."
  },
  "empowered_profile": {                        // only if Empowered+
    "legal_name": "...",                        // owner only
    "is_active": true,
    "candidate_page_slug": "john-smith-a3b4",
    "empowered_at": "...",
    "demoted_at": null
  }
}
```

---

### Invites (3 routes)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/invites/send` | Connected | Generate invite code. Max 5 unclaimed pending. Rate: 10/day/user. Returns `{ code }`. |
| POST | `/api/invites/claim` | Auth | Standalone code claim (no Connect session started). Returns `{ claimed: true, inviter_id }`. |
| GET | `/api/invites/mine` | Connected | List own invite codes (id, code, is_claimed, claimed_at, expires_at). UUIDs redacted. |

---

### Connect (5 routes)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/connect/start` | Auth | Input invite code + start verification session. Returns session state. |
| PATCH | `/api/connect/step` | Auth | Update profile draft fields (display_name, legal_name, location, home_address). Advances step to 'review' when all fields present. |
| POST | `/api/connect/complete` | Auth | Finalize: atomically create connected_profiles. Returns `{ connected: true, tier: "connected" }`. |
| GET | `/api/connect/status` | Auth | Check verification stage (not_started / in_progress / verified / pending / suspended). |
| POST | `/api/connect/compass-import` | Auth | Two-phase anonymous compass import. Phase 1: validate. Phase 2 (confirmed=true): store draft. |

---

### Compass (11 routes)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/compass/topics` | Optional | All live topics with nested stances, categories, role scopes. |
| GET | `/api/compass/categories` | Optional | All categories with nested live topics. |
| GET | `/api/compass/answers` | Auth | User's own compass responses (triggers lazy compass import promotion). |
| POST | `/api/compass/answers/batch` | Auth | Get answers for specific topic IDs. Body: `{ ids: uuid[] }`. |
| POST | `/api/compass/answers` | Auth | Upsert single answer. Body: `{ topic_id, value (1-5), write_in_text?, inverted? }`. |
| GET | `/api/compass/selected-topics` | Auth | User's saved topic IDs. Returns 403 if not Connected. |
| PUT | `/api/compass/selected-topics` | Auth | Save selected topic IDs (validated against live topics). Body: `{ topic_ids: uuid[] }`. |
| GET | `/api/compass/progress` | Auth | Calibration completeness. Optional `?role=` param for role-scoped count. |
| GET | `/api/compass/politicians` | Optional | All active politicians (name, office, photo). |
| GET | `/api/compass/politicians/:id/answers` | Optional | Politician's stances on topics. |
| GET | `/api/compass/politicians/:id/:topicId/context` | Optional | Politician's reasoning + sources for a topic. |

---

### Empower (3 routes)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/empower/preflight` | Connected | Check all empowerment conditions. Returns `{ eligible, failures?, summary? }`. Reserves slug in cache for 1h if eligible. |
| POST | `/api/empower/confirm` | Connected | Finalize empowerment with 3-item consent. Body: `{ consent: { legal_name_public: true, compass_stances_public: true, platform_terms: true } }`. Returns `{ empowered: true, profile }`. |
| POST | `/api/empower/demote` | Connected | Self-demote back to Connected tier. Optional reason body. |

---

### Gems (2 routes)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/gems/balance` | Connected | Current gem balances by type (red, blue, yellow). |
| GET | `/api/gems/transactions` | Connected | Paginated transaction history. Query: `gem_type?`, `limit` (max 100), `offset`. |

---

### Roles (2 routes)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/roles` | Auth | List all active roles in the system with tier requirements. |
| GET | `/api/roles/me` | Connected | User's own active (non-revoked) role grants. |

---

### Social (8 routes)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/social/peers/request` | Connected | Send peer connection request to another Connected+ user. |
| PATCH | `/api/social/peers/:id/accept` | Connected | Accept a pending peer request (addressee only). |
| PATCH | `/api/social/peers/:id/decline` | Connected | Decline a pending peer request (addressee only). |
| POST | `/api/social/peers/block` | Connected | Block a user (converts peer relationship, removes follows). |
| GET | `/api/social/peers` | Connected | List own peer connections (pending and accepted). |
| POST | `/api/social/follow` | Connected | Follow an Empowered account. |
| DELETE | `/api/social/follow/:target_id` | Connected | Unfollow. Idempotent. |
| GET | `/api/social/following` | Connected | List Empowered accounts the user follows. |
| GET | `/api/social/followers/count/:user_id` | Auth | Follower count for an Empowered profile (public). |

---

### Admin (19 routes)

All admin routes require `requireAuth + requireAdmin`. Every mutation is logged to `admin_audit_log`.

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/admin/me` | Confirm admin status. Returns `{ isAdmin: true }`. |
| GET | `/api/admin/dashboard` | Cohort stats: users by tier/standing, pending verifications, invite counts. |
| GET | `/api/admin/accounts` | List accounts. Query: `search?`, `tier?`, `standing?`, `page?`. |
| GET | `/api/admin/accounts/:userId` | Full account detail (tolerance_rating, legal_name, roles, audit log). Logged. |
| POST | `/api/admin/accounts/:userId/suspend` | Suspend account. |
| POST | `/api/admin/accounts/:userId/unsuspend` | Unsuspend account. |
| POST | `/api/admin/accounts/:userId/demote` | Force-demote an Empowered user. |
| GET | `/api/admin/invites/tree` | Full cohort invite tree (React Flow format). |
| GET | `/api/admin/invites/tree/:userId` | Invite subtree rooted at a user. |
| GET | `/api/admin/invites` | List all invite codes with creator/claimer info. Paginated. |
| POST | `/api/admin/invites` | Create admin invite code (bypasses Connected requirement). |
| DELETE | `/api/admin/invites/:codeId` | Revoke an active invite code. |
| POST | `/api/admin/roles/grant` | Grant a role to a user. |
| POST | `/api/admin/roles/revoke` | Revoke a role from a user. |
| POST | `/api/admin/compass/topics` | Create a compass topic. |
| PUT | `/api/admin/compass/topics/:id` | Update a compass topic (title, question_text, is_live). |
| PUT | `/api/admin/compass/stances/:id` | Update a compass stance. |
| PUT | `/api/admin/compass/politicians/:id/answers` | Bulk upsert politician answers. |
| POST | `/api/admin/compass/politicians/:id/context` | Upsert politician reasoning + sources for a topic. |
| GET | `/api/admin/essentials/politicians` | List all politicians including inactive (admin view). |
| GET | `/api/admin/cron-log` | Calibration lapse cron run log. Paginated. |

---

### Public Candidates (2 routes)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/candidates/:slug` | Optional | Public candidate profile by slug. Returns 404 if not found. Includes inactive (demoted) candidates with `active: false`. |
| GET | `/api/candidates/:slug/answers` | Optional | Candidate's compass answers. Required query: `?topics=uuid1,uuid2`. Optional: `?inverted=uuid1`. |

---

### Essentials (1 route)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/essentials/candidates/:zip` | Optional | Active candidates for a ZIP code (5-digit or ZIP+4). Returns `[]` for valid ZIP with no candidates. |

---

### Total Route Count

| Domain | Routes |
|--------|--------|
| Health | 1 |
| Auth | 4 |
| Account | 2 |
| Invites | 3 |
| Connect | 5 |
| Compass | 11 |
| Empower | 3 |
| Gems | 2 |
| Roles | 2 |
| Social | 9 |
| Admin | 21 |
| Candidates | 2 |
| Essentials | 1 |
| **Total** | **66** |

---

## Section 3: Civic Trivia Championships Integration

### What Civic Trivia Gets for Free

The account system is already a complete identity, trust, and rewards infrastructure. Civic Trivia does not need to build:
- User authentication (Supabase JWTs, signup/login/logout)
- Account tiers (Inform/Connected/Empowered) with permission gates
- Invite-based enrollment for trusted cohort management
- Gem ledger (red/blue/yellow gems with transaction history)
- Role system (assigning roles like "Tournament Host" to users)
- Social graph (follows, peer connections) so users can find opponents
- Admin dashboard (user management, suspend/unsuspend, invite management)
- Calibration compass (civic knowledge baseline already in place)

### Option A: Shared Supabase Project (Recommended for Alpha)

Civic Trivia runs in the **same Supabase project**. Users authenticate once and the JWT works across both the accounts API and any Civic Trivia API.

**How it works:**

1. **Auth is identical.** A user logs in via `POST /api/auth/login` and gets an `access_token`. That token is a standard Supabase JWT signed by the same key. Civic Trivia's backend verifies it the same way — check the issuer and audience:
   ```typescript
   // From backend/src/middleware/auth.ts
   const { payload } = await jwtVerify(token, secretKey, {
     issuer: `${SUPABASE_URL}/auth/v1`,
     audience: 'authenticated',
   });
   // payload.sub is the userId
   ```
   Civic Trivia can copy this exact pattern (or extract it into a shared package).

2. **Civic Trivia adds its own Postgres schema.** No conflicts with the existing `public`, `connect`, `empower`, and `inform` schemas. Add a `trivia` schema:
   ```sql
   CREATE SCHEMA trivia;
   CREATE TABLE trivia.championships (...);
   CREATE TABLE trivia.rounds (...);
   CREATE TABLE trivia.player_scores (...);
   ```

3. **Tier checks via API or direct query.** Civic Trivia can call `GET /api/account/me` with the user's JWT to get their tier, or query `connect.connected_profiles` directly via the Supabase SDK using the same service role key.

4. **Environment variables.** Civic Trivia needs:
   ```
   SUPABASE_URL=<same project URL>
   SUPABASE_ANON_KEY=<same anon key>
   SUPABASE_SERVICE_ROLE_KEY=<same service role key>
   SUPABASE_JWT_SECRET=<same JWT secret, if using HS256>
   ```
   These are already available since Civic Trivia is on the same project.

**Pros:** Simplest possible integration. Zero auth plumbing. Shared user accounts from day one.
**Cons:** Tight coupling to the Empowered Accounts Supabase project. Trivia schema lives in the same DB.

---

### Option B: Separate Supabase Project with Cross-Service Auth

Civic Trivia has its own Supabase project. Users must authenticate separately, or a shared auth layer is introduced.

**How it works:**
- Users authenticate against Empowered Accounts, get a JWT.
- Civic Trivia accepts that JWT only if both projects share the same JWT secret (a Supabase configuration option) OR a custom auth proxy verifies the token against the Empowered Accounts project.

**Pros:** Full isolation. Trivia can be developed/deployed independently.
**Cons:** Requires coordinating two Supabase projects, shared JWT secrets, and a custom token exchange layer. Users may need separate accounts unless SSO is implemented. Significantly more complexity for Alpha.

---

### Recommendation: Option A for Alpha

Shared Supabase project is the right choice for Alpha for three reasons:

1. **Zero user friction.** A Connected user logs in once and immediately has a Civic Trivia account. No second signup, no linking flow.
2. **Tier enforcement is free.** Civic Trivia can require Connected tier to participate in championships by checking `connect.connected_profiles` existence — one DB query. This prevents bot accounts from flooding leaderboards.
3. **Gem integration is trivial.** Award trivia points as gems by calling the existing gem ledger. The ledger is already built, audited, and admin-visible.

---

### Concrete Integration Path (Option A)

#### Step 1: Add the trivia schema in a Supabase migration

```sql
CREATE SCHEMA trivia;

CREATE TABLE trivia.questions (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question     TEXT NOT NULL,
  options      JSONB NOT NULL,  -- e.g., [{"label":"A","text":"..."},...]
  correct      TEXT NOT NULL,
  category     TEXT,
  difficulty   SMALLINT CHECK (difficulty BETWEEN 1 AND 5),
  is_live      BOOLEAN NOT NULL DEFAULT false,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE trivia.championships (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title        TEXT NOT NULL,
  starts_at    TIMESTAMPTZ NOT NULL,
  ends_at      TIMESTAMPTZ NOT NULL,
  status       TEXT NOT NULL DEFAULT 'scheduled',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE trivia.player_scores (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  championship_id UUID NOT NULL REFERENCES trivia.championships(id),
  user_id         UUID NOT NULL REFERENCES public.users(id),
  score           INTEGER NOT NULL DEFAULT 0,
  correct_count   INTEGER NOT NULL DEFAULT 0,
  submitted_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (championship_id, user_id)
);
```

#### Step 2: Copy the auth middleware pattern

```typescript
// trivia-backend/src/middleware/auth.ts
// Same pattern as backend/src/middleware/auth.ts
import { jwtVerify, createRemoteJWKSet } from 'jose';

const SECRET_KEY = process.env.SUPABASE_JWT_SECRET
  ? new TextEncoder().encode(process.env.SUPABASE_JWT_SECRET)
  : null;
const JWKS = SECRET_KEY
  ? null
  : createRemoteJWKSet(new URL(`${process.env.SUPABASE_URL}/auth/v1/.well-known/jwks.json`));

export async function requireAuth(req, res, next) {
  const token = req.headers.authorization?.slice(7);
  if (!token) return res.status(401).json({ error: 'Missing token' });
  const { payload } = await jwtVerify(token, SECRET_KEY ?? JWKS, {
    issuer: `${process.env.SUPABASE_URL}/auth/v1`,
    audience: 'authenticated',
  });
  req.userId = payload.sub;
  req.accessToken = token;
  next();
}
```

Alternatively, if Civic Trivia is deployed in the same Express process (or same monorepo), this middleware is already available from `backend/src/middleware/auth.ts`.

#### Step 3: Add a requireConnected guard for Civic Trivia

Since Civic Trivia should only allow verified Connected users to compete (to prevent bot spam on leaderboards):

```typescript
// trivia-backend/src/middleware/tierGuards.ts
import { supabaseAdmin } from './supabase'; // same project = same client

export async function requireConnected(req, res, next) {
  const { data } = await supabaseAdmin
    .schema('connect')
    .from('connected_profiles')
    .select('id, verification_status')
    .eq('user_id', req.userId)
    .maybeSingle();

  if (!data || data.verification_status !== 'verified') {
    return res.status(403).json({ error: 'Connected account required to compete' });
  }
  next();
}
```

This is identical to the pattern in `backend/src/middleware/tierGuards.ts`.

#### Step 4: Gem rewards integration (optional but straightforward)

The existing gem ledger has an RPC function `award_gems(user_id, gem_type, amount, reason)` (or equivalent — check the gemService). Civic Trivia can call this via `supabaseAdmin.rpc(...)` to award gems for winning a championship:

```typescript
// After trivia championship ends, award winner
await supabaseAdmin.rpc('award_gems', {
  p_user_id: winnerId,
  p_gem_type: 'yellow',     // yellow = Inform/civic knowledge features
  p_amount: 50,
  p_reason: 'trivia_championship_win',
  p_source: 'civic_trivia',
});
```

Winners' gem balances are immediately visible in the Empowered Accounts admin UI and in `GET /api/gems/balance`.

#### Step 5: Admin UI extension (optional)

The existing admin UI (Vite + React at `/admin`) can be extended with a trivia management section. The `requireAdmin` middleware pattern is already extracted and reusable. Alternatively, Civic Trivia builds its own admin screen — the admin auth pattern is the same JWT + role check.

---

### What Civic Trivia Still Needs to Build

| Component | Notes |
|-----------|-------|
| Trivia question bank | Questions, options, correct answers, categories, difficulty |
| Championship management | Create/schedule championships, set question sets |
| Game session logic | Real-time or turn-based round management |
| Scoring engine | Calculate scores, handle ties |
| Leaderboard | Per-championship and all-time |
| Trivia frontend | Web or mobile client |
| Civic Trivia API routes | `POST /api/trivia/enter`, `GET /api/trivia/championships`, etc. |

---

### What Civic Trivia Does NOT Need to Build (It Exists)

| Component | Available via |
|-----------|---------------|
| User auth (signup, login, JWT) | Existing accounts API |
| Account tiers (Inform/Connected/Empowered) | `requireConnected` / `requireEmpowered` middleware |
| Invite enrollment system | Existing invite system |
| Gem ledger + awards | `gemService` + RPC |
| Role system ("Tournament Host" role) | `POST /api/admin/roles/grant` |
| Social follows (find opponents) | `GET /api/social/following` |
| Admin user management | Existing admin UI + API |
| Civic calibration data | Compass responses available to query |

---

### Summary Table: Integration Effort

| Task | Effort | Notes |
|------|--------|-------|
| Auth setup | Minimal | Copy middleware from accounts repo |
| Database schema | Medium | New `trivia.*` tables in same Supabase project |
| Tier guards | Minimal | Copy pattern from `tierGuards.ts` |
| Gem awards | Minimal | One RPC call per award event |
| Role grants | None | Use existing `/api/admin/roles/grant` |
| Leaderboard | Medium | New API routes + frontend |
| Game engine | High | Custom; depends on trivia format |
| Admin UI | Low–Medium | Extend existing or build separate tab |

**Bottom line:** Civic Trivia can share the entire identity, trust, and rewards infrastructure. The integration cost is primarily the game-specific logic (questions, rounds, scoring), not the account/auth plumbing. Estimate: 1–2 days to wire auth + tier guards, then build the trivia game on top.
