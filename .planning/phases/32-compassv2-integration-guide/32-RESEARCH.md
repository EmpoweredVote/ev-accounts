# Phase 32: CompassV2 Integration Guide - Research

**Researched:** 2026-03-19
**Domain:** Documentation — auth redirect flow, compass API, tier model, jurisdiction
**Confidence:** HIGH — all findings sourced directly from production code (routes, frontend)

---

## Summary

This phase produces a single markdown file: `docs/COMPASSV2-INTEGRATION.md`, replacing `docs/COMPASS_CONTRACT.md`. Research involved reading the existing contract, every relevant route handler (`account.ts`, `auth.ts`, `compass.ts`), the accounts app login page and redirect utility, the app frontend hash fragment handler, and planning docs for phases 24 and quick-003.

The existing `COMPASS_CONTRACT.md` (Phase 18, 2026-03-10) is substantially accurate but is missing several additions shipped post-Phase 18: (1) the auth redirect/hash fragment flow added in quick-005, (2) jurisdiction fields on `/api/account/me` added in quick-003, (3) new root-level fields on `/me` (gems, verification_rating, vq_hold_active, red_gem_quests_unlocked, is_admin, location_consent), and (4) expanded connected_profile shape with gem structure change. The contract also documents login/signup as direct-call endpoints but the actual CompassV2 flow is a browser redirect, not an API call.

**Primary recommendation:** Write the new doc around the auth redirect workflow first (CompassV2 will never call POST /auth/login directly), then compass data workflows, then jurisdiction, then tier model. Everything in `COMPASS_CONTRACT.md` that remains accurate can be incorporated; everything about direct login/signup is now superseded.

---

## What COMPASS_CONTRACT.md Contains and What Has Changed

### What it covers (still accurate)
- All compass endpoints: topics, categories, answers, answers/batch, selected-topics, progress, politicians, politician answers, politician context
- Anonymous mode behavior (unauthenticated returns for each route)
- Guest state migration via POST /auth/signup `guest_state`
- Error codes table
- POST /auth/complete-onboarding
- POST /auth/logout
- Field-level notes: value is NUMERIC, inverted boolean, soft-delete behavior

### What is outdated or missing

| Gap | Details |
|-----|---------|
| Auth redirect flow absent | COMPASS_CONTRACT.md shows POST /auth/login as the auth method. For CompassV2, the correct flow is browser redirect to `accounts.empowered.vote/login?redirect=<url>`, which returns token via `#access_token=<token>` hash fragment. The old login/signup API docs are still accurate for direct callers but not the primary flow for CompassV2. |
| GET /account/me response is stale | Missing: `jurisdiction`, `gems`, `verification_rating`, `vq_hold_active`, `red_gem_quests_unlocked`, `is_admin`, `location_consent`. Connected_profile `gem_balance` field changed to structured `gems: { yellow, blue, red }`. |
| Jurisdiction section absent | Quick-003 added `jurisdiction` object to `/me`. Entire jurisdiction principle (auto-flowing, never ask again) is not documented. |
| New root-level fields undocumented | `location_consent`, `verification_rating`, `vq_hold_active`, `red_gem_quests_unlocked`, `is_admin` all added post-Phase 18 |
| Platform preamble absent | CONTEXT.md requires a full platform philosophy section; old doc has none |
| Invite-signup flow not explained | POST /auth/signup now also accepts `legal_name` + `invite_code` for Creating Connected Accounts in one step |
| POST /auth/request-access not documented | Not relevant to CompassV2 but part of the auth hub surface |

---

## Auth Redirect Flow (The Correct CompassV2 Auth Pattern)

Source: `admin/src/pages/Login.tsx`, `admin/src/lib/redirect.ts`, `app/src/App.tsx`, quick-005 commits.

### How it works

**Step 1 — CompassV2 redirects unauthenticated users to accounts:**

```
window.location.href = `https://accounts.empowered.vote/login?redirect=${encodeURIComponent(currentUrl)}`
```

The `redirect` query parameter is the URL CompassV2 wants to return to after login. Only `*.empowered.vote` domains are trusted — any other domain is silently discarded by the accounts app.

**Step 2 — User authenticates at accounts.empowered.vote:**

The accounts login page reads `?redirect=`, validates the domain, and shows a "You'll be returned to [App] after signing in" callout. The user fills in email + password. On success, the accounts app:
1. Calls `POST /api/auth/login` to get the JWT
2. Calls `GET /api/account/me` to load user state
3. Redirects to the `redirect` URL (or `https://profile.empowered.vote` if absent) with the token appended as a hash fragment:

