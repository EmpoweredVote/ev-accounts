# Empowered Accounts — Integration Guide v2

**Version:** v2.0 (2026-03-29)
**Audience:** Partner teams integrating with the Empowered Vote platform (CompassV2, Essentials, Treasury Tracker, Read & Rank, Fallacy Finders, Validation Quests, Civic Trivia Championship, and future features).
**Purpose:** Complete reference for building against the ev-accounts API in its current state. This document supersedes the v1 guide (`empowered-accounts-integration-guide.md`).

---

## Contents

1. [Overview — What Changed](#1-overview--what-changed)
2. [Production URLs](#2-production-urls)
3. [Authentication](#3-authentication)
4. [Tier System](#4-tier-system)
5. [Schema Inventory](#5-schema-inventory)
6. [Unified Politician IDs](#6-unified-politician-ids)
7. [Compass Value Range](#7-compass-value-range)
8. [Endpoint Inventory](#8-endpoint-inventory)
9. [Anti-Patterns](#9-anti-patterns)
10. [Migration Checklist](#10-migration-checklist)

---

## 1. Overview — What Changed

`empowered-accounts` is the foundational identity, trust, and data layer for the Empowered Vote civic platform. Every feature on the platform integrates here rather than building parallel auth or user tables.

**What this document replaces:**
The v1 guide (`empowered-accounts-integration-guide.md`) was written when a Go server ran alongside ev-accounts. The Go server has been decommissioned. **All API calls go to the ev-accounts API exclusively.**

**Key changes from v1:**

| Area | v1 (old) | v2 (current) |
|------|----------|--------------|
| JWT signing | HS256 symmetric (`SUPABASE_JWT_SECRET`) | ES256 asymmetric (JWKS endpoint) |
| Auth flow | Direct login returning token | SSO via `accounts.empowered.vote`, token in hash fragment |
| Go server | `ev-backend-h3n8.onrender.com` active | Permanently down — do NOT use |
| Politician IDs | Mix of `inform.politicians` integers and `essentials.politicians` UUIDs | All UUIDs from `essentials.politicians` only |
| Compass values | Integers, 1–5 range assumed | Float, 0.5–5.5 half-step scale |
| Session cookie | Not present in v1 | `ev_session` httpOnly cookie enables SSO across all apps |
| essentials schema | Not PostgREST-accessible (use pool.query) | Unchanged — still not PostgREST-accessible |

**Core invariant (unchanged):** A user's tier is determined by the *presence or absence of child records* — never by a status flag.

---

## 2. Production URLs

| Service | URL |
|---------|-----|
| **API (primary)** | `https://api.empowered.vote` |
| **API (alias)** | `https://accounts-api.empowered.vote` |
| **Accounts app (admin + login)** | `https://accounts.empowered.vote` |
| **Profile app** | `https://profile.empowered.vote` |
| **Auth Hub (SSO login redirect)** | `https://accounts.empowered.vote/login?redirect={encodeURIComponent(returnUrl)}` |

> **Anti-pattern: Do NOT use `ev-backend-h3n8.onrender.com` or any variant of the old Go server URL.** The Go server is permanently down. All traffic must go to `api.empowered.vote`.

All API routes in this document use the prefix `/api`. Example: `GET https://api.empowered.vote/api/health`.

**CORS:** The API allows requests from the following origins: `accounts.empowered.vote`, `profile.empowered.vote`, `essentials.empowered.vote`, `compass.empowered.vote`, `treasurytracker.empowered.vote`, `badges.empowered.vote`, `readrank.empowered.vote`, `fallacyfinders.empowered.vote`, and `localhost` in development. New origins must be added to `CORS_ORIGIN` on the Render deployment.

**Exposed response headers** (must be handled by client):
- `X-Data-Updated-At` — timestamp of underlying data in campaign finance responses
- `X-Data-Status` — `fresh` or `no-geofence-data` for essentials/candidates responses
- `X-Formatted-Address` — geocoded address returned by candidates/search

---

## 3. Authentication

### 3.1 JWT Signing Algorithm

JWTs are signed with **ES256 (asymmetric P-256)**. The symmetric `SUPABASE_JWT_SECRET` is no longer used and is not set on any Render deployment. Do not re-add it.

**JWKS endpoint:**
```
https://kxsdzaojfaibhuzmclfq.supabase.co/auth/v1/.well-known/jwks.json
```

### 3.2 Verifying JWTs in a Partner Backend

Use `jose` (not `jsonwebtoken`) for JWKS-based verification. The ev-accounts middleware itself uses this pattern:

```typescript
import { jwtVerify, createRemoteJWKSet } from 'jose';

const JWKS = createRemoteJWKSet(
  new URL('https://kxsdzaojfaibhuzmclfq.supabase.co/auth/v1/.well-known/jwks.json')
);

export async function requireAuth(req, res, next) {
  const token = req.headers.authorization?.slice(7); // strip "Bearer "
  if (!token) return res.status(401).json({ error: 'Missing authorization header' });

  try {
    const { payload } = await jwtVerify(token, JWKS, {
      issuer: 'https://kxsdzaojfaibhuzmclfq.supabase.co/auth/v1',
      audience: 'authenticated',
    });
    req.userId = payload.sub;
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}
```

**Environment variables a partner backend needs:**
```
SUPABASE_URL=https://kxsdzaojfaibhuzmclfq.supabase.co
SUPABASE_ANON_KEY=<shared anon key>
SUPABASE_SERVICE_ROLE_KEY=<shared service role key>
# Do NOT set SUPABASE_JWT_SECRET — ES256 uses JWKS, not a symmetric secret
```

### 3.3 SSO Redirect Flow (for user-facing apps)

All user-facing partner apps authenticate via the Accounts app. Users never log in at a partner app's own URL.

**Flow:**
1. User visits a partner app and is not authenticated.
2. Partner app redirects to: `https://accounts.empowered.vote/login?redirect={encodeURIComponent(returnUrl)}`
3. User logs in at `accounts.empowered.vote`.
4. On success, Accounts redirects back to `returnUrl` with `#access_token=eyJ...&refresh_token=...` in the URL hash.
5. Partner app reads `location.hash`, extracts `access_token`, stores it (e.g., `localStorage.setItem('ev_token', token)`).
6. All authenticated API calls include `Authorization: Bearer <access_token>`.

**Silent session renewal (SSO cookie):**

The `ev_session` httpOnly cookie is set on login at `accounts.empowered.vote`. It contains the Supabase refresh token. Partner apps can call `GET /api/auth/session` (no Bearer token needed) to silently exchange the cookie for a fresh token pair without requiring the user to re-authenticate.

```javascript
// On app load — check for silent session before showing login
const res = await fetch('https://api.empowered.vote/api/auth/session', {
  credentials: 'include', // required for cookie to be sent cross-origin
});
if (res.ok) {
  const { access_token } = await res.json();
  localStorage.setItem('ev_token', access_token);
}
// 401 = no valid session — redirect to login
```

### 3.4 Service-to-Service Auth

Some endpoints use service keys instead of user JWTs. There are two service key types:

| Header | Used by | Endpoints |
|--------|---------|-----------|
| `X-Service-Key: <key>` | XP award, trivia leaderboard | `POST /api/xp/award`, `GET /api/trivia/leaderboard-profiles` |
| `Authorization: Bearer <gem-service-key>` | Gems award, VQ confirm | `POST /api/gems/award`, `POST /api/vq/confirm-stance`, `POST /api/vq/adjust-vr` |

Service keys are provisioned per feature with per-key restrictions on which sources or gem types can be awarded. Contact the project owner for credentials.

---

## 4. Tier System

### 4.1 The Three Tiers

**Tier = child record presence, never a status flag.**

| Tier | Condition | Notes |
|------|-----------|-------|
| **Inform** | No `connected_profiles` row | Base tier. Anyone who signs up. |
| **Connected** | `connect.connected_profiles` row exists with `verification_status = 'verified'` | Requires an invite code for alpha. |
| **Empowered** | `empower.empowered_profiles` row exists with `is_active = true` | Demoted users have `is_active = false` and fall through to Connected. |

`GET /api/account/me` returns `tier: 'inform' | 'connected' | 'empowered'` and `empowerment_status: 'empowered' | 'demoted'` (only when an empowered_profiles row exists).

### 4.2 Middleware Guards

| Middleware | Meaning | HTTP error if fails |
|-----------|---------|---------------------|
| `requireAuth` | Valid, unexpired, non-revoked JWT | 401 |
| `requireConnected` | User has a Connected (or Empowered) profile | 403 |
| `requireAdmin` | User is in `public.admin_users` | 403 |
| `requireGemServiceKey` | Bearer token matches `GEMS_SERVICE_KEYS` map | 401 |
| `requireServiceKey` | `X-Service-Key` header matches `SERVICE_KEYS` map | 401 |
| `requireStagingReviewer` | User has `staging_reviewer` role or is admin | 403 |
| `optionalAuth` | JWT validated if present; `userId` is null if absent | Never blocks |

### 4.3 Suspended Accounts

`requireAuth` checks `account_standing` on `connected_profiles` for every request. Suspended accounts receive 403 even with a valid JWT. Inform-tier users (no connected_profiles row) are always allowed through.

---

## 5. Schema Inventory

| Schema | Purpose | API-Accessible via PostgREST? |
|--------|---------|-------------------------------|
| `public` | `users`, `admin_users`, `access_requests` | Yes (default schema) |
| `connect` | `connected_profiles`, `invite_codes`, `verification_sessions`, `peer_connections`, `follows` | Yes (via `supabase.schema('connect')`) |
| `empower` | `empowered_profiles` | Yes (via `supabase.schema('empower')`) |
| `inform` | `compass_topics`, `compass_stances`, `compass_responses`, `compass_categories`, `compass_topic_categories`, `politician_answers`, `politician_context` | Yes (via `supabase.schema('inform')`) |
| `essentials` | `politicians`, `offices`, `governments`, `chambers`, `districts`, `quotes`, `building_photos` and more | **NOT PostgREST-exposed** — use `pool.query()` only |
| `validation_quests` | VQ quest state, idempotency keys | Yes (via `supabase.schema('validation_quests')`) |
| `transparent_motivations` | Campaign finance data | **NOT PostgREST-exposed** — use `pool.query()` only |
| `treasury` | City budget data: `municipalities`, `budgets`, `budget_categories` | **NOT PostgREST-exposed** — use `pool.query()` only |

> **Anti-pattern: Do NOT call `supabaseAdmin.schema('essentials').from(...)` via PostgREST.** The `essentials` schema is not in the PostgREST exposed schema list. `supabaseAnon.schema('essentials')` will fail at runtime. All essentials reads and writes must use `pool.query()` (direct postgres driver). Same applies to `transparent_motivations` and `treasury`.

> **Anti-pattern: Do NOT use `supabaseAdmin.schema('connect'|'empower'|...).update()|insert()|upsert()` for non-public schema writes via PostgREST.** These fail silently or with cryptic errors. Use `pool.query()` or SECURITY DEFINER RPCs for all non-public schema writes.

---

## 6. Unified Politician IDs

**All politician references across the platform use `essentials.politicians` UUIDs.**

| System | Old ID type | Current ID type |
|--------|-------------|-----------------|
| Compass answers | `inform.politicians` integer | `essentials.politicians` UUID |
| Essentials politician list | `essentials.politicians` UUID | `essentials.politicians` UUID (unchanged) |
| Campaign finance | `transparent_motivations.politicians` integer (internal) | `essentials.politicians` UUID (in API responses) |
| VQ confirm-stance | `inform.politicians` integer (old) | `essentials.politicians` UUID |

The bridge table `essentials.politician_inform_bridge` maps old `inform.politicians` integer IDs to `essentials.politicians` UUIDs for any legacy migration needs. It is not used in new code.

> **Anti-pattern: Do NOT use `inform.politicians` integer IDs in any new code.** Any endpoint that accepts or returns a `politician_id` uses the `essentials.politicians` UUID. Passing an integer will fail UUID validation (422 VALIDATION_ERROR) or return no results.

---

## 7. Compass Value Range

**Compass values are floating-point numbers from 0.5 to 5.5 in 0.5 increments.**

```
Valid values: 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5
```

This is a half-step scale. The midpoint (neutral) is 3.0.

> **Anti-pattern: Do NOT assume compass values are integers or that the range is 0–5 or 1–5.** The Zod schema enforces `z.number().multipleOf(0.5).min(0.5).max(5.5)`. Values outside this range or non-half-step values will be rejected with 422.

Politician answers returned by `GET /api/compass/politicians/:id/answers` and the politician answer admin endpoints also use the 0.5–5.5 range.

---

## 8. Endpoint Inventory

Base URL for all endpoints: `https://api.empowered.vote`

Auth column legend:
- **None** — no authentication, works unauthenticated
- **Optional** — works with or without token; behavior differs (e.g., returns empty array when unauth)
- **Auth** — requires valid JWT (`requireAuth`)
- **Connected** — requires Auth + Connected or Empowered tier (`requireConnected`)
- **Admin** — requires Auth + admin flag (`requireAdmin`)
- **ServiceKey** — requires `X-Service-Key` header
- **GemKey** — requires `Authorization: Bearer <gem-service-key>`
- **StagingReviewer** — requires Auth + staging_reviewer role or admin

---

### 8.1 Health

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/health` | None | Returns `{ status: "ok", timestamp: <epoch_ms> }` |

---

### 8.2 Auth (`/api/auth`)

| Method | Path | Auth | Request Body | Description |
|--------|------|------|------|-------------|
| `POST` | `/api/auth/signup` | None | `{ email, password, legal_name?, invite_code?, guest_state? }` | Create account. Rate-limited 10/15min/IP. With `invite_code` + `legal_name`: atomically creates Connected profile. Returns 201 with `{ id, message }`. |
| `POST` | `/api/auth/login` | None | `{ email, password }` | Authenticate. Sets `ev_session` cookie. Returns `{ access_token, refresh_token, expires_in, expires_at, token_type, user: { id, email, tier, account_standing } }`. |
| `GET` | `/api/auth/session` | None (cookie) | — | SSO silent session renewal. Reads `ev_session` cookie. Returns `{ access_token, refresh_token }`. 401 if cookie missing or invalid. |
| `POST` | `/api/auth/logout` | Auth | — | Invalidates session globally. Clears `ev_session` cookie. Always 200. |
| `POST` | `/api/auth/complete-onboarding` | Auth | — | Sets `completed_onboarding = true` on `connected_profiles`. 403 NOT_CONNECTED if no Connected profile. |
| `POST` | `/api/auth/request-access` | None | `{ email }` | Capture email from users without an invite code. Rate-limited. Returns 201. |

**signup `guest_state` shape:**
```json
{
  "answers": [{ "topic_id": "uuid", "value": 3.0, "write_in_text": "optional" }],
  "selected_topics": ["uuid", "uuid"]
}
```
Guest compass answers are migrated into the new account on signup (non-fatal — migration failure does not block account creation).

---

### 8.3 Account (`/api/account`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/account/me` | Auth | Full user profile. See shape below. |
| `PATCH` | `/api/account/me` | Connected | Update `display_name` and/or `avatar_url`. Returns updated profile (same shape as GET). |
| `GET` | `/api/account/me/jurisdiction` | Connected | User's stored jurisdiction as 12 geo fields. 403 LOCATION_CONSENT_REQUIRED if location not set. |

**GET /api/account/me response shape:**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "display_name": "string or null",
  "avatar_url": "url or null",
  "tier": "inform | connected | empowered",
  "is_admin": false,
  "completed_onboarding": false,
  "location_consent": false,
  "verification_rating": 60,
  "vq_hold_active": false,
  "red_gem_quests_unlocked": false,
  "empowerment_status": "empowered | demoted",
  "account_standing": "active | suspended",
  "jurisdiction": {
    "congressional_district": "geo_id or null",
    "congressional_district_name": "string or null",
    "state_senate_district": "geo_id or null",
    "state_senate_district_name": "string or null",
    "state_house_district": "geo_id or null",
    "state_house_district_name": "string or null",
    "county": "geo_id or null",
    "county_name": "string or null",
    "school_district": "geo_id or null",
    "school_district_name": "string or null",
    "state": "CA",
    "city": "Los Angeles"
  },
  "created_at": "iso8601",
  "updated_at": "iso8601",
  "connected_profile": {
    "display_name": "string or null",
    "verification_status": "verified | pending | suspended",
    "tolerance_rating": 75,
    "xp": { "total": 0, "level": 1, "xp_in_level": 0, "xp_to_next_level": 100 },
    "gems": { "yellow": 0, "blue": 0, "red": 0 },
    "completed_onboarding": false,
    "verification_rating": 60,
    "vq_hold_active": false,
    "vq_hold_until": "iso8601 or null",
    "created_at": "iso8601"
  },
  "gems": { "yellow": 0, "blue": 0, "red": 0 },
  "empowered_profile": {
    "legal_name": "string",
    "is_active": true,
    "candidate_page_slug": "jane-smith-a1b2",
    "empowered_at": "iso8601",
    "demoted_at": "iso8601 or null"
  }
}
```

Notes:
- `empowerment_status` only present when an `empowered_profiles` row exists.
- `connected_profile` only present for Connected/Empowered users (includes `tolerance_rating`).
- `empowered_profile` only present for users with an `empowered_profiles` row.
- `tolerance_rating` and `legal_name` are NEVER at root level — structural privacy enforcement.
- `jurisdiction` is null for Inform users or users who haven't set location.

---

### 8.4 Profile (`/api/account/profile`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/account/profile/me` | Auth | Owner profile with gems, email, location_consent. |
| `GET` | `/api/account/profile/:userId` | None | Public profile for any user (no sensitive fields). |

---

### 8.5 Connect Flow (`/api/connect`)

The Connect flow is the enrollment pipeline from Inform to Connected tier. State machine: `invite → profile → review → complete`.

| Method | Path | Auth | Request Body | Description |
|--------|------|------|------|-------------|
| `POST` | `/api/connect/start` | Auth | `{ code: "XXXX-XXXX" }` | Claim invite code, create or resume verification_session. 409 ALREADY_CONNECTED if already Connected. |
| `PATCH` | `/api/connect/step` | Auth | `{ step: "profile\|review", display_name?, legal_name?, location?, home_address? }` | Update draft profile fields, advance step. |
| `POST` | `/api/connect/complete` | Auth | — | Atomically finalize Connect flow and create connected_profiles. 404 NO_SESSION, 400 INCOMPLETE_SESSION, 409 ALREADY_CONNECTED. |
| `GET` | `/api/connect/status` | Auth | — | Returns `{ status: 'not_started' \| 'in_progress' \| 'verified' \| 'pending' \| 'suspended', step_reached? }` |
| `POST` | `/api/connect/compass-import` | Auth | `{ calibrations, selected_topics?, confirmed, user_id? }` | Two-phase compass import. `confirmed: false` = validate versions; `confirmed: true` = write. Admin path when `user_id` provided. |
| `POST` | `/api/connect/set-location` | Connected | `{ address: "123 Main St, City, ST" }` | Geocode address, upsert location, resolve and store jurisdiction GEO IDs. 422 PO_BOX_REJECTED, ADDRESS_NOT_FOUND. 503 GEOCODER_UNAVAILABLE. |

---

### 8.6 Compass (`/api/compass`)

| Method | Path | Auth | Request Body / Query | Description |
|--------|------|------|------|-------------|
| `GET` | `/api/compass/topics` | Optional | — | All live topics with nested stances, categories, role scopes. |
| `GET` | `/api/compass/categories` | Optional | — | All categories with nested live topics. |
| `GET` | `/api/compass/answers` | Optional | — | User's own answers. `[]` if unauthenticated. |
| `POST` | `/api/compass/answers` | Optional | `{ topic_id, value, write_in_text?, inverted? }` | Upsert single answer. `null` if unauthenticated (not persisted). |
| `POST` | `/api/compass/answers/batch` | Optional | `{ ids: ["uuid", ...] }` | Fetch answers for list of topic IDs. `[]` if unauthenticated. |
| `DELETE` | `/api/compass/answers/me` | Auth | `?full=true` (admin only) | Soft-delete all user's answers + clear selected topics. Returns `{ reset: true }`. |
| `GET` | `/api/compass/selected-topics` | Optional | — | User's saved topic IDs array. `[]` if unauthenticated. |
| `PUT` | `/api/compass/selected-topics` | Optional | `{ topic_ids: ["uuid", ...] }` | Save selected topics (validated against live topics). `[]` if unauthenticated. |
| `GET` | `/api/compass/progress` | Auth | `?role=city_council\|state_legislature\|us_congress\|president` | Compass completeness score. |
| `POST` | `/api/compass/compare` | Auth | `{ politician_ids: ["uuid", ...] }` | Alignment scores between user and politicians. |
| `GET` | `/api/compass/verdicts` | Auth | `?politician_id=uuid` | User's compass verdicts (Read & Rank judgments). |
| `POST` | `/api/compass/verdicts` | Auth | `{ verdicts: [{ quote_id, supported, rank, session_size }] }` OR legacy `[{ quote_id, verdict: "agreed\|disagreed" }]` | Upsert batch verdicts. |
| `GET` | `/api/compass/politicians` | Optional | — | All active politicians (essentials UUIDs). |
| `GET` | `/api/compass/politicians/:id/answers` | Optional | — | Politician's stances on all topics. `id` = essentials UUID. |
| `POST` | `/api/compass/politicians/:id/answers/batch` | Optional | `{ topic_ids: ["uuid", ...] }` | Politician's answers filtered to supplied topic IDs. |
| `GET` | `/api/compass/politicians/:id/:topicId/context` | Optional | — | Reasoning + sources for politician's stance on a topic. 404 if no context record. |

**Compass Admin endpoints (also at `/api/compass`, admin-only):**

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/api/compass/topics/create` | Admin | Create topic + stances + optional categories atomically. |
| `PATCH` | `/api/compass/topics/update` | Admin | Update topic metadata. Body includes `id` + changed fields. |
| `DELETE` | `/api/compass/topics/delete/:id` | Admin | Delete topic. 422 if users have existing responses (archive with `is_live=false` instead). |
| `PATCH` | `/api/compass/stances/update` | Admin | Update stance text. Body: `{ id, text }` (single) or `{ topic_id, updated, added, removed }` (batch). |
| `PATCH` | `/api/compass/topics/categories/update` | Admin | Assign topic categories. Body: `{ topic_id, category_ids }` (full replace) or `{ topic_id, add, remove }` (delta). |
| `PUT` | `/api/compass/politicians/:id/answers` | Admin | Set politician answers for a topic. Body: `{ answers: [{ topic_id, value }] }` or legacy flat array. |
| `POST` | `/api/compass/politicians/context` | Admin | Set politician context (reasoning + sources). Body: `{ politician_id, topic_id, reasoning, sources? }`. |

---

### 8.7 Empower Flow (`/api/empower`)

| Method | Path | Auth | Request Body | Description |
|--------|------|------|------|-------------|
| `POST` | `/api/empower/preflight` | Connected | — | Validate empowerment conditions. Returns `{ eligible: true\|false, failures?, summary? }`. On eligible: reserves slug for 1 hour. |
| `POST` | `/api/empower/confirm` | Connected | `{ consent: { legal_name_public: true, compass_stances_public: true, platform_terms: true } }` | Execute empowerment. All three consent items must be literal `true`. 409 PREFLIGHT_EXPIRED if slug expired. |
| `POST` | `/api/empower/demote` | Connected | `{ reason?: { lapsed_topic_ids?, lapsed_at?, triggered_by? } }` | Self-demotion from Empowered to Connected. |

---

### 8.8 Invites (`/api/invites`)

| Method | Path | Auth | Request Body | Description |
|--------|------|------|------|-------------|
| `POST` | `/api/invites/send` | Connected | — | Generate a new invite code. Max 5 unclaimed codes. Rate-limited 10/24hr. Returns `{ code: "XXXX-XXXX" }`. |
| `POST` | `/api/invites/claim` | Auth | `{ code: "XXXX-XXXX" }` | Claim an invite code (does NOT create Connected profile — use connect/start for that). Returns `{ claimed: true, inviter_id }`. |
| `GET` | `/api/invites/mine` | Connected | — | User's own invite codes (safe fields only, no UUIDs of others). |

---

### 8.9 XP (`/api/xp`)

| Method | Path | Auth | Request Body / Query | Description |
|--------|------|------|------|-------------|
| `POST` | `/api/xp/award` | ServiceKey | `{ user_id, source, amount, idempotency_key, metadata? }` | Award XP to a Connected user. Idempotent. Unlocks referral code at level 2. |
| `GET` | `/api/xp/leaderboard` | None | `?window=alltime\|week` | Top 25 CTC XP users. |
| `GET` | `/api/xp/leaderboard/me` | Connected | `?window=alltime\|week` | Caller's rank + XP gap to player above. 404 if unranked. |
| `GET` | `/api/xp/me/history` | Connected | `?limit=50&offset=0` | Paginated XP transaction history. |
| `GET` | `/api/xp/:userId` | None | — | Public XP profile for a user. |

---

### 8.10 Gems (`/api/gems`)

| Method | Path | Auth | Request Body / Query | Description |
|--------|------|------|------|-------------|
| `POST` | `/api/gems/award` | GemKey | `{ user_id, gem_type: "yellow\|blue\|red", amount, idempotency_key }` | Award gems. Idempotent. Per-key gem_type enforcement. Returns `{ gem_type, amount, new_balance, is_duplicate }`. |
| `GET` | `/api/gems/balance` | Connected | — | Current gem balances `{ yellow, blue, red }`. |
| `GET` | `/api/gems/transactions` | Connected | `?gem_type=&limit=50&offset=0` | Paginated gem transaction history. |

---

### 8.11 Validation Quests (`/api/vq`)

| Method | Path | Auth | Request Body | Description |
|--------|------|------|------|-------------|
| `POST` | `/api/vq/confirm-stance` | GemKey | `{ politician_id, topic_id, confirmed_value, correct_user_ids, incorrect_user_ids, idempotency_key, gems_amount? }` | Resolve a VQ question. Awards red gems + adjusts VRs + upserts politician stance atomically. |
| `POST` | `/api/vq/adjust-vr` | GemKey | `{ user_id, delta, idempotency_key, reason? }` | Adjust a user's Verification Rating. For Yellow quest grading. |

---

### 8.12 Social (`/api/social`)

| Method | Path | Auth | Request Body | Description |
|--------|------|------|------|-------------|
| `POST` | `/api/social/peers/request` | Connected | `{ target_id }` | Send peer connection request. |
| `PATCH` | `/api/social/peers/:id/accept` | Connected | — | Accept pending request (addressee only). |
| `PATCH` | `/api/social/peers/:id/decline` | Connected | — | Decline pending request. |
| `POST` | `/api/social/peers/block` | Connected | `{ target_id }` | Block a user. Removes existing relationships. |
| `GET` | `/api/social/peers` | Connected | — | User's peer connections (pending + accepted). |
| `POST` | `/api/social/follow` | Connected | `{ target_id }` | Follow an Empowered account. |
| `DELETE` | `/api/social/follow/:target_id` | Connected | — | Unfollow. Idempotent. |
| `GET` | `/api/social/following` | Connected | — | Accounts the user is following. |
| `GET` | `/api/social/followers/:userId` | None | — | Follower count for an Empowered user. |

---

### 8.13 Roles (`/api/roles`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/roles` | Auth | All active roles in the system. |
| `GET` | `/api/roles/me` | Connected | Caller's active (non-revoked) role grants. |

---

### 8.14 Referral (`/api/referral`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/referral` | Connected | Referral state: `{ unlocked, code, inviteeJoined, inviteeLevel }`. Unlocked at level 2. |

---

### 8.15 Candidates (`/api/candidates`)

Public Empowered candidate pages — slug-based.

| Method | Path | Auth | Query | Description |
|--------|------|------|-------|-------------|
| `GET` | `/api/candidates/:slug/answers` | None | `?topics=uuid1,uuid2&inverted=uuid1` | Candidate's public compass answers for specified topics. |
| `GET` | `/api/candidates/:slug` | None | — | Full public candidate profile (active and demoted). |

---

### 8.16 Essentials — Representatives (`/api/essentials`)

| Method | Path | Auth | Query / Body | Description |
|--------|------|------|------|-------------|
| `GET` | `/api/essentials/elections` | Optional | `?lat=&lng=` | Upcoming elections for a coordinate. |
| `GET` | `/api/essentials/address-search` | Optional | `?address=...` | Representatives for an address (Census geocoder + PostGIS). Includes `data_level`. |
| `GET` | `/api/essentials/quotes` | None | — | All quotes + candidates + issues for Read & Rank. |
| `GET` | `/api/essentials/cities/:geo_id/building-photo` | None | — | Building photo for a city by Census GEOID. |
| `GET` | `/api/essentials/governments/:id` | Optional | — | Government with nested chambers. |
| `GET` | `/api/essentials/chambers/:id` | Optional | — | Chamber with parent government. |
| `GET` | `/api/essentials/districts/:id` | Optional | — | District with active politicians, chamber, government. |
| `GET` | `/api/essentials/representatives/me` | Connected | — | Politicians for user's stored jurisdiction (no geocoding). 204 if no location on file. |

---

### 8.17 Essentials — Politicians (`/api/essentials/politicians`)

All IDs are `essentials.politicians` UUIDs. All endpoints are public (optionalAuth).

| Method | Path | Query | Description |
|--------|------|-------|-------------|
| `GET` | `/api/essentials/politicians` | `?include_candidates=true&q=&state=CA&limit=50&offset=0` | Flat politician list. Incumbents only unless `include_candidates=true`. |
| `GET` | `/api/essentials/politicians/:id` | — | Full politician profile with contacts, images, degrees, experiences. |
| `GET` | `/api/essentials/politicians/:id/legislative` | — | Legislative sessions. |
| `GET` | `/api/essentials/politicians/:id/legislative-summary` | — | `{ recent_bills: [...5], recent_votes: [...10] }` |
| `GET` | `/api/essentials/politicians/:id/committees` | — | Committee memberships. |
| `GET` | `/api/essentials/politicians/:id/bills` | `?limit=50&all=true` | Bills sponsored or cosponsored. |
| `GET` | `/api/essentials/politicians/:id/votes` | `?limit=50` | Voting record. |
| `GET` | `/api/essentials/politicians/:id/endorsements` | — | Endorsements with organization details. |
| `GET` | `/api/essentials/politicians/:id/elections` | — | Election history. |
| `GET` | `/api/essentials/politicians/:id/leadership` | — | Leadership positions. |
| `GET` | `/api/essentials/politicians/:id/stances` | — | Policy stances from BallotReady data. |
| `GET` | `/api/essentials/politicians/:id/judicial-record` | — | `{ judge_detail, evaluations, metrics, disciplinary_records }` |

---

### 8.18 Essentials — Candidates (`/api/essentials/candidates`)

| Method | Path | Auth | Body | Description |
|--------|------|------|------|-------------|
| `GET` | `/api/essentials/candidates/:zip` | None | — | Active candidates for a ZIP code (5-digit or ZIP+4). |
| `POST` | `/api/essentials/candidates/search` | None | `{ query: "full address", includeChallengers?: bool }` | Geocodes address, returns representatives. Sets `X-Data-Status` and `X-Formatted-Address` headers. |

---

### 8.19 Essentials — Browse (`/api/essentials/browse`)

Location-based browse without requiring geocoding.

| Method | Path | Auth | Body | Description |
|--------|------|------|------|-------------|
| `GET` | `/api/essentials/browse/states` | Optional | — | States that have politician data. |
| `GET` | `/api/essentials/browse/states/:state/areas` | Optional | — | Browsable areas (counties, cities) for a state. `:state` = 2-letter abbreviation. |
| `POST` | `/api/essentials/browse/by-area` | Optional | `{ geo_id, mtfcc }` | Politicians whose districts overlap a given area. |

---

### 8.20 Treasury (`/api/treasury`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/treasury/cities` | None | All cities with `available_datasets: [{ fiscal_year, dataset_type }]`. |
| `GET` | `/api/treasury/cities/:id` | None | City by UUID. |
| `GET` | `/api/treasury/cities/:cityId/budgets` | None | Budgets for a city. `?fiscal_year=2024` |
| `GET` | `/api/treasury/budgets/:id` | None | Budget by UUID. |
| `GET` | `/api/treasury/budgets/:id/categories` | None | Categories for a budget. |
| `GET` | `/api/treasury/budgets/:id/line-items` | None | Line items for a budget. |
| `GET` | `/api/treasury/budgets/:id/transactions` | None | `?link_key=fire&limit=20` — linked transactions by category prefix. |
| `GET` | `/api/treasury/search` | None | `?q=roads&city_id=uuid&year=2025&limit=20` — natural language search. |
| `GET` | `/api/treasury/enrichment-queue/status` | Admin | Enrichment queue status + next scheduled run. |
| `POST` | `/api/treasury/cities` | Admin | Create city. Body: `{ name, state, population? }` |
| `POST` | `/api/treasury/budgets` | Admin | Create budget. |
| `POST` | `/api/treasury/budgets/categories` | Admin | Create budget category. |
| `POST` | `/api/treasury/budgets/line-items` | Admin | Create budget line item. |

Response fields are snake_case (`fiscal_year`, `why_matters`, `city_id`, etc.).

---

### 8.21 Campaign Finance (`/api/campaign-finance`)

All public endpoints — no auth required.

| Method | Path | Query | Description |
|--------|------|-------|-------------|
| `GET` | `/api/campaign-finance/health` | — | Service health check. |
| `GET` | `/api/campaign-finance/search` | `?q=&limit=10&offset=0` | Politician name search (min 2 chars). |
| `GET` | `/api/campaign-finance/politician/:id/summary` | `?cycle=2024&confidence=high\|medium\|estimated` | Campaign finance summary. `:id` = essentials UUID. Sets `X-Data-Updated-At` header. |
| `GET` | `/api/campaign-finance/politician/:id/contributions` | `?cursor=&limit=50&cycle=2024&confidence=` | Paginated contributions. Cursor-based pagination. |

> `politician_source_id` is never exposed in any campaign finance response.

---

### 8.22 Meetings (`/api/meetings`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/meetings` | None | `?city=&state=&status=completed` — meeting list with filters. |
| `GET` | `/api/meetings/:id` | None | Meeting by UUID. |
| `GET` | `/api/meetings/:id/transcript` | None | `?page=1` — paginated meeting transcript. |
| `GET` | `/api/meetings/:id/summary` | None | AI meeting summary. 404 if none. |
| `GET` | `/api/meetings/:id/votes` | None | Vote records for a meeting. |
| `POST` | `/api/meetings` | Admin | Create meeting. |
| `PATCH` | `/api/meetings/:id` | Admin | Update meeting. |
| `DELETE` | `/api/meetings/:id` | Admin | Delete meeting. |

---

### 8.23 Staging (`/api/staging`)

Internal data review workflow. Requires `staging_reviewer` role or admin.

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/staging/politicians` | StagingReviewer | `?status=` — list staging politicians. |
| `GET` | `/api/staging/politicians/:id` | StagingReviewer | Single staging politician. |
| `POST` | `/api/staging/politicians` | StagingReviewer | Create staging politician. |
| `PUT` | `/api/staging/politicians/:id` | StagingReviewer | Update staging politician. |
| `POST` | `/api/staging/politicians/:id/review` | StagingReviewer | `{ action: "approve\|reject", comment? }` — approve or reject. |
| `POST` | `/api/staging/politicians/:id/lock` | StagingReviewer | Acquire edit lock. 409 if already locked. |
| `DELETE` | `/api/staging/politicians/:id/lock` | StagingReviewer | Release lock. |
| `POST` | `/api/staging/politicians/:id/merge` | StagingReviewer | `{ targetId }` — merge staging record into production. |
| `GET` | `/api/staging/stances` | StagingReviewer | List staging stances. |
| `GET` | `/api/staging/stances/:id` | StagingReviewer | Single staging stance. |
| `POST` | `/api/staging/stances` | StagingReviewer | Create staging stance. |
| `PUT` | `/api/staging/stances/:id` | StagingReviewer | Update staging stance. |
| `POST` | `/api/staging/stances/:id/review` | StagingReviewer | Approve or reject. |
| `POST` | `/api/staging/stances/:id/lock` | StagingReviewer | Acquire lock. |
| `DELETE` | `/api/staging/stances/:id/lock` | StagingReviewer | Release lock. |
| `GET` | `/api/staging/photos` | StagingReviewer | List staging photos. |
| `GET` | `/api/staging/photos/:id` | StagingReviewer | Single staging photo. |
| `POST` | `/api/staging/photos` | StagingReviewer | Create staging photo. |
| `POST` | `/api/staging/photos/:id/review` | StagingReviewer | Approve or reject. |

---

### 8.24 Trivia (`/api/trivia`)

Service-to-service endpoint for Civic Trivia Championship leaderboard.

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/trivia/leaderboard-profiles` | ServiceKey | `?user_ids=uuid1,uuid2,...` (max 100) — returns `display_name`, `total_xp`, `level` per user. |

---

### 8.25 Admin (`/api/admin`)

All admin routes require Auth + admin flag. Every mutation logs to `admin_audit_log`.

**Identity & Dashboard:**

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/admin/me` | Returns `{ isAdmin: true }`. Used to verify admin access on login. |
| `GET` | `/api/admin/dashboard` | Cohort statistics: users by tier, standing, pending verifications. |
| `GET` | `/api/admin/access-requests` | All access requests (newest-first). |

**Accounts:**

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/admin/accounts` | `?search=&tier=&standing=&page=1` — paginated account list. |
| `GET` | `/api/admin/accounts/:userId` | Full account detail (tolerance_rating, legal_name, roles, audit log). Logged. |
| `POST` | `/api/admin/accounts/:userId/suspend` | Set account_standing = 'suspended'. |
| `POST` | `/api/admin/accounts/:userId/unsuspend` | Set account_standing = 'active'. |
| `POST` | `/api/admin/accounts/:userId/demote` | Demote Empowered user. Body: `{ reason? }` |
| `POST` | `/api/admin/accounts/:userId/promote` | Promote Inform user to Connected. Body: `{ note? }`. 409 ALREADY_CONNECTED. |
| `PATCH` | `/api/admin/accounts/:userId/verification-rating` | `{ verification_rating?, clear_hold? }` — manual VR override. |
| `GET` | `/api/admin/accounts/:userId/xp-history` | Paginated XP history (25/page). |
| `GET` | `/api/admin/accounts/:userId/promotion-history` | Promotion log for a user. |
| `GET` | `/api/admin/promotions` | Global promotion log. |

**Invites:**

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/admin/invites` | All invite codes with creator and claimer info. Paginated. |
| `POST` | `/api/admin/invites` | Create admin invite code. Body: `{ recipient_email? }` |
| `DELETE` | `/api/admin/invites/:codeId` | Revoke an invite code. |
| `GET` | `/api/admin/invites/tree` | Full cohort invite tree (React Flow format). |
| `GET` | `/api/admin/invites/tree/:userId` | Invite subtree rooted at a user. |

**Roles:**

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/admin/roles/grant` | `{ user_id, role_slug }` — grant a role. |
| `POST` | `/api/admin/roles/revoke` | `{ user_id, role_slug }` — revoke a role. |

**Compass Admin:**

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/admin/compass/topics` | All topics (including non-live drafts). |
| `POST` | `/api/admin/compass/topics` | Create topic + optional stances. |
| `PATCH` | `/api/admin/compass/topics/:id` | Update topic metadata. |
| `GET` | `/api/admin/compass/topics/:id/stances` | All stances for a topic. |
| `PATCH` | `/api/admin/compass/stances/:id` | Update a stance. |
| `GET` | `/api/admin/compass/politicians` | All politicians (admin view). |
| `POST` | `/api/admin/compass/politicians` | Create a politician. |
| `PATCH` | `/api/admin/compass/politicians/:id` | Update a politician. |
| `PUT` | `/api/admin/compass/politicians/:id/answers` | Set politician compass answers. |
| `POST` | `/api/admin/compass/politicians/:id/context` | Set politician context (reasoning + sources). |
| `GET` | `/api/admin/compass/categories` | All compass categories. |
| `POST` | `/api/admin/compass/categories` | Create a category. |
| `POST` | `/api/admin/compass/topics/:id/categories` | Assign topic categories. |

**Cron Log:**

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/admin/cron-log` | Recent cron job execution log. |

---

## 9. Anti-Patterns

Collected reference of things NOT to do. These are real mistakes that have caused production bugs.

### 9.1 Go Server URL

**Do NOT use `ev-backend-h3n8.onrender.com` or any variant of the old Go server URL.**

The Go server is permanently down. All requests will time out or receive connection errors. All routes exist on `api.empowered.vote`.

### 9.2 inform.politicians Integer IDs

**Do NOT use `inform.politicians` integer IDs in any new code.**

All politician references across the platform use `essentials.politicians` UUIDs. Using an integer where a UUID is expected returns 422 VALIDATION_ERROR. The bridge table exists for migration only.

### 9.3 SUPABASE_JWT_SECRET

**Do NOT set `SUPABASE_JWT_SECRET` on any Render deployment or feature backend.**

GoTrue migrated from HS256 to ES256 (asymmetric P-256). The symmetric secret is no longer valid for verification. Use the JWKS endpoint instead. Setting `SUPABASE_JWT_SECRET` causes auth middleware to use symmetric verification, which will fail for all tokens.

### 9.4 Multi-Table Writes via Chained JS Awaits

**Do NOT chain JS `await` calls for multi-table writes that must be atomic.**

```typescript
// WRONG
await supabase.from('connected_profiles').insert(profileData);
await supabase.from('invite_codes').update({ is_claimed: true }).eq('id', codeId);
// If the second call fails, data is inconsistent

// CORRECT — use SECURITY DEFINER RPC
await adminRpc('complete_connect_flow', { p_user_id: userId });
```

Use `SECURITY DEFINER` RPCs (called via `supabase.rpc()` or `adminRpc()`) for all operations that must write to multiple tables atomically.

### 9.5 supabaseAdmin.schema('essentials') via PostgREST

**Do NOT call `supabaseAdmin.schema('essentials').from(...)` or any PostgREST call into the `essentials` schema.**

The `essentials` schema is not in the PostgREST exposed schema list (`public, connect, empower, inform, graphql_public, validation_quests`). This will fail at runtime. Use `pool.query()` directly:

```typescript
// WRONG
const { data } = await supabaseAdmin.schema('essentials').from('politicians').select('*');

// CORRECT
const { rows } = await pool.query('SELECT * FROM essentials.politicians WHERE is_active = true');
```

Same applies to `transparent_motivations` and `treasury` schemas.

### 9.6 Non-Public Schema Writes via PostgREST

**Do NOT use `supabaseAdmin.schema('connect'|'empower'|...).update()|insert()|upsert()` for writes to non-public schemas.**

PostgREST writes to non-public schemas fail or behave unexpectedly. Use `pool.query()` for all non-public schema writes outside of SECURITY DEFINER RPCs.

### 9.7 Compass Value Range Assumptions

**Do NOT assume compass values are integers or that the range is 0–5 or 1–5.**

Valid values are `0.5, 1.0, 1.5, ... 5.0, 5.5` (float, half-step scale). The Zod schema enforces `multipleOf(0.5).min(0.5).max(5.5)`. Values outside this range are rejected with 422.

### 9.8 Nested SECURITY DEFINER Calls

**Do NOT call one SECURITY DEFINER function from inside another.**

Gem/XP writes must be inline in atomic RPCs, not via nested `credit_gems` or `award_xp` calls. Nested SECURITY DEFINER calls can cause unexpected permission escalation and make advisory lock reasoning harder to follow.

### 9.9 tolerance_rating and legal_name at Root Level

**Do NOT surface `tolerance_rating` or `legal_name` at the root level of any API response.**

Both fields are enforced at the RLS layer AND the serialization layer. `tolerance_rating` lives inside `connected_profile` nested object (owner self-view only). `legal_name` lives inside `empowered_profile` nested object (owner self-view only). Tests are required to assert absence of these fields in non-owner responses.

---

## 10. Migration Checklist

Steps for a partner app to migrate from Go-server integration to ev-accounts integration:

- [ ] **Update base URL** — Replace `ev-backend-h3n8.onrender.com` with `api.empowered.vote` everywhere.
- [ ] **Update JWT verification** — Remove `SUPABASE_JWT_SECRET` env var. Update middleware to use `createRemoteJWKSet` from `jose` with the JWKS endpoint `https://kxsdzaojfaibhuzmclfq.supabase.co/auth/v1/.well-known/jwks.json`.
- [ ] **Update login flow to SSO** — Replace direct `POST /api/auth/login` form with redirect to `https://accounts.empowered.vote/login?redirect=...`. Read token from `#access_token=` hash fragment on return.
- [ ] **Add GET /api/auth/session call on app load** — For silent token renewal via `ev_session` cookie. Send with `credentials: 'include'`.
- [ ] **Update all politician ID references** — Replace `inform.politicians` integer IDs with `essentials.politicians` UUIDs. Check `POST /api/compass/compare`, `POST /api/vq/confirm-stance`, and any direct DB calls.
- [ ] **Update compass value handling** — Ensure all compass value inputs and displays support the 0.5–5.5 half-step range. Remove integer casts.
- [ ] **Update essentials DB access** — Replace any `supabase.schema('essentials')` calls with `pool.query()` against fully-qualified table names.
- [ ] **Add `credentials: 'include'` to cross-origin fetch calls** — Required for the `ev_session` cookie to be sent.
- [ ] **Check CORS_ORIGIN** — Confirm your app's domain is in the CORS allowed list. Contact the project owner if not.
- [ ] **Update `GET /api/account/me` response consumers** — The response shape now includes `verification_rating`, `vq_hold_active`, `red_gem_quests_unlocked`, `jurisdiction`, and nested `connected_profile` / `empowered_profile` objects.
- [ ] **Check XP consumer** — `connected_profile.xp` is now an object `{ total, level, xp_in_level, xp_to_next_level }`, not an integer. Top-level `gems` object also present.
- [ ] **Verify service key headers** — XP award uses `X-Service-Key` header. Gems award uses `Authorization: Bearer <gem-service-key>`. Confirm your service key is provisioned and permitted for your source/gem_type.
- [ ] **Remove any direct Go-server `/api/essentials/politicians` integer ID calls** — All politician IDs in essentials responses are UUIDs.
- [ ] **Run smoke test** — See `docs/SMOKE-TEST-INTEG.md` for the verified integration smoke test script.
