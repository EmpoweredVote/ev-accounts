# Validation Quests → Empowered Accounts Integration Guide

**Audience:** Claude working in the `empowered-validation-quests` codebase
**Accounts API:** `https://ev-accounts-api.onrender.com`
**Last updated:** 2026-03-15 (v1.3 deployed)

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

### Service-Key Requests (XP awards)

XP awards are server-to-server. Use `QUEST_SERVICE_KEY` — never expose it to the client.

```typescript
const response = await fetch('https://ev-accounts-api.onrender.com/api/xp/award', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${process.env.QUEST_SERVICE_KEY}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({ ... }),
});
```

**Key setup:** Chris sets matching values in both VQ's Render environment (`QUEST_SERVICE_KEY`) and the accounts API environment. VQ doesn't register keys — just uses the value Chris provides.

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
    'Authorization': `Bearer ${process.env.QUEST_SERVICE_KEY}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    userId,
    source: 'validation_quest_completion',
    amount: xpAmount,
    idempotencyKey: `vq-submit-${submissionId}`,
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
Authorization: Bearer <QUEST_SERVICE_KEY>
Content-Type: application/json
```

### Request Body

```typescript
{
  userId: string;          // Supabase UUID of the user
  source: string;          // must be 'validation_quest_completion'
  amount: number;          // positive integer
  idempotencyKey: string;  // unique per award event — prevents double-award on retry
  metadata?: object;       // optional — include quest/submission context for the ledger
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
{ error: 'SOURCE_NOT_PERMITTED' }

// 401 — invalid or missing key
{ error: 'UNAUTHORIZED' }
```

### Idempotency

Always derive `idempotencyKey` from a stable event identifier. Safe to retry on 5xx — duplicate returns `is_duplicate: true`:

```typescript
const idempotencyKey = `vq-submit-${submissionId}-${userId}`;
```

### Permitted Source

`QUEST_SERVICE_KEY` is authorized for `'validation_quest_completion'` only. Any other source returns 422.

### Example

```typescript
async function awardQuestXp(userId: string, submissionId: string, questId: string) {
  const res = await fetch(`${ACCOUNTS_URL}/api/xp/award`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.QUEST_SERVICE_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      userId,
      source: 'validation_quest_completion',
      amount: 500,
      idempotencyKey: `vq-submit-${submissionId}-${userId}`,
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

**Item 3 — Veracity Rating integration:** Not yet designed on the accounts side. For Alpha, VQ should maintain its own `user_veracity_profiles` table (as currently built). When accounts is ready to aggregate veracity data platform-wide, a push model (VQ calls an accounts endpoint with an accuracy delta after each consensus finalization) is preferred — it keeps accounts as the aggregation source of truth. File a feature request when VQ is ready to integrate; include the `accuracy_rate`, `restriction_state`, and `review_required` fields as the proposed push payload.

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
| `QUEST_SERVICE_KEY` | XP award auth | Chris provides; must match accounts API env |
| `ENABLE_XP_AWARDS` | Feature flag for XP award calls | Set to `true` — source key is confirmed |

---

## What VQ Does NOT Own

- User account creation, deletion, or password management
- Tier promotion (admin tool handles this, or users go through the accounts signup/invite flow)
- Gem awards (VQ does not currently award gems — if needed in future, request a gem key from Chris)
- XP ledger reads (beyond `/api/account/me`)
- Tolerance Rating (internal to accounts, never exposed externally)
- Location storage or geocoding

If VQ needs something from accounts that isn't in this doc, file a feature request against the `empowered-accounts` repo and tag it for Chris.