```typescript
// From admin/src/pages/Login.tsx — production code
window.location.href = `${target}#access_token=${token}`;
```

**Step 3 — CompassV2 receives the token from the hash fragment:**

On page load (or resume from redirect), CompassV2 checks `window.location.hash` for `access_token=`:

```typescript
// Pattern from app/src/App.tsx — exact production implementation
const hash = window.location.hash;
if (hash.includes('access_token=')) {
  const params = new URLSearchParams(hash.substring(1)); // strip the #
  const token = params.get('access_token');
  if (token) {
    // Clean the URL immediately — remove hash so token isn't bookmarked
    window.history.replaceState(null, '', window.location.pathname + window.location.search);
    // Store token in memory + localStorage
    localStorage.setItem('ev_token', token);
    // Fetch user profile with this token
    const me = await fetch(`${API_BASE}/account/me`, {
      headers: { Authorization: `Bearer ${token}` }
    }).then(r => r.json());
    // Now authenticated — proceed
  }
}
```

### Why hash fragment, not query parameter

Security: query parameters are logged by servers, proxies, and browser history. A token in `?access_token=...` would appear in Nginx access logs, CDN logs, and browser history as a bookmarkable URL. Hash fragments are not sent to servers — they never leave the browser. This is why OAuth2 implicit flow uses hash fragments. The accounts platform follows this established security pattern.

### Why login lives at accounts.empowered.vote

Single sign-on architecture: every Empowered Vote feature app (CompassV2, Essentials, CTC, Validation Quests) shares one identity system. Users have one account, one password, one profile. Login logic lives in one place. Feature apps never handle credentials — they only handle tokens.

### Trusted domain validation

Source: `admin/src/lib/redirect.ts`

The accounts app validates the `redirect` param before using it:

```typescript
// Trusted: *.empowered.vote AND empowered.vote root
url.hostname === 'empowered.vote' || url.hostname.endsWith('.empowered.vote')
```

Any other domain is silently discarded; the user lands on `https://profile.empowered.vote` instead. This prevents open redirect attacks. CompassV2 must be hosted at `*.empowered.vote` (e.g., `compass.empowered.vote`) for the redirect to work.

### Signup flow

CompassV2 can link unauthenticated users to the signup page:

```
https://accounts.empowered.vote/signup?redirect=<compassUrl>
```

The signup page preserves the `?redirect=` param. After email confirmation and first login, the user is returned to CompassV2 via the same hash fragment mechanism. Note: signup requires an invite code for the Alpha; inform-tier users can still use the compass without signing up.

---

## Complete GET /api/account/me Response

Source: `backend/src/routes/account.ts` — lines 150–210, read directly.

### Full response shape (Connected user with jurisdiction)

```typescript
{
  // Always present
  id: string;                          // UUID
  email: string;                       // from Supabase Auth
  display_name: string | null;         // from public.users
  avatar_url: string | null;
  tier: 'inform' | 'connected' | 'empowered';
  is_admin: boolean;
  completed_onboarding: boolean;       // false for Inform tier always
  location_consent: boolean;           // false for Inform tier always
  verification_rating: number;         // default 60 for Inform; actual for Connected
  vq_hold_active: boolean;             // derived: vq_hold_until > now()
  red_gem_quests_unlocked: boolean;    // derived: verification_rating >= 90
  account_standing: 'active' | 'suspended';
  jurisdiction: JurisdictionObject | null;  // null if no location_consent or Inform tier
  created_at: string;                  // ISO 8601
  updated_at: string;

  // Present only if empowered_profiles record exists (any empowered_profile, active or demoted)
  empowerment_status?: 'empowered' | 'demoted';

  // Present only when connected_profiles record exists (Connected or Empowered tier)
  connected_profile?: {
    display_name: string | null;
    verification_status: string;
    tolerance_rating: number;          // NEVER at root; owner-only field
    xp: {
      total: number;
      level: number;
      xp_in_level: number;
      xp_to_next_level: number;
    };
    gems: {
      yellow: number;
      blue: number;
      red: number;
    };
    completed_onboarding: boolean;
    verification_rating: number;
    vq_hold_active: boolean;
    vq_hold_until: string | null;      // ISO 8601 or null
    created_at: string;
  };

  // Present only when empowered_profiles record exists
  empowered_profile?: {
    legal_name: string;                // NEVER at root; owner-only field
    is_active: boolean;
    candidate_page_slug: string | null;
    empowered_at: string;
    demoted_at: string | null;
  };

  // Present only when connected_profiles record exists (duplicate of connected_profile.gems)
  gems?: {
    yellow: number;
    blue: number;
    red: number;
  };
}
```

