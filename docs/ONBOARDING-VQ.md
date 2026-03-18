# Validation Quests → Empowered Accounts Integration Guide

**Audience:** Claude working in the `empowered-validation-quests` codebase
**Accounts API:** `https://ev-accounts-api.onrender.com`
**Last updated:** 2026-03-18 (v1.5 — profile.empowered.vote canonical, referral codes, corrected /me shape)

---

## What Accounts Provides to Validation Quests

Empowered Accounts is the shared identity and permission layer for the platform. Validation Quests does not manage its own user accounts — every VQ user is an Empowered Accounts user identified by the same UUID from the shared Supabase project.

| Concern | Owned By | How VQ Accesses It |
|---------|----------|--------------------|
| User identity (UUID, email, tier) | Accounts | `GET /api/account/me` with Bearer token |
| XP progression | Accounts | `POST /api/xp/award` with service key |
| User jurisdiction (district) | Accounts | `jurisdiction` field on `GET /api/account/me` (or dedicated `/me/jurisdiction`) |
| Account creation / signup | Accounts | `profile.empowered.vote/signup?redirect=<vq-url>` |
| Login | Accounts | `profile.empowered.vote/login?redirect=<vq-url>` |
| Public profile | Accounts | `GET /api/account/profile/:userId` |
| Stance confirmation | Accounts | `POST /api/vq/confirm-stance` with service key |
| VR adjustment (Yellow quests) | Accounts | `POST /api/vq/adjust-vr` with service key |

---

## Authentication

### User-Scoped Requests

VQ receives a Supabase JWT when a user authenticates. Pass it as a Bearer token:

```typescript
const response = await fetch('https://ev-accounts-api.onrender.com/api/account/me', {
  headers: {
    'Authorization': `Bearer ${supabaseAccessToken}`,
  },
});
```

The token comes from `supabase.auth.getSession()` → `session.access_token`. No conversion needed — it's a standard Supabase JWT that accounts verifies via JWKS.

### Service-Key Requests (XP awards, stance confirmation)

Service-to-server calls use the `X-Service-Key` header — never the `Authorization` header, never expose the key to the client.

```typescript
const response = await fetch('https://ev-accounts-api.onrender.com/api/xp/award', {
  method: 'POST',
  headers: {
    'X-Service-Key': process.env.QUEST_SERVICE_KEY!,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({ ... }),
});
```

**Key setup:** Chris sets matching values in both VQ's Render environment (`QUEST_SERVICE_KEY`, `VQ_SERVICE_KEY`) and the accounts API environment. VQ doesn't register keys — just uses the values Chris provides.

**Two separate keys:**
- `QUEST_SERVICE_KEY` — for `POST /api/xp/award` only
- `VQ_SERVICE_KEY` — for `POST /api/vq/confirm-stance` and `POST /api/vq/adjust-vr` (confirm-stance requires `red` gem permission)

---

## Migration: Direct RPC → API Endpoint

VQ previously called `connect.award_xp` via direct Supabase RPC. **Use the HTTP endpoint instead.** The RPC still exists but the API endpoint is the correct path — it handles auth, source validation, error responses, and now also triggers referral code side-effects.

```typescript
// OLD — remove this
await supabaseService
  .schema('connect')
  .rpc('award_xp', {
    p_user_id: userId,
    p_source: 'validation_quest_completion',
    p_amount: xpAmount,
    p_idempotency_key: `vq-submit-${submissionId}`,
  });

// NEW
await fetch(`${ACCOUNTS_URL}/api/xp/award`, {
  method: 'POST',
  headers: {
    'X-Service-Key': process.env.QUEST_SERVICE_KEY!,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    user_id: userId,
    source: 'validation_quest_completion',
    amount: xpAmount,
    idempotency_key: `vq-submit-${submissionId}-${userId}`,
    metadata: { questId, submissionId },
  }),
});
```

---

## XP Awards

### Endpoint

```
POST /api/xp/award
X-Service-Key: <QUEST_SERVICE_KEY>
Content-Type: application/json
```

### Request Body

```typescript
{
  user_id: string;          // Supabase UUID of the user
  source: string;           // must be 'validation_quest_completion'
  amount: number;           // positive integer
  idempotency_key: string;  // unique per award event — prevents double-award on retry
  metadata?: object;        // optional — include quest/submission context for the ledger
}
```

### Response

