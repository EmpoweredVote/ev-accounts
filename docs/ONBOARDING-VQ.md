# Validation Quests → Empowered Accounts Integration Guide

**Audience:** Claude working in the `empowered-validation-quests` codebase
**Accounts API:** `https://ev-accounts-api.onrender.com`
**Last updated:** 2026-03-16 (v1.4 — confirm-stance added, VR fields on /me)

---

## What Accounts Provides to Validation Quests

Empowered Accounts is the shared identity and permission layer for the platform. Validation Quests does not manage its own user accounts — every VQ user is an Empowered Accounts user identified by the same UUID from the shared Supabase project.

What accounts owns that VQ uses:

| Concern | Owned By | How VQ Accesses It |
|---------|----------|--------------------|
| User identity (UUID, email, tier) | Accounts | `GET /api/account/me` with Bearer token |
| XP progression | Accounts | `POST /api/xp/award` with service key |
| User jurisdiction (district) | Accounts | `GET /api/account/me/jurisdiction` with Bearer token |
| Account creation / signup | Accounts | `accounts.empowered.vote/signup?redirect=<vq-url>` |
| Public profile | Accounts | `GET /api/account/profile/:userId` |
| Stance confirmation | Accounts | `POST /api/vq/confirm-stance` with service key |

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

---

## Migration: Direct RPC → API Endpoint

VQ previously called `connect.award_xp` via direct Supabase RPC:

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
```

**Use the HTTP endpoint instead.** The RPC still exists but the API endpoint is the correct path for service-to-service calls — it handles auth, source validation, and error responses uniformly.

```typescript
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
    idempotency_key: `vq-submit-${submissionId}`,
    metadata: { questId, submissionId },
  }),
});
```

**You can now enable XP awards.** The `validation_quest_completion` source is registered and authorized for `QUEST_SERVICE_KEY`. Set `ENABLE_XP_AWARDS=true` in VQ's Render environment when ready.

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
  total_xp: number;
  level: number;
  is_duplicate: boolean;  // true if idempotencyKey already used — no double-award
}

// 422 — source not permitted for this key
{ error: 'SOURCE_NOT_PERMITTED', message: "This service key is not authorized to award source '...'" }

// 401 — invalid or missing key
{ error: 'Missing or invalid X-Service-Key' }
```

### Idempotency

Always derive `idempotency_key` from a stable event identifier. Safe to retry on 5xx — duplicate returns `is_duplicate: true`:

```typescript
const idempotency_key = `vq-submit-${submissionId}-${userId}`;
```

### Permitted Source

`QUEST_SERVICE_KEY` is authorized for `'validation_quest_completion'` only. Any other source returns 422.

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

  const data = await res.json();
  return data; // { total_xp, level, is_duplicate }
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

### Authentication

Same `X-Service-Key` header pattern as XP awards. Use the `VQ_SERVICE_KEY` value provided by Chris. This key must have `red` gem type permission in the accounts API `GEMS_SERVICE_KEYS` env var (separate from `QUEST_SERVICE_KEY` which handles XP and is a different key).

### Complete Example

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
  unresolved_users: string[];
  replayed?: boolean;  // present and true on idempotent replay; absent on first call
}