### Jurisdiction object shape

Source: `backend/src/routes/account.ts` — lines 116–128.

Present at root when `connected.location_consent === true`. `null` otherwise.

```typescript
{
  congressional_district: string | null;       // e.g. "18th Congressional District"
  congressional_district_name: string | null;  // human-readable name
  state_senate_district: string | null;
  state_senate_district_name: string | null;
  state_house_district: string | null;
  state_house_district_name: string | null;
  county: string | null;
  county_name: string | null;
  school_district: string | null;
  school_district_name: string | null;
}
```

**Important:** `jurisdiction` is resolved server-side from the user's saved encrypted location via the `resolve_user_jurisdiction` RPC. CompassV2 reads these fields directly — no separate address lookup needed.

### How to determine tier

```typescript
// Tier rules — derived from child record presence, never a flag
// From account.ts line 83:
const tier = (empowered && empowered.is_active) ? 'empowered' : connected ? 'connected' : 'inform';
```

- `tier === 'inform'` → no `connected_profile` in response, no `gems`, no `jurisdiction`
- `tier === 'connected'` → `connected_profile` present, `jurisdiction` present if `location_consent`
- `tier === 'empowered'` → same as connected + `empowered_profile` present

Note: `empowerment_status === 'demoted'` means a user with `empowered_profile.is_active === false`. Their `tier` is `'connected'`, not `'empowered'`. The `empowerment_status` field marks the historical distinction.

---

## All Compass Endpoints

Source: `backend/src/routes/compass.ts` — verified against live code.

### Complete endpoint table

| Method | Path | Auth | Unauthenticated behavior |
|--------|------|------|--------------------------|
| GET | `/api/compass/topics` | Optional | Full data |
| GET | `/api/compass/categories` | Optional | Full data |
| GET | `/api/compass/answers` | Optional | `[]` |
| POST | `/api/compass/answers` | Optional | `null` — not persisted |
| POST | `/api/compass/answers/batch` | Optional | `[]` |
| GET | `/api/compass/selected-topics` | Optional | `{ topic_ids: [] }` |
| PUT | `/api/compass/selected-topics` | Optional | `{ topic_ids: [] }` — not persisted |
| DELETE | `/api/compass/answers/me` | Required | 401 |
| GET | `/api/compass/progress` | Required | 401 |
| GET | `/api/compass/politicians` | Optional | Full data |
| GET | `/api/compass/politicians/:id/answers` | Optional | Full data |
| GET | `/api/compass/politicians/:id/:topicId/context` | Optional | Full data |

### Account endpoints CompassV2 needs

| Method | Path | Auth | Notes |
|--------|------|------|-------|
| GET | `/api/account/me` | Required | Full user profile including tier and jurisdiction |
| PATCH | `/api/account/me` | Required (Connected+) | Update display_name, avatar_url |
| POST | `/api/auth/complete-onboarding` | Required (Connected) | Sets completed_onboarding = true |
| POST | `/api/auth/logout` | Required | Revokes session globally |

### Selected request/response shapes (all from source code)

**GET /api/compass/topics response:**
```json
[{
  "id": "uuid",
  "title": "Minimum Wage",
  "short_title": "Min. Wage",
  "question_text": "Should the federal minimum wage be increased?",
  "stances": [
    { "value": 1, "text": "Strongly Oppose" },
    { "value": 2, "text": "Oppose" },
    { "value": 3, "text": "Neutral" },
    { "value": 4, "text": "Support" },
    { "value": 5, "text": "Strongly Support" }
  ]
}]
```