```typescript
// 200 — awarded (or duplicate)
{
  transaction_id: string;
  user_id: string;
  source: string;
  amount: number;
  created_at: string;
  level: number;              // user's current level after this award
  total_xp: number;           // user's total XP after this award
  xp_in_level: number;        // XP progress within the current level
  xp_to_next_level: number;   // XP remaining to reach the next level
  is_duplicate: boolean;      // true if idempotency_key already used — no double-award
}

// 422 — source not permitted for this key
{ "error": "SOURCE_NOT_PERMITTED", "message": "..." }

// 401 — invalid or missing key
{ "error": "Missing or invalid X-Service-Key" }

// 404 — user has no Connected profile
{ "error": "User not found or not Connected tier" }
```

### Side Effect: Referral Code Unlock

When a user reaches level 2 for the first time, the accounts API automatically generates a referral invite code for them (visible on their profile page at `profile.empowered.vote`). This happens as a fire-and-forget side effect after the XP award — it does not affect the response or timing. No action needed from VQ.

### Idempotency

Always derive `idempotency_key` from a stable event identifier. Safe to retry on 5xx — duplicate returns `is_duplicate: true`:

```typescript
const idempotency_key = `vq-submit-${submissionId}-${userId}`;
```

### Example

```typescript
async function awardQuestXp(userId: string, submissionId: string, questId: string) {
  const res = await fetch(`${ACCOUNTS_URL}/api/xp/award`, {
    method: 'POST',
    headers: {
      'X-Service-Key': process.env.QUEST_SERVICE_KEY!,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      user_id: userId,
      source: 'validation_quest_completion',
      amount: 500,
      idempotency_key: `vq-submit-${submissionId}-${userId}`,
      metadata: { questId, submissionId },
    }),
  });

  if (!res.ok) {
    console.error('[xp/award] failed:', await res.json());
    return null;
  }

  return res.json();
  // { transaction_id, level, total_xp, xp_in_level, xp_to_next_level, is_duplicate }
}
```

---

## Stance Confirmation

When VQ resolves a question (determines the correct answer), call this endpoint to record the confirmed stance, award Red Gems to correct answerers, and adjust Verification Ratings for all participants.

### Endpoint

```
POST /api/vq/confirm-stance
X-Service-Key: <VQ_SERVICE_KEY>
Content-Type: application/json
```

This key must have `red` gem type permission in the accounts API `GEMS_SERVICE_KEYS` env var (separate from `QUEST_SERVICE_KEY`).

### Request Body

| Field | Type | Required | Constraints | Notes |
|-------|------|----------|-------------|-------|
| `politician_id` | string (UUID) | Yes | Valid UUID | The politician this question is about |
| `topic_id` | string (UUID) | Yes | Valid UUID | The compass topic (question) |
| `confirmed_value` | number | Yes | Integer 1–5 | The correct answer value |
| `correct_user_ids` | string[] | No | UUID array | Users who answered correctly; defaults to `[]` |
| `incorrect_user_ids` | string[] | No | UUID array | Users who answered incorrectly; defaults to `[]` |
| `idempotency_key` | string | Yes | max 255 chars | Unique per resolution event — reusing a key returns the original result |
| `gems_amount` | number | No | Positive integer; default 1 | Red Gems awarded to each correct user |

A user can appear in only one array. If a user appears in both, they are treated as correct.

### Response (200)

```typescript
interface ConfirmStanceResult {
  politician_id: string;
  topic_id: string;
  confirmed_value: number;
  correct_count: number;
  incorrect_count: number;
  users: Array<{
    user_id: string;
    result: 'correct' | 'incorrect';
    gems_awarded: number;
    rating_delta: number;
    new_rating: number;
  }>;
  unresolved_users: string[];  // UUIDs that couldn't be processed — informational only
  replayed?: boolean;          // present and true on idempotent replay; absent on first call
}
```

**Example response:**
```json
{
  "politician_id": "uuid",
  "topic_id": "uuid",
  "confirmed_value": 3,
  "correct_count": 2,
  "incorrect_count": 1,
  "users": [
    { "user_id": "uuid-A", "result": "correct",   "gems_awarded": 1, "rating_delta":  3, "new_rating": 78 },
    { "user_id": "uuid-B", "result": "correct",   "gems_awarded": 1, "rating_delta":  3, "new_rating": 93 },
    { "user_id": "uuid-C", "result": "incorrect", "gems_awarded": 0, "rating_delta": -10, "new_rating": 50 }
  ],
  "unresolved_users": []
}
```

