# Empowered Accounts — System Onboarding

**Audience:** New contributors, UX collaborators (Chris Andrews), and security reviewers.
**Last updated:** 2026-03-10 (v1.3 in progress, Phases 17–18 complete)

---

## What This Is

`empowered-accounts` is the foundational identity and permission infrastructure for the Empowered Vote platform. It is not a feature — it is the layer every feature attaches to. Every question of the form "can this user do X?" is answered by querying this system.

It is a REST API (Express 4.x / TypeScript) backed by Supabase (Postgres + Auth + RLS). It has no end-user UI — frontend experiences live in feature repos that call this API. The one exception is an internal React admin tool (Vite + Tailwind) that lives in `/admin`.

**Current state:** v1.3 in progress (Phases 1–18 complete, Phases 19–23 underway). ~13,500 lines of TypeScript across backend and admin.

---

## Platform Context (Why This Exists)

Empowered Vote is a civic infrastructure project with two design horizons:

1. **Near-term:** Reduce political polarization in Bloomington, Indiana. Pilot is invite-only Alpha with Monroe County residents — IU students, local civic participants.
2. **Long-term:** Build a model of democratic participation that would still work for the first Martian colonists — systems that can't be corrupted by self-interest because they're value-driven by design.

The platform has three pillars:

| Pillar | Problem It Solves | Who | Privacy |
|--------|------------------|-----|---------|
| **Inform** | Information pollution | Everyone — no account needed | Fully anonymous |
| **Connect** | Political polarization | Authenticated, pseudonymous citizens | Pseudonym only |
| **Empower** | Civic impotence | Civic leaders who want real democratic impact | Real name, public |

This repo implements the account tier that underlies all three.

---

## The Three-Tier Architecture

### Core Principle

**Tier = child record presence. Never a status flag.**

```
auth.users                       ← Supabase Auth (UUID, email, password hash)
    └── public.users             ← our extension (slug, account_standing, invite chain)
        ├── connect.connected_profiles   ← EXISTS = Connected tier
        └── empower.empowered_profiles   ← EXISTS = Empowered tier (requires connected)
```

A user's tier is determined entirely by which child records exist:

| Tier | What Exists | Who They Are |
|------|------------|--------------|
| **Inform** | `public.users` only | Anonymous or basic account — can use all Inform features |
| **Connected** | + `connected_profiles` | Pseudonymous civic participant — full Connect access |
| **Empowered** | + `empowered_profiles` | Civic leader with a public record — full Empower access |

This design means a single `JOIN` determines authorization. No flag chains, no application-level guesses, no partial states. A row either exists or it doesn't.

### Inform Tier

Anyone can create an account. Inform features (Compass calibration, Essentials, Civic Trivia) work without any verification. Anonymous users can earn XP and badges — they just can't display them publicly (no profile to show on).

**Stored data:** UUID, email (in auth.users), optional slug, account_standing.

### Connected Tier

A Connected user has passed invite-based verification and accepted the Connect terms. They receive a pseudonymous display name that separates their civic identity from their real identity.

**Key Connected data:**
- `display_name` — pseudonym, shown in all Connect contexts
- `tolerance_rating` — internal trust score (NEVER returned to other users, enforced at RLS + API)
- `selected_topic_ids` — their compass focus areas (3–8 topics)
- `gem_balance` / `xp` columns (see below)
- `location_consent`, `encrypted_lat`, `encrypted_lng` — location data (v1.3, encrypted at rest)

**Enrollment:** Invite-only for Alpha. Inviter's Tolerance Rating is adjusted when their invitee is sanctioned — one level of accountability, non-cascading. Invite chains are permanent records.

**What they can do:** Compass calibration with public/friends/private visibility, social graph (follows, connections), gem earning, XP earning, participation in Connect features (Symposiums, etc.).

### Empowered Tier

An Empowered user is a civic leader who has chosen to trade pseudonymity for influence. This is an explicit, non-reversible-in-character choice: **their legal name becomes publicly visible.**

**Key Empowered data:**
- `legal_name` — real name, public on all Empower surfaces and candidate pages
- Full politician schema (coming in Phase 21): `representing_city`, `district_type`, `district_label`, `chamber_name`, `office_title`, `is_vacant`, `is_candidate`
- All compass stances become public (custom stances included)

**Empowerment is atomic or nothing.** The `execute_empowerment` RPC creates `empowered_profiles`, batch-updates compass visibility to public, and generates a slug — all in a single Postgres transaction. Partial empowerment is never a valid state.

