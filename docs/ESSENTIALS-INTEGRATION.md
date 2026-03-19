# Essentials Integration Guide

Canonical integration guide for the Essentials team against the Empowered Accounts API.

---

## Table of Contents

1. [Quick Reference](#1-quick-reference)
2. [Empowered Vote Platform Overview](#2-empowered-vote-platform-overview)
3. [The Jurisdiction Principle](#3-the-jurisdiction-principle)
4. [Access States](#4-access-states)
5. [Detection Pattern](#5-detection-pattern)
6. [Jurisdiction Fields Reference](#6-jurisdiction-fields-reference)
7. [Auth Flow](#7-auth-flow)
8. [Connected Enhancements](#8-connected-enhancements)
9. [Error Handling](#9-error-handling)
10. [Integration Checklist](#10-integration-checklist)

---

## 1. Quick Reference

**Base URL:**
```
Production: https://accounts.empowered.vote/api
```

**Auth Hub URL:**
```
https://accounts.empowered.vote/login?redirect={encodeURIComponent(returnUrl)}
```

**Token delivery:** Hash fragment on redirect return (`#access_token=eyJ...`)

**Token storage:** `localStorage.getItem('ev_token')`

**Token usage:** `Authorization: Bearer {token}` header on authenticated requests

### Endpoint Table

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | /api/account/me | Optional | User profile with tier, jurisdiction, XP, gems (401 if no token) |
| GET | /api/essentials/candidates/:zip | None | Candidates for a given ZIP code |
| GET | /api/essentials/politicians | None | All politicians with district data |
| POST | /api/xp/award | X-Service-Key | Award XP to a Connected user (service-to-service) |
| POST | /api/gems/award | X-Service-Key | Award gems to a Connected user (service-to-service) |

---

## 2. Empowered Vote Platform Overview

Empowered Vote is a civic engagement platform built on a three-tier account architecture: Inform, Connected, Empowered. Every product decision about what a user can see or do flows from which tier they occupy.

### The Three Tiers

**Inform** — unauthenticated or pre-signup.
- Can browse all public content: politicians, candidates, civic information.
- No jurisdiction data. No persistence. No XP, no gems.
- Must provide a local address or ZIP input for any location-dependent feature.

**Connected** — signed up via invite code, email verified.
- Has a `connected_profile` row in the database. That row's presence is what makes a user Connected — there is no "tier" status flag.
- Has XP, gems (yellow/blue/red), verification rating.
- Has jurisdiction if location consent was granted during account setup.
- Location-dependent features auto-populate from jurisdiction — no address input needed.

**Empowered** — promoted from Connected. Has legal name on file, has a candidate page on the platform.
- For Essentials purposes, identical to Connected. All location features behave the same.
- `tier` field in /account/me returns `'empowered'`.

### Tier Detection Rule

Tier is determined by child record presence in the database:
- `connected_profiles` row exists → Connected
- `empowered_profiles` row exists → Empowered
- Neither exists → Inform

The `tier` field in the /account/me response reflects this. Use it directly.

### Inform Pillar Emphasis

Essentials lives primarily in the Inform pillar — it must work fully and completely for anonymous users. Jurisdiction and Connected enhancements are additive layers on top of a fully functional anonymous experience. Inform is not a degraded state; it is the baseline.

---

## 3. The Jurisdiction Principle

### Never ask a Connected user for their address again.

When a user is Connected and has granted location consent, their address was collected once — during account setup at `accounts.empowered.vote`. The accounts service resolved that address to legislative districts via the US Census geocoder. That resolved jurisdiction is available on every call to `GET /api/account/me`.

You must never ask a Connected user for their address or ZIP code in Essentials. Doing so is a product violation. It signals the platform doesn't trust its own data. It fragments the user's trust. It creates a second collection point for sensitive location data.

**The correct pattern:**
1. Detect user state using `GET /api/account/me` (see Section 5).
2. If `jurisdiction` is non-null: use it as the default locality. No address input needed.
3. If `jurisdiction` is null (Inform, or Connected without consent): show an address/ZIP input for exploration. This is normal and expected.

**Connected users can still explore.** Jurisdiction pre-populates locality as the default, but users can always explore other areas by entering a different address or ZIP manually. Jurisdiction is a default, not a lock.

---

## 4. Access States

Essentials has two primary access states. Build both explicitly.

### Inform (Anonymous / Unauthenticated)

No token, or token that returned 401.

- **Location:** No jurisdiction. Show address/ZIP input for any location-dependent feature.
- **Persistence:** None. No saved preferences, no history.
- **Candidates/politicians:** All public endpoints work without auth. Data is available.
- **XP/gems:** Not available. Skip award calls entirely.
- **Transition:** When the user performs an action that benefits from persistence (saving a location, tracking a representative), show a "connect your account" prompt. Redirect to the Auth Hub on confirmation.

### Connected (Authenticated with Jurisdiction)

Token exists, `/api/account/me` returns 200, `jurisdiction` is non-null.

- **Location:** Jurisdiction fields pre-populate locality automatically.
- **Persistence:** Preferences and history can be saved.
- **XP/gems:** Available via service-to-service award endpoints.
- **No address input needed.** Do not show one unless the user explicitly wants to explore a different area.

### Connected (Authenticated without Jurisdiction)

Token exists, `/api/account/me` returns 200, `jurisdiction` is null.

The user is Connected but either declined location consent or consent is pending geocoding resolution.

- **Location:** Treat the same as Inform. Show address/ZIP input.
- **Do NOT prompt for location consent.** Location consent is managed exclusively by the accounts app. Essentials does not collect location consent.
- **XP/gems:** Still available — this user is Connected, just without jurisdiction data.

> **Anti-pattern:** Do not distinguish between "Inform anonymous" and "Connected without jurisdiction" for location UI purposes. In both cases, show an address/ZIP input and move on. The difference is only relevant for XP/gem awards — Connected users get them, Inform users do not.

---

## 5. Detection Pattern

On app initialization and on every route load, run this decision tree to establish user state.

### Decision Tree

```
1. Check localStorage for 'ev_token'
   ├── No token → Inform (anonymous)
   │   └── Show address/ZIP input for location features
   │
   └── Token exists → Call GET /api/account/me
       ├── 401 response → Token expired or invalid
       │   ├── Clear token: localStorage.removeItem('ev_token')
       │   └── Treat as Inform (anonymous) — this is normal, not an error
       │
       └── 200 response → User is authenticated
           ├── me.jurisdiction !== null → Connected with jurisdiction
           │   └── Use jurisdiction as default locality — no address input
           │
           └── me.jurisdiction === null → Connected without jurisdiction
               └── Show address/ZIP input (same as Inform for location features)
```

### Canonical TypeScript Implementation

```typescript
const API_BASE = 'https://accounts.empowered.vote/api';

type UserState =
  | { type: 'inform' }
  | { type: 'connected_with_jurisdiction'; user: AccountMe; jurisdiction: Jurisdiction }
  | { type: 'connected_no_jurisdiction'; user: AccountMe };

async function detectUserState(): Promise<UserState> {
  const token = localStorage.getItem('ev_token');

  if (!token) {
    return { type: 'inform' };
  }

  const response = await fetch(`${API_BASE}/account/me`, {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (response.status === 401) {
    // Token expired or invalid — normal state for returning users
    localStorage.removeItem('ev_token');
    return { type: 'inform' };
  }

  const me: AccountMe = await response.json();

  if (me.jurisdiction !== null) {
    return {
      type: 'connected_with_jurisdiction',
      user: me,
      jurisdiction: me.jurisdiction,
    };
  }

  return { type: 'connected_no_jurisdiction', user: me };
}
```

### Using the Result

```typescript
const state = await detectUserState();

switch (state.type) {
  case 'inform':
    // Show address/ZIP input for location features
    renderAddressInput();
    break;

  case 'connected_with_jurisdiction':
    // Use jurisdiction as default locality
    const district = state.jurisdiction.congressional_district;         // e.g. "1807"
    const districtName = state.jurisdiction.congressional_district_name; // e.g. "Indiana's 7th Congressional District"
    const county = state.jurisdiction.county;                           // e.g. "18097"
    const countyName = state.jurisdiction.county_name;                  // e.g. "Marion County"
    renderWithJurisdiction(state.jurisdiction);
    break;

  case 'connected_no_jurisdiction':
    // No jurisdiction, but user is Connected — XP/gem awards still apply
    renderAddressInput();
    break;
}
```

> **Anti-pattern:** Do not treat a 401 from `GET /api/account/me` as an application error. It is the normal response for anonymous users and expired tokens. Catch it, clear the token, and render the Inform experience.

> **Anti-pattern:** Do not store tier or jurisdiction state across sessions in localStorage. Always re-fetch from `/api/account/me` on load. Jurisdiction can change (geocoding resolves, user updates address), and tier can change (promotion, suspension) between sessions.

---

## 6. Jurisdiction Fields Reference

### Interface Definition

```typescript
interface Jurisdiction {
  congressional_district: string | null;       // TIGER/Line GEOID, e.g. "1807"
  congressional_district_name: string | null;  // e.g. "Indiana's 7th Congressional District"
  state_senate_district: string | null;        // e.g. "18030"
  state_senate_district_name: string | null;   // e.g. "Indiana Senate District 30"
  state_house_district: string | null;         // e.g. "18097"
  state_house_district_name: string | null;    // e.g. "Indiana House District 97"
  county: string | null;                       // 5-char FIPS, e.g. "18097"
  county_name: string | null;                  // e.g. "Marion County"
  school_district: string | null;              // 7-char LEAID, e.g. "1801890"
  school_district_name: string | null;         // e.g. "Metropolitan School District of Pike Township"
}
```

### GEOID Format Table

| Field | Format | Example Code | Example Name |
|-------|--------|--------------|--------------|
| `congressional_district` | 4-char TIGER/Line GEOID | `"1807"` | Indiana's 7th Congressional District |
| `congressional_district_name` | Plain text | — | Indiana's 7th Congressional District |
| `state_senate_district` | 5-char TIGER/Line GEOID | `"18030"` | Indiana Senate District 30 |
| `state_senate_district_name` | Plain text | — | Indiana Senate District 30 |
| `state_house_district` | 5-char TIGER/Line GEOID | `"18097"` | Indiana House District 97 |
| `state_house_district_name` | Plain text | — | Indiana House District 97 |
| `county` | 5-char FIPS code | `"18097"` | Marion County |
| `county_name` | Plain text | — | Marion County |
| `school_district` | 7-char LEAID | `"1801890"` | Metropolitan School District of Pike Township |
| `school_district_name` | Plain text | — | Metropolitan School District of Pike Township |

### GEOID Source

All codes are from TIGER/Line 2024 shapefiles. The format is numeric — no state abbreviation prefix, no hyphen-separated notation.

> **Anti-pattern:** Do not assume congressional district IDs use a state-abbreviation-plus-number format or a plain ordinal. The stored value is the raw TIGER/Line GEOID — `"1807"` for Indiana's 7th Congressional District. Match against the full numeric GEOID string exactly.

### Matching Politicians to Jurisdiction

The `GET /api/essentials/politicians` response includes `district_id` and `district_type` fields on each `PoliticianRecord`. To match a user's jurisdiction to their representatives, compare `me.jurisdiction.congressional_district` to politician records where `district_type === 'congressional'` and `district_id === me.jurisdiction.congressional_district`.

```typescript
const myReps = politicians.filter(p =>
  p.district_type === 'congressional' &&
  p.district_id === me.jurisdiction.congressional_district
);
```

### Individual Fields Can Be Null

Each field within a non-null `Jurisdiction` object can itself be null if that district type was not resolved for the user's address (e.g., the Census geocoder returned no school district for a rural address). Always check individual field nullability even when the parent `jurisdiction` object is non-null.

---

## 7. Auth Flow

Essentials does not handle login or signup directly. Users authenticate at `accounts.empowered.vote` (the Auth Hub) and return to Essentials with a token. This is the same mechanism used by all Empowered Vote apps.

### Step 1 — Redirect to Auth Hub

When an anonymous user initiates a persistent action (e.g., saves a representative to follow, wants their jurisdiction auto-populated), redirect them to:

```typescript
function redirectToAuthHub(returnUrl: string): void {
  const url = new URL('https://accounts.empowered.vote/login');
  url.searchParams.set('redirect', returnUrl);
  window.location.href = url.toString();
}
```

Example redirect URL:
```
https://accounts.empowered.vote/login?redirect=https%3A%2F%2Fessentials.empowered.vote%2Fcandidates
```

**Domain restriction:** Only `*.empowered.vote` domains are accepted as redirect targets. Any other domain is silently discarded — the user will not be redirected back.

### Step 2 — User Authenticates at Auth Hub

The Auth Hub handles login, signup, and email verification. Essentials does not need to know which path the user takes.

On success, the Auth Hub redirects back to the `redirect` URL with the token in a URL hash fragment:

```
https://essentials.empowered.vote/candidates#access_token=eyJhbGciOiJI...
```

**Why hash fragment:** Query parameters are logged by servers and CDNs. Hash fragments are client-side only — never transmitted to a server. This prevents token leakage in logs and network traffic.

### Step 3 — Extract Token on Return

Call this function on app initialization and on every route change:

```typescript
function handleAuthReturn(): string | null {
  const hash = window.location.hash;
  if (!hash.includes('access_token=')) return null;

  const params = new URLSearchParams(hash.substring(1));
  const token = params.get('access_token');
  if (!token) return null;

  // Clean URL immediately — token must not persist in address bar
  window.history.replaceState(null, '', window.location.pathname + window.location.search);

  // Store token
  localStorage.setItem('ev_token', token);
  return token;
}
```

Call this before rendering user state:

```typescript
// On app initialization
const token = handleAuthReturn() ?? localStorage.getItem('ev_token');
// Then run detectUserState() to determine jurisdiction/tier
```

### Step 4 — Use Token for API Calls

```typescript
async function apiFetch(path: string, options: RequestInit = {}, token?: string) {
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...options.headers,
  };
  const response = await fetch(`${API_BASE}${path}`, { ...options, headers });
  if (!response.ok) {
    const error = await response.json();
    throw { status: response.status, code: error.code, message: error.message };
  }
  return response.json();
}
```

### Token Lifecycle

- Supabase JWTs expire in approximately 1 hour.
- When any API call returns HTTP 401, clear the token and redirect to the Auth Hub.
- There is no refresh token flow for external apps. Re-authentication via redirect is the only path.

### Full Auth Flow Diagram

```
Essentials                    Auth Hub (accounts.empowered.vote)
    |                               |
    |-- redirect to /login -------->|
    |   ?redirect=encodeURI(url)    |
    |                               |-- user logs in / signs up
    |                               |-- email verified
    |<-- redirect to returnUrl -----|
    |   #access_token=eyJ...        |
    |                               |
    |-- handleAuthReturn()          |
    |-- store ev_token              |
    |-- detectUserState() --------->|  (calls GET /api/account/me)
    |<-- user profile + tier -------|
    |                               |
    |-- render with jurisdiction    |
```

> **Anti-pattern:** Do not call POST /auth/login directly from Essentials. The redirect flow is the only supported auth mechanism for external apps.

---

## 8. Connected Enhancements

XP awards and gem awards are **opt-in additions** on top of the anonymous Essentials experience. Essentials works fully and correctly without them. Implement the Inform + jurisdiction detection first; add Connected enhancements separately.

These endpoints are **service-to-service** — they use a shared service key, not a user token. Essentials calls these from its backend server, not from the browser.

### Coordination Required Before Going Live

Essentials needs two things provisioned by the Accounts team before using these endpoints:

1. **XP source registered** — `"essentials-rep-lookup"` is already registered in the Accounts backend. The `ESSENTIALS_SERVICE_KEY` env var slot exists; the Accounts team sets its value and shares it with you.
2. **Gem service key provisioned** — gem keys are managed via the `GEMS_SERVICE_KEYS` JSON-map env var on the Accounts backend (e.g. `{"essentials-key-abc":["yellow"]}`). The Accounts team adds an entry for Essentials and shares the key value. There is no standalone `ESSENTIALS_GEMS_KEY` env var — the key is one entry in the shared map.

These provisioning steps are operational, not a blocker for implementation. Build against the documented shapes now; get keys provisioned before the first real award call.

### POST /api/xp/award

Awards XP to a Connected user.

- **Auth:** `X-Service-Key: {ESSENTIALS_SERVICE_KEY}` header (no Bearer token)
- **Call from:** Essentials backend server (not browser)

**Request body:**

```typescript
interface AwardXpRequest {
  user_id: string;           // UUID — the user's Accounts ID from me.id
  source: string;            // Registered source name, e.g. "essentials-rep-lookup"
  amount: number;            // XP amount to award (positive integer)
  idempotency_key: string;   // Required — see Idempotency below
  metadata?: Record<string, unknown>; // Optional context (action, feature, etc.)
}
```

**Response:**

```typescript
interface AwardXpResponse {
  transaction_id: string;
  user_id: string;
  source: string;
  amount: number;
  created_at: string;
  level: number;             // User's current level after award
  total_xp: number;          // User's total XP after award
  xp_in_level: number;       // XP progress within current level
  xp_to_next_level: number;  // XP needed to reach next level
  is_duplicate: boolean;     // true if idempotency_key was already processed
}
```

**Example:**

```typescript
// Essentials backend — award XP when user looks up their representatives
await fetch('https://accounts.empowered.vote/api/xp/award', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Service-Key': process.env.ESSENTIALS_SERVICE_KEY,
  },
  body: JSON.stringify({
    user_id: userId,
    source: 'essentials-rep-lookup',
    amount: 10,
    idempotency_key: `essentials:rep-lookup:${userId}:${zipCode}:${dateStr}`,
    metadata: { zip: zipCode },
  }),
});
```

### POST /api/gems/award

Awards gems to a Connected user.

- **Auth:** `X-Service-Key: {ESSENTIALS_GEMS_KEY}` header (no Bearer token)
- **Call from:** Essentials backend server (not browser)

**Request body:**

```typescript
interface AwardGemsRequest {
  user_id: string;         // UUID — the user's Accounts ID
  gem_type: 'yellow' | 'blue' | 'red';
  amount: number;          // Gem count to award (positive integer)
  idempotency_key: string; // Required — see Idempotency below
}
```

**Response:**

```typescript
interface AwardGemsResponse {
  gem_type: string;
  amount: number;
  new_balance: number;     // User's gem balance after award
  is_duplicate: boolean;   // true if idempotency_key was already processed
}
```

**Example:**

```typescript
// Essentials backend — award yellow gem for first representative lookup
await fetch('https://accounts.empowered.vote/api/gems/award', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Service-Key': process.env.ESSENTIALS_GEM_KEY,  // entry in GEMS_SERVICE_KEYS map; provisioned by Accounts team
  },
  body: JSON.stringify({
    user_id: userId,
    gem_type: 'yellow',
    amount: 1,
    idempotency_key: `essentials:first-lookup:${userId}`,
  }),
});
```

### Idempotency

`idempotency_key` is required on all award calls. The Accounts API will replay a previous result if the same key is submitted again — no double awards, no errors. Use deterministic keys based on the action being rewarded.

**Recommended format:** `{app}:{action}:{user_id}:{unique-context}`

| Scenario | Example Key |
|----------|-------------|
| Daily rep lookup | `essentials:rep-lookup:uuid:2026-03-19` |
| First lookup (lifetime) | `essentials:first-lookup:uuid` |
| Specific ZIP explored | `essentials:zip-explore:uuid:46201` |

**If `is_duplicate: true` in the response:** The action was already awarded. This is not an error — the previous result was replayed. Do not award again.

### Gem Types

| Type | Color | Meaning |
|------|-------|---------|
| `yellow` | Yellow | Inform / general civic engagement |
| `blue` | Blue | Connected / social actions |
| `red` | Red | Empowered / advanced civic actions |

Essentials should award `yellow` gems for Inform Pillar actions (looking up representatives, exploring districts). Consult the Empowered Vote gem design doc for specific award criteria before going live.

---

## 9. Error Handling

### Error Response Shape

All API errors return a consistent JSON body:

```json
{ "code": "ERROR_CODE", "message": "Human-readable description" }
```

**Always parse `code`, never `message`.** The `message` field is for human debugging and may change between deploys. The `code` field is the stable contract.

```typescript
try {
  const data = await apiFetch('/account/me', {}, token);
} catch (error) {
  if (error.code === 'AUTH_ERROR') {
    // Token expired — clear and treat as Inform
    localStorage.removeItem('ev_token');
    renderInformState();
  } else if (error.code === 'RATE_LIMIT_EXCEEDED') {
    // Back off and retry
  } else if (error.code === 'INTERNAL_ERROR') {
    // Server error — retry with backoff
  }
}
```

### Error Code Reference

| Code | HTTP | Meaning | Action |
|------|------|---------|--------|
| AUTH_ERROR | 401 | Token missing, expired, or invalid | Clear token, treat as Inform (on /account/me); redirect to Auth Hub (on other endpoints) |
| NOT_CONNECTED | 403 | User is authenticated but not Connected tier | Skip award call; user is Inform tier |
| VALIDATION_ERROR | 422 | Request body failed validation | Check field constraints and fix |
| RATE_LIMIT_EXCEEDED | 429 | Too many requests | Back off with exponential backoff |
| INTERNAL_ERROR | 500 | Server error | Retry with backoff; if persistent, contact support |

> **Anti-pattern:** Do not treat a 401 from `GET /api/account/me` as an application error. For anonymous users and expired tokens, 401 is the expected response. Catch it, clear the token, and render the Inform experience. Only redirect to the Auth Hub if a different authenticated endpoint returns 401.

> **Anti-pattern:** Do not retry award calls if `is_duplicate: true` is in the response. The duplicate flag means the award was already applied in a previous call with the same idempotency key. The response is replaying the original result, not indicating failure.

---

## 10. Integration Checklist

Use this checklist to verify full integration compliance. Each item maps to an EDOC requirement.

### EDOC-01 — Jurisdiction Principle: Never Ask for Address Again

- [ ] No address or ZIP input shown to Connected users when `jurisdiction` is non-null
- [ ] Jurisdiction is read from `me.jurisdiction` in the `/api/account/me` response
- [ ] Jurisdiction pre-populates default locality; user can still explore other areas manually
- [ ] Location consent is NOT prompted or collected by Essentials

### EDOC-02 — Two-State UX Pattern: Inform vs Connected

- [ ] Inform state (no token, or 401 from /account/me): address/ZIP input shown for location features
- [ ] Connected with jurisdiction: jurisdiction auto-populates locality, no address input
- [ ] Connected without jurisdiction: address/ZIP input shown (same as Inform for location)
- [ ] Inform users can access all public candidate and politician data without auth
- [ ] Tier detected from `me.tier` field — not recomputed from profile presence

### EDOC-03 — Auth Flow: Anonymous to Connected Transition

- [ ] Auth redirect flow implemented: `https://accounts.empowered.vote/login?redirect={encodeURIComponent(url)}`
- [ ] Token extracted from URL hash fragment (`#access_token=...`) on initialization and route changes
- [ ] URL cleaned immediately after extraction (`window.history.replaceState`)
- [ ] Token stored in `localStorage` under `ev_token`
- [ ] All authenticated requests send `Authorization: Bearer {token}` header
- [ ] Token expiry handled: clear token, re-authenticate via redirect
- [ ] POST /auth/login is NOT called directly from Essentials

### EDOC-04 — Three-Pillar Philosophy: Inform Pillar Emphasis

- [ ] Essentials works fully for anonymous Inform users — no auth required for core features
- [ ] Connected enhancements (jurisdiction, XP, gems) are additive, not gating
- [ ] Inform experience is not degraded compared to Connected — same candidate/politician data available

### EDOC-05 — Jurisdiction Field Names and Formats

- [ ] Jurisdiction fields use exact names from the `Jurisdiction` interface (Section 6)
- [ ] GEOID matching uses numeric TIGER/Line format (e.g., `"1807"` — the raw numeric GEOID, not a state-abbreviation-plus-number format)
- [ ] Each jurisdiction field checked for individual nullability even when parent object is non-null
- [ ] `congressional_district`, `state_senate_district`, `state_house_district`, `county`, `school_district` formats understood

### EDOC-06 — Connected Enhancements as Opt-In

- [ ] XP and gem award calls are NOT made for Inform users (no token, or user.tier === 'inform')
- [ ] XP award endpoint called with `X-Service-Key` header (not user token)
- [ ] Gem award endpoint called with `X-Service-Key` header (not user token)
- [ ] `idempotency_key` included on all award calls, using deterministic format
- [ ] `is_duplicate: true` in award response handled gracefully (not treated as error)
- [ ] XP source name registered with Accounts team before first production award call
- [ ] Service key provisioned by Accounts team before first production award call

---

*Empowered Accounts API — Essentials Integration Guide*
*Last updated: 2026-03-19*