### Side Effects

**For each user in `correct_user_ids`:**
- Awarded `gems_amount` Red Gems (default: 1)
- `verification_rating` increases by **+3**, capped at **150**

**For each user in `incorrect_user_ids`:**
- `verification_rating` decreases by **−10**, floored at **0**
- If rating reaches **0**, `vq_hold_until` is set to **now + 30 days**
  - The user's `/api/account/me` response shows `vq_hold_active: true`

**For the question itself:**
- `inform.politician_answers` is upserted with `confirmed_value` as the authoritative stance

**On idempotent replay** (same `idempotency_key`):
- No gems awarded, no rating changes, no DB writes
- Original result returned with `replayed: true`

### Edge Cases

| Scenario | Before | After |
|----------|--------|-------|
| Correct user near cap | `verification_rating` 148 | `verification_rating` 150 (capped) |
| Incorrect user near floor | `verification_rating` 8 | `verification_rating` 0, `vq_hold_until` set +30 days |
| Incorrect user already at floor | `verification_rating` 0 | `verification_rating` 0, `vq_hold_until` reset to now+30 days |
| User in both arrays | — | Treated as correct (deduped before processing) |
| Empty both arrays | — | 200 with `correct_count: 0`, `incorrect_count: 0`, politician_answers upserted |

### Error Responses

| Status | Body | Cause |
|--------|------|-------|
| 401 | `{ "error": "Missing or invalid X-Service-Key" }` | Missing or invalid service key |
| 404 | `{ "error": "QUESTION_NOT_FOUND" }` | The `politician_id` / `topic_id` pair does not exist in the compass |
| 422 | `{ "error": "VALIDATION_ERROR", "issues": [...] }` | Zod validation failure — check required fields and UUID format |
| 422 | `{ "error": "FORBIDDEN_GEM_TYPE", "permitted": ["yellow"] }` | Service key lacks `red` gem permission — contact Chris |
| 422 | `{ "error": "INVALID_VALUE" }` | `confirmed_value` outside 1–5 |

On 5xx, retry with the same `idempotency_key` — safe to replay.

### Example

```typescript
async function confirmStance(opts: {
  politicianId: string;
  topicId: string;
  confirmedValue: number;
  correctUserIds: string[];
  incorrectUserIds: string[];
  idempotencyKey: string;
  gemsAmount?: number;
}): Promise<ConfirmStanceResult> {
  const res = await fetch(`${ACCOUNTS_URL}/api/vq/confirm-stance`, {
    method: 'POST',
    headers: {
      'X-Service-Key': process.env.VQ_SERVICE_KEY!,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      politician_id: opts.politicianId,
      topic_id: opts.topicId,
      confirmed_value: opts.confirmedValue,
      correct_user_ids: opts.correctUserIds,
      incorrect_user_ids: opts.incorrectUserIds,
      idempotency_key: opts.idempotencyKey,
      gems_amount: opts.gemsAmount ?? 1,
    }),
  });

  if (!res.ok) throw new Error(`confirm-stance failed: ${res.status} ${await res.text()}`);
  return res.json();
}

// Usage — called once per resolution event
const result = await confirmStance({
  politicianId: resolution.politicianId,
  topicId: resolution.topicId,
  confirmedValue: resolution.correctValue,
  correctUserIds: resolution.correctSubmitters,
  incorrectUserIds: resolution.incorrectSubmitters,
  idempotencyKey: `vq-resolution-${resolution.id}`,
  gemsAmount: 1,
});

if (result.replayed) {
  // idempotency_key was already used — original result returned, no changes made
}
```

**`idempotency_key` guidance:** Derive from your internal resolution event ID, not per-user. Example: `vq-resolution-${resolutionId}`. All users in that resolution share the same key — the accounts API handles per-user deduplication internally. Never reuse a key across different resolution events.

---

## Verification Rating Adjustment (Yellow Quests)

For Yellow quest immediate grading, use this lighter endpoint to adjust a user's
verification_rating without the full stance confirmation ceremony (no gems, no
politician stance upsert).

### Endpoint

```
POST /api/vq/adjust-vr
X-Service-Key: <VQ_SERVICE_KEY>
Content-Type: application/json
```