**Demotion** sets `is_active = false` on `empowered_profiles` and batch-reverts compass visibility to private. Downstream features (Symposiums, Bills) handle their own attribution policy for demoted users — accounts only sets the flag.

---

## Database Architecture

### Schema Layout

Supabase organizes tables into schemas. Each schema has its own RLS policies and represents a domain boundary:

| Schema | Purpose | Key Tables |
|--------|---------|-----------|
| `public` | Core user identity | `users`, `invite_codes`, `user_roles`, `role_definitions` |
| `connect` | Connected-tier data | `connected_profiles`, `social_relationships`, `gem_transactions`, `xp_ledger` |
| `empower` | Empowered-tier data | `empowered_profiles` |
| `inform` | Shared civic content | `compass_topics`, `compass_stances`, `compass_responses`, `compass_change_history`, `politicians`, `politician_answers`, `district_boundaries` |
| `extensions` | Postgres extensions | PostGIS, pgcrypto (Supabase puts these here) |
| `vault` | Supabase Vault | `decrypted_secrets` (encryption key storage) |

### Row-Level Security (RLS)

RLS is always enabled. It is the **primary** defense layer — API-layer authorization checks are a second layer. The architecture test suite enforces that no table is readable without RLS.

Key RLS patterns in use:

```sql
-- Users can only read their own connected_profile
CREATE POLICY "users_own_profile" ON connect.connected_profiles
  FOR SELECT USING (user_id = auth.uid());

-- tolerance_rating is never readable by other users
-- (achieved via column exclusion in SELECT policies + serialization layer)

-- district_boundaries is read-only for authenticated users (no INSERT/UPDATE/DELETE by users)
CREATE POLICY "district_boundaries_authenticated_read" ON inform.district_boundaries
  FOR SELECT TO authenticated USING (true);
```

### SECURITY DEFINER RPCs

Multi-step atomic operations use Postgres RPCs (functions called via `supabase.rpc()`). All RPCs follow this pattern:

```sql
CREATE OR REPLACE FUNCTION connect.upsert_user_location(p_user_id uuid, p_lat float8, p_lng float8)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER          -- runs as function owner, not caller (required for Vault access)
SET search_path = ''      -- prevents search_path injection; ALL refs must be schema-qualified
AS $$
BEGIN
  -- Two-pass validation: validate ALL inputs before ANY writes (all-or-nothing atomicity)
  -- Vault key fetch, encrypt, write — never returns raw coordinates
END;
$$;
```

Key RPCs:
- `execute_empowerment` — atomic empowerment (3 tables, full rollback)
- `award_xp` — idempotent XP award with transaction key
- `credit_gems` — atomic gem award with advisory lock + balance update
- `upsert_user_location` — encrypt lat/lng via pgcrypto, write to connected_profiles
- `resolve_user_jurisdiction` — decrypt coords, ST_Covers query against TIGER/Line boundaries, return jurisdiction JSON (no raw coordinates ever returned)

---

## Security Model

### Authentication