async function confirmStance(opts: {
  politicianId: string;
  topicId: string;
  confirmedValue: number;
  correctUserIds: string[];
  incorrectUserIds: string[];
  idempotencyKey: string;
  gemsAmount?: number;
}): Promise<ConfirmStanceResult> {
  const res = await fetch(`${ACCOUNTS_API_URL}/api/vq/confirm-stance`, {
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
  return res.json() as Promise<ConfirmStanceResult>;
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

**idempotency_key guidance:** Derive from your internal resolution event ID, not per-user. Example: `vq-resolution-${resolutionId}`. All users in that resolution share the same key — the accounts API handles per-user deduplication internally.

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

`unresolved_users` contains UUIDs that were submitted but could not be processed (e.g., user no longer exists). These are informational — no error is thrown.

`replayed: true` is present when the `idempotency_key` was already used. The original result is returned unchanged — no additional gems awarded, no ratings changed. The field is absent (not `false`) on the first call.

### Side Effects

**For each user in `correct_user_ids`:**
- Awarded `gems_amount` Red Gems (default: 1)
- `verification_rating` increases by **+3**, capped at **150**
  - Example: rating 148 + 3 = **150** (not 151)
  - Example: rating 60 + 3 = **63**

**For each user in `incorrect_user_ids`:**
- `verification_rating` decreases by **−10**, floored at **0**
  - Example: rating 8 − 10 = **0** (not −2)
  - Example: rating 60 − 10 = **50**
- If rating reaches **0**, `vq_hold_until` is set to **now + 30 days**
  - The user's `/api/account/me` response shows `vq_hold_active: true`
  - They cannot participate in Red Gem quests until the hold expires

**For the question itself:**
- `inform.politician_answers` is upserted with `confirmed_value` as the authoritative stance record

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
| 422 | `{ "error": "VALIDATION_ERROR", "issues": [{ "field": "politician_id", "message": "Invalid uuid" }] }` | Zod validation failure — check required fields and UUID format |
| 422 | `{ "error": "FORBIDDEN_GEM_TYPE", "permitted": ["yellow"] }` | Service key lacks `red` gem type permission — contact Chris to update accounts API env |
| 422 | `{ "error": "INVALID_VALUE" }` | `confirmed_value` outside 1–5 |
| 404 | `{ "error": "QUESTION_NOT_FOUND" }` | The `politician_id` / `topic_id` pair does not exist in the compass |

All errors return `{ "error": string }` with an optional `issues` array for validation failures. On 5xx, retry with the same `idempotency_key` — safe to replay.

**Idempotency conflict behavior:** If you send the same `idempotency_key` with a different payload, the original result for that key is returned (no conflict error is raised). Never reuse a key across different resolution events.

### Environment Variables

| Variable | Purpose | Value Source |
|----------|---------|--------------|
| `VQ_SERVICE_KEY` | Stance confirmation auth (must have `red` gem type) | Chris provides; must match accounts API `GEMS_SERVICE_KEYS` env |

---

## Reading User State

```
GET /api/account/me
Authorization: Bearer <userJwt>
```

Response shape (Connected user):

```typescript
{
  id: string;
  tier: 'inform' | 'connected' | 'empowered';
  completed_onboarding: boolean;
  xp: {
    total: number;
    level: number;
    xp_in_level: number;          // XP earned within current level
    xp_to_next_level: number | null;  // null at max level
  } | null;   // null for Inform-tier users (no connected_profiles)
  gems: {
    yellow: number;
    blue: number;
    red: number;
  } | null;
  location_consent: boolean;
  verification_rating: number;      // 0–150; default 60
  vq_hold_active: boolean;          // true if vq_hold_until is in the future
  red_gem_quests_unlocked: boolean; // true when verification_rating >= 90
  // ... other fields
}
```

**XP level thresholds** (for display only — use `xp_in_level` / `xp_to_next_level` for progress bars):
- Levels 1–3: 2,000 XP each
- Levels 4–9: 3,000 XP each
- Levels 10–29: 4,000 XP each
- Levels 30+: 5,000 XP each

**Inform-tier users** have `xp: null` and `gems: null`. These users have no `connected_profiles` row. Guard:

```typescript
const xpLevel = meData.xp?.level ?? 0;
const totalXp = meData.xp?.total ?? 0;
```

**Tier gating:** If a quest requires Connected tier or above, check `meData.tier !== 'inform'` before allowing submission.

---

## Jurisdiction (District Eligibility)

For quests scoped to a specific district (e.g., "Monroe County only"), use the jurisdiction endpoint:

```
GET /api/account/me/jurisdiction
Authorization: Bearer <userJwt>
```

Response:

```typescript
{
  congressional: string;    // e.g. "1809"
  state_senate: string;
  state_house: string;
  county: string;
  school_district: string;
}
```

**403 if `location_consent = false`** — the user hasn't set their location yet. Handle this gracefully: prompt them to set their location at `accounts.empowered.vote` or via the set-location flow.

```typescript
const jurisdictionRes = await fetch(`${ACCOUNTS_URL}/api/account/me/jurisdiction`, {
  headers: { 'Authorization': `Bearer ${userJwt}` },
});

if (jurisdictionRes.status === 403) {
  // User hasn't shared location — prompt them or show location-agnostic quests
  return { hasLocation: false };
}

const jurisdiction = await jurisdictionRes.json();
// jurisdiction.county === '18105' → Monroe County, Indiana
```

Raw coordinates are never returned — only jurisdiction strings. Accounts handles all geocoding and encryption internally.

---

## Public Profile

To display a user's public profile (e.g., leaderboard, contributor credit):

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
  empowered_profile?: { ... };  // present for Empowered users
}
```

No gems, no tolerance_rating, no location data. Safe to display publicly.

---

## Account Creation

VQ should **not** implement its own signup flow. Direct users to:

```
https://accounts.empowered.vote/signup?redirect=https://quests.empowered.vote/feed
```

After creating a Connected Account and confirming their email, users are redirected back to VQ at the URL you provided. The `redirect` param only accepts `*.empowered.vote` domains.

For the login flow:

```
https://accounts.empowered.vote/login?redirect=https://quests.empowered.vote/feed
```

---

## Responding to the Coordination Doc Questions

From `ACCOUNTS-COORDINATION.md` (2026-03-08):

**Item 1 — `validation_quest_completion` source key:** Confirmed registered and authorized. Enable XP awards now (`ENABLE_XP_AWARDS=true`).

**Item 2 — XP level formula:** Already returned in `GET /api/account/me` as `xp.level`, `xp.xp_in_level`, and `xp.xp_to_next_level`. Use these directly for the XPBar — no client-side calculation needed.

**Item 3 — Verification Rating integration:** Fully implemented. Accounts owns `verification_rating` on `connected_profiles`. VQ does not maintain its own rating table — all rating adjustments happen atomically inside `POST /api/vq/confirm-stance` (+3 correct, −10 incorrect, floor 0, cap 150). Accounts also handles hold enforcement (`vq_hold_until`) and surfaces `vq_hold_active` and `red_gem_quests_unlocked` on `GET /api/account/me`. VQ should read these fields to gate quest participation — no local rating state needed.

---

## Error Handling

| Status | Meaning | Action |
|--------|---------|--------|
| 401 | Invalid/missing token | Re-prompt login (user token) or check key config (service key) |
| 403 | Insufficient tier or consent not given | Show upgrade/setup prompt |
| 422 | Validation error | Fix the request — do not retry |
| 429 | Rate limited | Exponential backoff |
| 5xx | Server error | Retry with same `idempotencyKey` — safe, duplicate returns 200 |

---

## Environment Variables VQ Needs

| Variable | Purpose | Value Source |
|----------|---------|--------------|
| `ACCOUNTS_URL` | Base URL for accounts API | `https://ev-accounts-api.onrender.com` |
| `QUEST_SERVICE_KEY` | XP award auth (`X-Service-Key`) | Chris provides; must match accounts API env |
| `VQ_SERVICE_KEY` | Stance confirmation auth (`X-Service-Key`, needs `red` gem permission) | Chris provides; must match accounts API `GEMS_SERVICE_KEYS` env |
| `ENABLE_XP_AWARDS` | Feature flag for XP award calls | Set to `true` — source key is confirmed |

---

## What VQ Does NOT Own

- User account creation, deletion, or password management
- Tier promotion (admin tool handles this, or users go through the accounts signup/invite flow)
- Direct gem balance writes — always go through `POST /api/vq/confirm-stance` for Red Gem awards; do not call gem endpoints directly
- XP ledger reads (beyond `/api/account/me`)
- Tolerance Rating (internal to accounts, never exposed externally)
- Location storage or geocoding

If VQ needs something from accounts that isn't in this doc, file a feature request against the `empowered-accounts` repo and tag it for Chris.