**GET /api/compass/answers response:**
```json
[{
  "topic_id": "uuid",
  "value": 3.5,
  "write_in_text": "string | null",
  "visibility": "private | public",
  "inverted": false,
  "created_at": "2026-01-15T10:00:00Z",
  "updated_at": "2026-01-15T10:00:00Z"
}]
```

**POST /api/compass/answers request (upsert):**
```json
{
  "topic_id": "uuid",
  "value": 3.5,
  "write_in_text": "optional string, max 500 chars",
  "inverted": false
}
```
Value constraints: `0.5 <= value <= 5.5`, must be multiple of 0.5. Integers 1–5 for preset stances; half-integers for write-in placement.

**PUT /api/compass/selected-topics — Connected tier only:**
```json
{ "topic_ids": ["uuid", "uuid"] }
```
Returns 403 `NOT_CONNECTED` for authenticated Inform users (unlike GET which returns empty). Validates all IDs against live topics.

**GET /api/compass/progress response:**
```json
{
  "answered": 12,
  "total": 30,
  "percent": 40
}
```
Optional `?role=` query param: `city_council | state_legislature | us_congress | president`

---

## Tier Access Model (What Each Tier Can Do in Compass)

### Inform tier (anonymous or email-only account)

- Read all topics, categories, politicians, politician answers, politician context
- Submit answers — server returns `null`, answers NOT persisted
- View selected-topics — returns `{ topic_ids: [] }`
- Save selected-topics — server returns `{ topic_ids: [] }`, NOT persisted

**What this means for CompassV2:** Anonymous users can complete the full compass experience. All answers must be stored in browser localStorage. On signup, pass them in `guest_state` to migrate.

### Connected tier (verified via invite, has connected_profile)

Everything Inform can do, plus:
- Answers ARE persisted server-side via POST /api/compass/answers
- GET /api/compass/answers returns saved answers
- PUT /api/compass/selected-topics persists the selection
- GET /api/compass/selected-topics returns saved selection
- GET /api/compass/progress (auth required)
- DELETE /api/compass/answers/me (auth required)
- POST /api/auth/complete-onboarding
- Jurisdiction populated on /api/account/me (if location_consent)

### Empowered tier

Same as Connected. No compass-specific gating above Connected.

### Key tier checks in compass

```typescript
// From compass.ts — the pattern throughout:
// optionalAuth middleware sets req.userId if token present, leaves null otherwise

router.post('/answers', optionalAuth, async (req, res) => {
  const authReq = req as AuthenticatedRequest;
  if (!authReq.userId) { res.status(200).json(null); return; }  // Inform: no-op
  // Connected/Empowered: persist
});
```

Selected-topics writes return 403 `NOT_CONNECTED` for authenticated Inform users (not unauthenticated — those get empty response). This is a deliberate distinction.

---

## Jurisdiction Principle

Source: quick-003, `backend/src/routes/account.ts`, `app/src/pages/DashboardPage.tsx`.

### What jurisdiction provides

When a Connected user has set their location (location_consent = true), the `/api/account/me` response includes a `jurisdiction` object with their resolved political districts:

- `congressional_district` + `congressional_district_name` — U.S. Congressional district
- `state_senate_district` + `state_senate_district_name`
- `state_house_district` + `state_house_district_name`
- `county` + `county_name`
- `school_district` + `school_district_name`

These are resolved from the user's encrypted location via PostGIS TIGER/Line boundary intersection on the server. CompassV2 receives clean district names — never raw coordinates.

### How to use jurisdiction

```typescript
const me = await fetch('/api/account/me', { headers: { Authorization: `Bearer ${token}` } })
  .then(r => r.json());

if (me.jurisdiction) {
  // User has set location — personalize without asking
  const district = me.jurisdiction.congressional_district_name;
  // "Show politicians from your district first"
  // "Filter compass topics relevant to your state legislature"
}
```

### When jurisdiction is null

- User is Inform tier (no connected_profile)
- User is Connected but has not set location yet (`location_consent === false`)
- The `resolve_user_jurisdiction` RPC failed server-side (graceful degradation)

When `jurisdiction` is `null`, present the universal/non-localized experience. Do not prompt for an address.