### Request Body

| Field | Type | Required | Constraints | Notes |
|-------|------|----------|-------------|-------|
| `user_id` | string (UUID) | Yes | Valid UUID | The user whose VR is being adjusted |
| `delta` | number | Yes | Integer -100 to 100 | Positive = correct, negative = incorrect |
| `idempotency_key` | string | Yes | max 255 chars | Unique per grading event |
| `reason` | string | No | max 255 chars | Context string (e.g., "yellow_quest_correct") |

### Response (200)

```typescript
interface AdjustVrResult {
  user_id: string;
  old_rating: number;
  new_rating: number;
  delta_applied: number;  // actual delta after clamping (may differ from requested)
  vq_hold_set: boolean;   // true if vq_hold_until was set because rating hit 0
  replayed?: boolean;      // present and true on idempotent replay
}
```

### Side Effects

- VR clamped to [0, 100] (Yellow quest range, not the [0, 150] Red quest range)
- If VR reaches 0, `vq_hold_until` is set to now + 30 days
- On idempotent replay: no writes, original result returned with `replayed: true`

### Error Responses

| Status | Body | Cause |
|--------|------|-------|
| 401 | `{ "error": "Missing or invalid X-Service-Key" }` | Bad or missing key |
| 404 | `{ "error": "USER_NOT_FOUND" }` | No connected_profile for this user_id |
| 422 | `{ "error": "VALIDATION_ERROR", "issues": [...] }` | Zod validation failure |

On 5xx, retry with the same `idempotency_key` — safe, duplicate returns 200.

---

## Reading User State

```
GET /api/account/me
Authorization: Bearer <userJwt>
```

**Response shape (Connected user):**

```typescript
{
  // — Identity —
  id: string;
  email: string;
  display_name: string | null;
  tier: 'inform' | 'connected' | 'empowered';
  completed_onboarding: boolean;
  location_consent: boolean;
  is_admin: boolean;

  // — VQ-relevant fields (root level, always present for Connected users) —
  verification_rating: number;      // 0–150; default 60
  vq_hold_active: boolean;          // true if vq_hold_until is in the future
  red_gem_quests_unlocked: boolean; // true when verification_rating >= 90

  // — Gems at root (shortcut for Connected users) —
  gems: {
    yellow: number;
    blue: number;
    red: number;
  } | null;  // null for Inform-tier users

  // — Jurisdiction (null if location_consent is false or Inform tier) —
  jurisdiction: {
    congressional_district: string | null;
    congressional_district_name: string | null;
    state_senate_district: string | null;
    state_senate_district_name: string | null;
    state_house_district: string | null;
    state_house_district_name: string | null;
    county: string | null;
    county_name: string | null;
    school_district: string | null;
    school_district_name: string | null;
  } | null;

  // — Full connected profile (null for Inform-tier users) —
  connected_profile: {
    xp: {
      total: number;
      level: number;
      xp_in_level: number;
      xp_to_next_level: number;
    };
    gems: { yellow: number; blue: number; red: number };
    verification_rating: number;
    vq_hold_active: boolean;
  } | null;
}
```

**XP is inside `connected_profile`, not at root.** Access it as:

```typescript
const xp = meData.connected_profile?.xp;
const level = xp?.level ?? 0;
const totalXp = xp?.total ?? 0;
```

**XP level thresholds** (for display — use `xp_in_level` / `xp_to_next_level` for progress bars):
- Levels 1–3: 2,000 XP each
- Levels 4–9: 3,000 XP each
- Levels 10–29: 4,000 XP each
- Levels 30+: 5,000 XP each

**Inform-tier users** have `connected_profile: null` and `gems: null`. Guard:

```typescript
if (!meData.connected_profile) {
  // Inform-tier user — prompt upgrade or show limited experience
}
```

**VQ participation gating:**

```typescript
if (meData.vq_hold_active) {
  // Show hold message — user is on cooldown, cannot participate in Red Gem quests
}
if (!meData.red_gem_quests_unlocked) {
  // verification_rating < 90 — user cannot participate in Red Gem quests yet
  // Show their current rating: meData.verification_rating
}
```

---

## Jurisdiction (District Eligibility)

Jurisdiction data is embedded directly in the `GET /api/account/me` response — no separate call needed. The `jurisdiction` field is present at root level and is `null` when `location_consent` is false or the user is Inform tier.