- **Supabase Auth** — JWT-based. ES256 (JWKS verification, not static secret). Compatible with Supabase's post-May 2025 key rotation.
- **Bearer token support** — `Authorization: Bearer <token>` header accepted on all authenticated routes (required for CompassV2 frontend which can't use cookies).
- **Service-role key** — used server-side only for admin operations. Banned from route files via architecture test.

### Dual Supabase Client

```typescript
// supabaseAdmin — service role, writes only, internal operations
// Used in: service layer, atomic transactions
const supabaseAdmin = createClient(url, SERVICE_ROLE_KEY);

// Per-request user client — scoped to authenticated user, RLS enforced
// Used in: all route handlers
const userClient = createServerClient(url, ANON_KEY, { cookies });
```

The architecture test suite asserts that `supabaseAdmin` never appears in `/routes/` files.

### Fields That Never Leave the Server

These fields are enforced at **two layers**: RLS (database prevents the read) and serialization (API layer strips them before responding).

| Field | Table | Reason |
|-------|-------|--------|
| `tolerance_rating` | `connect.connected_profiles` | Internal trust score — visibility to other users would enable gaming |
| `legal_name` | `empower.empowered_profiles` | Only surfaced on Empower/candidate contexts, never in Connect contexts |
| `encrypted_lat`, `encrypted_lng` | `connect.connected_profiles` | Raw coordinates never appear in any API response — only jurisdiction JSON is returned |
| Verification session data | `connect.verification_sessions` | Internal admin only |

### Location Privacy (v1.3)

Coordinates are encrypted at rest using pgcrypto (AES-256, symmetric key stored in Supabase Vault):

```
Address string → geocoding API → (lat, lng) float values
                                       ↓
                         pgp_sym_encrypt_bytea(lat::text::bytea, vault_key)
                                       ↓
                         bytea columns on connected_profiles
                         (address string discarded after geocoding)
```

`resolve_user_jurisdiction` decrypts the bytea internally, runs a PostGIS `ST_Covers` query against loaded Indiana TIGER/Line boundaries, and returns only the jurisdiction struct:

```json
{
  "congressional": "1809",
  "state_senate": "...",
  "state_house": "...",
  "county": "...",
  "school_district": "..."
}
```

Raw coordinates **never appear in any return value, API response, or server log** reachable by application code. The encryption key lives in Supabase Vault, not in environment variables or migration files.

### JWT Revocation

JWTs are short-lived Supabase tokens. The accounts system maintains a blocklist in Upstash Redis. Blocked tokens are rejected on next request regardless of expiry. Blocklist uses in-memory fallback — Redis being down degrades gracefully without crashing the API.

### Architecture Tests

90 architecture tests run in CI (`backend/tests/architecture/`). They assert:
- No `supabaseAdmin` in route files
- `tolerance_rating` and `legal_name` never appear in response objects
- No plaintext coordinate fields (`encrypted_lat`, `encrypted_lng`, float coordinates) in SELECT lists or API responses
- RLS enabled on all tables
- All new SECURITY DEFINER functions use `SET search_path = ''`

---

## API Surface

All routes are prefixed `/api/`. Auth uses Supabase JWT (Bearer token or session cookie).

### Public / Unauthenticated

| Method | Route | Description |
|--------|-------|-------------|
| `GET` | `/api/health` | Health check |
| `GET` | `/api/essentials/politicians` | All politicians (for Essentials feature) |
| `GET` | `/api/essentials/candidates` | All candidates |
| `POST` | `/api/auth/signup` | Create account (email, password, optional guest state) |
| `POST` | `/api/auth/login` | Login, return JWT |
| `GET` | `/api/compass/topics` | All live compass topics |
| `GET` | `/api/compass/categories` | Topics grouped by category |
| `GET` | `/api/account/profile/:userId` | Public profile (no sensitive fields) |

### Authenticated (any tier)

| Method | Route | Description |
|--------|-------|-------------|
| `GET` | `/api/auth/me` | Current user identity |
| `POST` | `/api/auth/logout` | Invalidate session + blocklist JWT |
| `GET` | `/api/account/me` | Full account state (tier, XP, gems, jurisdiction) |
| `PATCH` | `/api/account/me` | Update account fields |
| `GET` | `/api/compass/answers` | User's own compass answers |
| `POST` | `/api/compass/answers` | Upsert answer (topic_id, value, write_in_text) |
| `POST` | `/api/compass/answers/batch` | Get answers for multiple topic IDs |
| `GET` | `/api/compass/selected-topics` | User's saved topic focus list |
| `PUT` | `/api/compass/selected-topics` | Set topic focus list |
| `DELETE` | `/api/compass/answers/me` | Soft-reset all compass answers |
| `GET` | `/api/xp/:userId` | Public XP + level for any user |

### Connected Tier

| Method | Route | Description |
|--------|-------|-------------|
| `GET` | `/api/connect/profile` | Connected profile |
| `POST` | `/api/connect/set-location` | Geocode address → encrypt → store (coming Phase 20) |
| `GET` | `/api/account/me/jurisdiction` | Jurisdiction JSON (no raw coords) (coming Phase 20) |
| `GET` | `/api/social/*` | Follow, connect, block operations |

### Empowered Tier

| Method | Route | Description |
|--------|-------|-------------|
| `POST` | `/api/empower/request` | Initiate empowerment preflight |
| `POST` | `/api/empower/execute` | Atomic empowerment transaction |
| `POST` | `/api/empower/demote` | Demotion + visibility revert |

### Service Key Routes (feature repo → accounts)

Called by CTC, Validation Quests, and other feature repos with a scoped service key:

| Method | Route | Description |
|--------|-------|-------------|
| `POST` | `/api/xp/award` | Award XP (idempotent, transaction key required) |
| `POST` | `/api/gems/award` | Award gems by type (coming Phase 22) |

### Admin Routes (internal tool only)

| Prefix | Description |
|--------|-------------|
| `GET /api/admin/me` | Admin identity (id + email) |
| `GET /api/admin/accounts` | Account list with tier status |
| `POST /api/admin/invites` | Issue invite codes |
| `GET/PATCH /api/admin/compass/*` | Topic/stance/politician management |
| `GET /api/admin/xp/:userId` | Full XP ledger for a user |

---

## XP and Gem Ledgers

Both follow the same pattern: **append-only ledger + denormalized balance on connected_profiles**.

### XP

```
connect.xp_ledger
├── user_id         FK to public.users
├── source          ENUM: 'ctc_game', 'ctc_perfect_bonus', 'validation_quest', ...
├── amount          INTEGER
├── transaction_key UUID (UNIQUE — prevents double-award)
└── created_at      TIMESTAMPTZ

connect.connected_profiles.total_xp   ← denormalized sum, updated atomically by award_xp RPC
```

`calculate_level(total_xp)` is a pure SQL function (IMMUTABLE) with tiered thresholds: 2k×3 levels, 3k×6, 4k×20, 5k×all thereafter. Returns `{ level, xp_in_level, xp_to_next_level }`.

`GET /api/account/me` returns: `xp: { total, level, xp_in_level, xp_to_next_level }`.

### Gems

Currently single-currency (yellow). Phase 22 expands to yellow/blue/red with per-key source authorization.

```
connect.gem_transactions
├── user_id         FK
├── amount          INTEGER (positive = credit, negative = spend)
├── source          TEXT
└── created_at      TIMESTAMPTZ

connect.connected_profiles.gem_balance   ← denormalized sum
```

Advisory lock pattern prevents race conditions on balance updates.

---

## Compass Architecture

The Compass is the platform's political alignment tool — users calibrate their positions on policy topics, and those positions power comparisons with politicians and peers.

### Data Model

```
inform.compass_topics           id, title, short_title, question_text, is_live, is_active (generated)
inform.compass_stances          id, topic_id, value (1–5), text
inform.compass_responses        user_id, topic_id, value (NUMERIC 0.5–5.5), write_in_text,
                                visibility, inverted, deleted_at (soft-delete)
inform.compass_change_history   user_id, topic_id, old_value, new_value, created_at
inform.compass_topic_categories topic_id, category_id (m2m)
inform.politicians              id, full_name, office_title, photo_origin_url, is_candidate
inform.politician_answers       politician_id, topic_id, value
```

### Key Patterns

- **Value range:** `NUMERIC(3,1)`, 0.5 to 5.5. Integer stances (1–5) coexist with write-in half-integer positions.
- **Soft delete:** `deleted_at` column, not hard delete. All reads use `.is('deleted_at', null)` — `.eq(null)` does NOT generate IS NULL in PostgREST.
- **Inversion:** `inverted` boolean stored per-response. Never ignore it when rendering.
- **Visibility:** `'private' | 'friends' | 'public'`. Connected users control per-topic visibility. Empowered users' answers are forced public.
- **Anonymous compass import:** Guest calibrations saved to localStorage → migrated to DB on Connect enrollment via `migrate_guest_compass_state` RPC (ON CONFLICT DO NOTHING — never overwrites post-signup answers).

---

## Invite System and Accountability

Alpha enrollment is invite-only. The invite chain is a permanent record:

```
public.invite_codes
├── code            TEXT UNIQUE
├── created_by      FK to public.users (the inviter)
├── claimed_by      FK to public.users (set when claimed)
├── claimed_at      TIMESTAMPTZ
└── is_active       BOOLEAN

public.users
└── invited_by      FK to public.users (back-reference to inviter)
```

**Tolerance Rating accountability:** When an invitee is sanctioned, the `adjust_inviter_tolerance_rating` RPC decrements the inviter's tolerance_rating by 1. This is one level only — it does not cascade up the chain. The purpose is skin-in-the-game: inviters who vet carefully face less risk.

---

## What's Built (v1.3 Status)

| Phase | What | Status |
|-------|------|--------|
| 1–8 | Full schema, auth, enrollment, compass, empowerment, social graph, admin, candidates | ✓ Complete (v1.0) |
| 9–11 | XP ledger, leveling, admin XP view | ✓ Complete (v1.1) |
| 12–16 | Alpha hardening, CompassV2 compatibility, compass admin backend + React UI | ✓ Complete (v1.2) |
| 17 | Live Alpha deployment runbook + smoke test suite | ✓ Complete |
| 18 | CompassV2 API contract (bearer tokens, /me shape, signup email, response shapes) | ✓ Complete |
| 19 | Location schema + RPCs (encrypted coords + PostGIS jurisdiction) | ◆ In progress |
| 20 | Location endpoints (`/set-location`, `/jurisdiction`) | ○ Pending |
| 21 | empowered_profiles politician schema (VQ-ready field set) | ○ Pending |
| 22 | Multi-currency gems (yellow/blue/red, `/api/gems/award`) | ○ Pending |
| 23 | Central profile page (aggregated `/api/account/profile/:userId`) | ○ Pending |

---

## Tech Stack Reference

| Layer | Technology | Notes |
|-------|-----------|-------|
| Backend | Express 4.x / TypeScript strict | Render. All routes `/api/` prefixed |
| Database | Supabase (Postgres 17) | Migrations only via `backend/migrations/*.sql` — never manual schema changes |
| Auth | Supabase Auth | JWKS-verified JWTs, Bearer + cookie support |
| Cache | Upstash Redis (`@upstash/redis` HTTP) | In-memory fallback — never crashes API |
| Admin UI | Vite + React + Tailwind v4 | Internal only, `/admin` directory |
| Atomic transactions | `pg` (raw Postgres driver) | Supabase JS client cannot BEGIN/COMMIT |
| Location | pgcrypto (extensions schema) + PostGIS | Vault key, bytea encrypted coords, ST_Covers |
| Spatial data | Indiana TIGER/Line 2024 | ogr2ogr load, inform.district_boundaries, GIST index |

---

## Key Design Rules (For Code Reviewers)

1. **Tier = child record, never a flag.** If you see tier logic based on a boolean column, it's wrong.
2. **`tolerance_rating` and `legal_name` never in API responses to other users.** Enforced at RLS and serialization. Architecture test covers this.
3. **Raw coordinates never returned.** `encrypted_lat`/`encrypted_lng` bytea columns are never selected in route handlers. Only `resolve_user_jurisdiction` touches them, inside a SECURITY DEFINER RPC, and returns only the jurisdiction struct.
4. **`supabaseAdmin` never in route files.** Service role reads that feed API responses are a privilege escalation bug. Architecture test enforces this.
5. **All SECURITY DEFINER functions use `SET search_path = ''`.** ALL references inside such functions must be fully schema-qualified (including `extensions.pgp_sym_encrypt_bytea`, `extensions.ST_Covers`, etc.).
6. **All reads on compass_responses use `.is('deleted_at', null)`.** Not `.eq('deleted_at', null)` — PostgREST generates the wrong SQL.
7. **Migrations are idempotent.** Use `IF NOT EXISTS`, `CREATE OR REPLACE`, `ADD COLUMN IF NOT EXISTS`. Safe to re-run.
8. **PostgreSQL RPCs for multi-table writes.** Never chain JS `await` calls for operations that need atomicity.
9. **`pg_sym_encrypt_bytea` not `pgp_sym_encrypt`.** We store bytea (binary). The `_bytea` variant returns bytea; the plain variant returns text.
10. **`ST_MakePoint(lng, lat)` not `(lat, lng)`.** PostGIS X/Y convention: longitude is X, latitude is Y.

---

## Reading the Codebase

```
backend/
├── migrations/         SQL files — 001 through 032 (current)
├── scripts/            applyMigrations.ts, smokeTest.ts
└── src/
    ├── routes/         One file per domain (auth.ts, account.ts, compass.ts, ...)
    ├── services/       Business logic called by routes (accountService.ts, etc.)
    ├── lib/            Supabase clients, Redis, JWT verification, service key auth
    ├── middleware/      requireAuth, optionalAuth, requireAdmin, requireServiceKey
    └── types/          database.types.ts (Supabase-generated), shared interfaces

admin/
└── src/
    ├── pages/          Topics, Politicians, Categories, Accounts, XP views
    ├── components/     Shared UI
    └── lib/            Admin Supabase client, auth store

docs/
├── COMPASS_CONTRACT.md     External API contract for CompassV2 frontend
├── RUNBOOK-TIGER-LOAD.md   TIGER/Line data load operator guide
└── ACCOUNTS-ONBOARDING.md  This document

.planning/
├── PROJECT.md          Architecture decisions log
├── ROADMAP.md          All phases with goals and success criteria
└── STATE.md            Current position and accumulated session decisions
```

The most important files for understanding the system:
- `empowered-vote-primer.md` — platform philosophy and design principles
- `empowered-accounts-design.md` — full data model SQL and API shape
- `.planning/PROJECT.md` — every key decision made and why
- `backend/src/middleware/` — auth and permission boundaries
- `backend/migrations/` — ground truth of the schema

---

*Empowered Accounts — Empowered Vote | Bloomington, Indiana*
*Contact: Chris Andrews (UX Research Lead)*