### The "never ask for address" principle

A Connected user's address is stored once in the accounts system. Every feature that needs jurisdiction reads it from `/api/account/me`. CompassV2 must never display an address input form or ask a Connected user where they live. The data flows automatically.

This is not just a UX preference — it is a platform contract. The accounts system is the single source of location truth. A user who updates their location in accounts has it updated everywhere instantly because all features read from the same source.

---

## Error Codes

Source: `COMPASS_CONTRACT.md` + route code verification.

| Code | HTTP Status | When |
|------|-------------|------|
| `VALIDATION_ERROR` | 422 | Invalid body (wrong type, out-of-range value, short password) |
| `INVALID_TOPIC_IDS` | 422 | PUT /compass/selected-topics: some IDs not live; `invalid_ids` array included |
| `TOPIC_NOT_FOUND` | 404 | POST /compass/answers: topic UUID not live |
| `NOT_FOUND` | 404 | Politician context: no context record exists |
| `NOT_CONNECTED` | 403 | Action requires Connected tier; user is Inform |
| `AUTH_ERROR` | 401 | JWT invalid, expired, or revoked |
| `INVALID_CREDENTIALS` | 401 | Wrong email or password (not distinguished — OWASP) |
| `EMAIL_NOT_VERIFIED` | 403 | Account exists, email not confirmed |
| `EMAIL_EXISTS` | 409 | Signup: email already registered |
| `INVALID_INVITE_CODE` | 422 | Signup: invite code invalid or already claimed |
| `SELF_INVITE_BLOCKED` | 422 | Signup: user tried to use their own invite code |
| `RATE_LIMIT_EXCEEDED` | 429 | Auth endpoints: 10 req/15 min per IP |
| `EMAIL_DELIVERY_FAILED` | 503 | SMTP failure during signup |
| `USER_NOT_FOUND` | 404 | /account/me: user record not found (DB inconsistency) |
| `INTERNAL_ERROR` | 500 | Unexpected server error |

All error responses:
```json
{ "code": "ERROR_CODE", "message": "human-readable string" }
```
The `message` field is for debugging only — never display it to users. Parse `code` only.

---

## Anti-Patterns to Document

Beyond the two mentioned in CONTEXT.md (address prompt, tier caching), the following should be called out:

### 1. Don't ask for address if jurisdiction is present
Source: jurisdiction principle, platform contract.

### 2. Don't cache tier status client-side
Tier can change (user earns Connected status, gets demoted from Empowered). Always re-read from `/api/account/me`. The one safe cache is within a single session (during a page navigation, not across sessions).

### 3. Don't call POST /auth/login directly
CompassV2 is a browser app using the redirect flow. Calling POST /auth/login directly (e.g., embedding a login form in compass) bypasses the SSO architecture and forces users to manage two separate sessions.

### 4. Don't store tokens beyond the session without refresh handling
JWTs expire in ~1 hour. The API does not expose a refresh token endpoint. If a stored token fails (`AUTH_ERROR`), clear it and redirect to accounts.

### 5. Don't pass answers as integers — always float
`value` on answers is NUMERIC (PostgreSQL) and may be a float. Parse as float, not integer. `value: 3` and `value: 3.5` are both valid; `parseInt` would corrupt 3.5 → 3.

### 6. Don't treat POST /compass/answers returning null as an error
For unauthenticated users, `null` is the correct 200 response. It is not an error — it means "we received your answer, but you're anonymous so it wasn't saved." Handle it gracefully.

### 7. Don't call GET /compass/selected-topics before the user is Connected and expect a 403
GET returns `{ topic_ids: [] }` for unauthenticated users (no 403). Only authenticated-but-not-Connected users get 403 from GET. PUT always returns 403 for authenticated-not-Connected users. These behaviors differ — don't conflate them.

### 8. Don't assume tolerance_rating is accessible
`tolerance_rating` is nested in `connected_profile` and is only returned to the account owner. It is intentionally absent from all other views. CompassV2 should never attempt to read or display it for other users.

---

## Guest State Migration

Source: `backend/src/routes/auth.ts` lines 229–243, `COMPASS_CONTRACT.md` section 7.

On signup, CompassV2 can pass localStorage answers to be migrated:

```typescript
await fetch(`${API_BASE}/auth/signup`, {
  method: 'POST',
  body: JSON.stringify({
    email,
    password,
    legal_name,   // required for invite flow
    invite_code,  // required for Alpha
    guest_state: {
      answers: compassAnswers,       // [{ topic_id, value, write_in_text? }]
      selected_topics: selectedIds,  // [uuid, uuid, ...]
    }
  })
});
```

Migration is best-effort: if it fails, signup still returns 201. `selected_topics` migration requires a Connected profile to already exist — during signup this is always false (user is Inform at signup). Store selected_topics in localStorage and submit via `PUT /compass/selected-topics` after the user completes Connect enrollment.

---

## Platform Philosophy (What the New Doc Needs to Explain)

Source: `empowered-vote-primer.md`, `PROJECT.md`.

The new doc's first section must establish:

**Three tiers — Inform, Connected, Empowered:**
- **Inform:** Everyone. No account required. Anonymous compass usage is a first-class experience, not a degraded one. Compass answers are not saved server-side, but the full calibration UX is available.
- **Connected:** Verified via invite chain (Alpha). Pseudonymous identity. Answers persist. Jurisdiction flows automatically. Selected topics save. History preserved.
- **Empowered:** Leadership tier. Connected users who chose civic leadership. Their compass becomes fully public. Not relevant to compass-specific gating.

**Why tiers are child records, not flags:**
The presence of a `connected_profiles` row IS the Connected tier. There is no `tier` column that could be set incorrectly. CompassV2 reads `tier` from `/api/account/me` — this field is computed server-side from child record presence.

**Why the single account system matters:**
A user's Empowered Vote account works across all platform features. Their XP, gems, location, and compass answers are maintained once. CompassV2 does not maintain its own user store — it reads from and writes to accounts.

---

## Sources

### Primary (HIGH confidence — all sourced from production code)

- `backend/src/routes/account.ts` — GET /me and PATCH /me full implementation
- `backend/src/routes/auth.ts` — login, signup, logout, complete-onboarding
- `backend/src/routes/compass.ts` — all compass routes
- `admin/src/pages/Login.tsx` — hash fragment redirect implementation
- `admin/src/lib/redirect.ts` — trusted domain validation
- `app/src/App.tsx` — hash fragment receiving implementation
- `app/src/components/AuthGuard.tsx` — redirect-to-accounts pattern
- `docs/COMPASS_CONTRACT.md` — existing contract (Phase 18, 2026-03-10)
- `.planning/quick/003-*` — jurisdiction field addition details
- `.planning/phases/24-*` — auth hub and redirect design
- `empowered-vote-primer.md` — platform philosophy

---

## Open Questions

1. **Does CompassV2 need to handle the `empowerment_status` field?**
   - What we know: it exists on `/me` for users with any empowered_profiles row
   - What's unclear: whether CompassV2 shows different UI for empowered vs connected users
   - Recommendation: document the field, note it's informational for compass purposes

2. **What is compass.empowered.vote's actual URL structure?**
   - What we know: DashboardPage.tsx lists `https://compass.empowered.vote` as the compass URL
   - What's unclear: whether CompassV2 is at the root or a subdirectory
   - Recommendation: use `https://compass.empowered.vote` in auth redirect examples; the trusted domain check covers `*.empowered.vote`

3. **Token persistence strategy for CompassV2**
   - What we know: JWTs expire in ~1 hour, no refresh token endpoint in the API
   - What's unclear: how long CompassV2 sessions should last, whether long-session support is needed
   - Recommendation: document that on `AUTH_ERROR`, clear token and redirect to login

---

## Metadata

**Confidence breakdown:**
- Auth redirect flow: HIGH — read from production Login.tsx and redirect.ts directly
- Account/me response shape: HIGH — read from production account.ts directly
- Compass endpoints: HIGH — read from production compass.ts directly
- Jurisdiction fields: HIGH — read from production account.ts directly
- Platform philosophy: HIGH — from empowered-vote-primer.md
- Anti-patterns: HIGH — derived from code behavior, CONTEXT.md decisions

**Research date:** 2026-03-19
**Valid until:** 2026-06-01 (stable; next invalidation is a new endpoint or schema change)