**Using jurisdiction from /me (preferred):**

```typescript
const meData = await fetch(`${ACCOUNTS_URL}/api/account/me`, {
  headers: { 'Authorization': `Bearer ${userJwt}` },
}).then(r => r.json());

// District-scoped quests
if (meData.jurisdiction) {
  const userDistrict = meData.jurisdiction.congressional_district_name;
  // Filter quests by district...
} else {
  // location_consent is false — prompt user to set location at profile.empowered.vote
}
```

**Jurisdiction field shape (from /me):**

```typescript
jurisdiction: {
  congressional_district: string | null;
  congressional_district_name: string | null;
  state_senate_district: string | null;
  state_senate_district_name: string | null;
  state_house_district: string | null;
  state_house_district_name: string | null;
  county: string | null;
  county_name: string | null;
  school_district: string | null;
  school_district_name: string | null;
} | null
```

**Dedicated endpoint (backward compatible, still available):**

The dedicated `GET /api/account/me/jurisdiction` endpoint remains available for cases where you only need jurisdiction data (e.g., polling just for district changes without re-fetching the full profile). It returns a 403 when `location_consent` is false.

```
GET /api/account/me/jurisdiction
Authorization: Bearer <userJwt>
```

```typescript
const res = await fetch(`${ACCOUNTS_URL}/api/account/me/jurisdiction`, {
  headers: { 'Authorization': `Bearer ${userJwt}` },
});

if (res.status === 403) {
  return { hasLocation: false };
}

const { jurisdiction } = await res.json();
```

Raw coordinates are never returned — only human-readable district names. Accounts handles all geocoding and encryption internally.

---

## Public Profile

To display a user's public profile (leaderboard, contributor credit):

```
GET /api/account/profile/:userId
```

No authentication required. Returns:

```typescript
{
  username: string;
  tier: 'inform' | 'connected' | 'empowered';
  level: number;
  total_xp: number;
  selected_topic_ids: string[];
}
```

No gems, no verification_rating, no location data — safe to display publicly.

---

## Account Creation & Login

VQ should **not** implement its own signup or login flows. `profile.empowered.vote` is the canonical user-facing app. Direct users there with a `redirect` param:

```
# Signup
https://profile.empowered.vote/signup?redirect=https://quests.empowered.vote/feed

# Login
https://profile.empowered.vote/login?redirect=https://quests.empowered.vote/feed
```

After the user creates an account or signs in, they are redirected back to the URL provided. The `redirect` param only accepts `*.empowered.vote` domains.

> **Note:** `accounts.empowered.vote` is the admin panel only and does not serve the end-user signup/onboarding flow. Always link to `profile.empowered.vote`.

---

## Error Handling

| Status | Meaning | Action |
|--------|---------|--------|
| 401 | Invalid/missing token or service key | Re-prompt login (user token) or check key config (service key) |
| 403 | Insufficient tier or consent not given | Show upgrade/setup prompt |
| 404 | User not found or resource not found | Handle gracefully — do not retry |
| 422 | Validation error | Fix the request — do not retry |
| 429 | Rate limited | Exponential backoff |
| 5xx | Server error | Retry with same `idempotency_key` — safe, duplicate returns 200 |

---

## Environment Variables VQ Needs

| Variable | Purpose | Value Source |
|----------|---------|--------------|
| `ACCOUNTS_URL` | Base URL for accounts API | `https://ev-accounts-api.onrender.com` |
| `QUEST_SERVICE_KEY` | XP award auth (`X-Service-Key`) | Chris provides; must match accounts API env |
| `VQ_SERVICE_KEY` | Stance confirmation auth (`X-Service-Key`, needs `red` gem permission) | Chris provides; must match accounts API `GEMS_SERVICE_KEYS` env |

---

## What VQ Does NOT Own

- User account creation, deletion, or password management
- Tier promotion (admin panel handles this; users sign up via `profile.empowered.vote`)
- Direct gem balance writes — always go through `POST /api/vq/confirm-stance` for Red Gem awards
- XP ledger reads (beyond the fields returned by `/api/account/me`)
- Tolerance Rating — internal to accounts, never exposed externally
- Location storage or geocoding
- Referral codes — generated automatically by accounts when a user hits level 2

If VQ needs something from accounts that isn't in this doc, file a feature request against the `empowered-accounts` repo and tag it for Chris.
