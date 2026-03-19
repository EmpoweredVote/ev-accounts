# Phase 33: Essentials Integration Guide - Research

**Researched:** 2026-03-19
**Domain:** Integration documentation — Accounts API contracts for Essentials team
**Confidence:** HIGH (all findings sourced directly from codebase)

---

## Summary

This phase produces a documentation file only (`docs/ESSENTIALS-INTEGRATION.md`). No code changes. Research task is to harvest ground truth from the codebase — exact field names, endpoint paths, request/response shapes, auth patterns, and production value formats — so the document contains zero invented examples.

The Essentials integration is distinct from CompassV2. Essentials is the Inform Pillar consumer: it needs jurisdiction-based local content personalization, user detection for optional Connected enhancements, and awareness of the XP/gem award APIs. The CompassV2 integration guide (`docs/COMPASSV2-INTEGRATION.md`) is the prior art model — same voice, similar structure.

The jurisdiction fields come from raw TIGER/Line 2024 GEOIDs (numeric strings stored in the `geoid` column of `inform.district_boundaries`). Congressional GEOIDs are 4-char (e.g. `"1807"` = Indiana's 7th), state senate/house are 5-char, counties are 5-char FIPS, school districts are 7-char. Human-readable names come from `NAMELSAD` stored in the `name` column.

**Primary recommendation:** Model the document after `docs/COMPASSV2-INTEGRATION.md` — same quick-reference table at top, same concepts-first flow, same TypeScript interface blocks. All endpoint shapes and field names verified from source.

---

## Standard Stack

This phase has no library dependencies — it is a Markdown document. The "stack" is the existing Accounts API that Essentials will consume.

### API Base

| Concern | Value | Source |
|---------|-------|--------|
| Base URL | `https://accounts.empowered.vote/api` | `docs/COMPASSV2-INTEGRATION.md` |
| Auth Hub URL | `https://accounts.empowered.vote/login?redirect={encodeURIComponent(url)}` | `docs/COMPASSV2-INTEGRATION.md` |
| Token delivery | URL hash fragment `#access_token=eyJ...` | `docs/COMPASSV2-INTEGRATION.md` |
| Token storage | `localStorage` key `ev_token` | `docs/COMPASSV2-INTEGRATION.md` |
| Token header | `Authorization: Bearer {token}` | `docs/COMPASSV2-INTEGRATION.md` |

### Endpoints Relevant to Essentials

| Method | Path | Auth | Essentials Use |
|--------|------|------|----------------|
| GET | /api/account/me | Required (401 if unauth) | User detection + jurisdiction |
| POST | /api/xp/award | X-Service-Key | Award XP for engagement (optional enhancement) |
| POST | /api/gems/award | X-Service-Key (Bearer) | Award yellow gems (optional enhancement) |
| GET | /api/essentials/candidates/:zip | Optional | Active candidates by ZIP |
| GET | /api/essentials/politicians | Optional | Politicians grouped by office |

---

## Architecture Patterns

### Pattern 1: User Detection on Every Page Load

**What:** Call `GET /api/account/me` on every page load. Null/401 response = anonymous (Inform). Populated response = Connected user with jurisdiction available.

**Source:** `backend/src/routes/account.ts` — the route returns 401 when unauthenticated.

**Decision from CONTEXT.md:** Essentials does not maintain its own auth state. `/api/account/me` is the source of truth on every load.

```typescript
// Source: backend/src/routes/account.ts (response shape lines 150–210)
interface AccountMe {
  id: string;                              // UUID
  email: string;
  display_name: string | null;
  avatar_url: string | null;
  tier: 'inform' | 'connected' | 'empowered';
  is_admin: boolean;
  completed_onboarding: boolean;
  location_consent: boolean;
  verification_rating: number;
  vq_hold_active: boolean;
  red_gem_quests_unlocked: boolean;
  account_standing: 'active' | 'suspended';
  jurisdiction: Jurisdiction | null;       // null when no location consent
  created_at: string;
  updated_at: string;
  // Only present when tier === 'connected' or 'empowered':
  connected_profile?: {
    display_name: string | null;
    verification_status: string;
    xp: {
      total: number;
      level: number;
      xp_in_level: number;
      xp_to_next_level: number;
    };
    gems: { yellow: number; blue: number; red: number; };
    completed_onboarding: boolean;
    verification_rating: number;
    vq_hold_active: boolean;
    vq_hold_until: string | null;
    created_at: string;
  };
  gems?: { yellow: number; blue: number; red: number; };
}
```

**Decision tree:**

```typescript
// On page load
const token = localStorage.getItem('ev_token');

if (!token) {
  // Inform user — no account, jurisdiction null, show address input
  return { user: null, jurisdiction: null };
}

try {
  const me = await fetch('https://accounts.empowered.vote/api/account/me', {
    headers: { Authorization: `Bearer ${token}` }
  }).then(r => r.json());

  if (me.jurisdiction) {
    // Connected user with known jurisdiction — use silently, no address input
    return { user: me, jurisdiction: me.jurisdiction };
  } else {
    // Connected user but no location consent yet
    // Treat same as anonymous for locality: show address input
    return { user: me, jurisdiction: null };
  }
} catch {
  // 401 or network error — treat as anonymous
  return { user: null, jurisdiction: null };
}
```

### Pattern 2: Jurisdiction-Based Locality

**What:** When `jurisdiction` is non-null, use it as the default locality for local content. Connected users can still manually type an area to explore — same as anonymous users — but start with their home jurisdiction pre-populated.

**Source:** CONTEXT.md decision: "Connected users get their jurisdiction pre-populated as the default locality; they can still type in and explore other areas the same way anonymous/Inform users do"

The jurisdiction object shape (verified from `backend/src/routes/account.ts` lines 116–128):

```typescript
// Source: backend/src/routes/account.ts — jurisdictionData construction
interface Jurisdiction {
  congressional_district: string | null;       // TIGER/Line GEOID, e.g. "1807"
  congressional_district_name: string | null;  // NAMELSAD, e.g. "Indiana's 7th Congressional District"
  state_senate_district: string | null;        // e.g. "18030"
  state_senate_district_name: string | null;   // e.g. "Indiana Senate District 30"
  state_house_district: string | null;         // e.g. "18097"
  state_house_district_name: string | null;    // e.g. "Indiana House District 97"
  county: string | null;                       // 5-char FIPS, e.g. "18097"
  county_name: string | null;                  // e.g. "Marion County"
  school_district: string | null;              // 7-char GEOID, e.g. "1801890"
  school_district_name: string | null;         // e.g. "Metropolitan School District of Pike Township"
}
```

**GEOID formats (from TIGER/Line 2024 via migration 031/032 and RUNBOOK-TIGER-LOAD.md):**
- Congressional: 4-char, state FIPS (2) + district (2) — `"1807"` = Indiana's 7th
- State senate: 5-char — `"18030"` = Indiana Senate District 30
- State house: 5-char — `"18097"` = Indiana House District 97
- County: 5-char, state FIPS (2) + county FIPS (3) — `"18097"` = Marion County, Indiana
- School district: 7-char LEAID — `"1801890"` = IPS

**Name format:** Raw NAMELSAD from TIGER/Line. Congressional example: `"Indiana's 7th Congressional District"`. State senate example: `"State Senate District 30"`. County: `"Marion County"`.

**Note on FRAMER doc values:** `docs/FRAMER-LOCATION-TRUST-FLOW.md` shows `"IN-07"` as a congressional_district value — this is an illustrative value from a human-authored document. The actual stored value is the raw TIGER/Line GEOID `"1807"`. Do not use `"IN-07"` format in the Essentials guide.

### Pattern 3: When jurisdiction is Null

Three cases — all treated identically (show address input, no personalization):

1. User is anonymous (not authenticated) — no account
2. Connected user who has not granted location consent — their choice, do not prompt for address
3. Connected user with pending geocoding — rare, resolves on next `/account/me` call

**CRITICAL:** Do not prompt for address/location when `jurisdiction` is null AND user is Connected (`tier === 'connected'` or `tier === 'empowered'`). Null jurisdiction for a Connected user means they chose not to share location. Show the address input UX only for anonymous users or when `location_consent === false`.

**Source:** CONTEXT.md + `backend/src/routes/account.ts` line 107: `if (connected?.location_consent) { ... resolve jurisdiction ... }`. Jurisdiction is only attempted when `location_consent === true`.

**Refined decision tree for address input:**

```typescript
function shouldShowAddressInput(user: AccountMe | null): boolean {
  if (!user) return true;                          // Anonymous
  if (user.jurisdiction !== null) return false;   // Connected with jurisdiction — use silently
  // Connected but no jurisdiction:
  //   location_consent false = their choice, don't prompt for address
  //   Show address input for local exploration (same as anonymous)
  return true;
}
```

### Pattern 4: Connected Enhancements (Opt-In)

**What:** XP and gem awards for engagement. These are server-to-server calls using a service key. Essentials implements these optionally — they are never required for the core experience.

**XP Award endpoint** (source: `backend/src/routes/xp.ts` + `backend/src/lib/xpService.ts`):

```typescript
// POST /api/xp/award
// Header: X-Service-Key: {ESSENTIALS_SERVICE_KEY}
// Requires: source must be a permitted XP source for this key

interface AwardXpRequest {
  user_id: string;           // UUID — from AccountMe.id
  source: string;            // Must match permitted sources for the key
  amount: number;            // Positive integer
  idempotency_key: string;   // Unique per event, 1–255 chars
  metadata?: Record<string, unknown>;
}

interface AwardXpResponse {
  transaction_id: string;
  user_id: string;
  source: string;
  amount: number;
  created_at: string;
  level: number;
  total_xp: number;
  xp_in_level: number;
  xp_to_next_level: number;
  is_duplicate: boolean;     // true = already processed, safe to ignore
}
```

XP sources currently registered: `validation_quest_completion`, `civic_trivia_championship_score`, `admin_gift`. Essentials needs its own registered source — this is a coordination item (see Open Questions).

**Gem Award endpoint** (source: `backend/src/routes/gems.ts`):

```typescript
// POST /api/gems/award
// Header: X-Service-Key: {ESSENTIALS_GEMS_KEY}
// Requires: gem_type must be permitted for this key

interface AwardGemsRequest {
  user_id: string;
  gem_type: 'yellow' | 'blue' | 'red';
  amount: number;            // Positive integer
  idempotency_key: string;   // 1–255 chars
}

interface AwardGemsResponse {
  gem_type: string;
  amount: number;
  new_balance: number;
  is_duplicate: boolean;
}
```

**Auth pattern for service-to-service calls:**
- XP: `X-Service-Key: {key}` header (from `QUEST_SERVICE_KEY`, `TRIVIA_SERVICE_KEY`, or `ADMIN_SERVICE_KEY` env vars)
- Gems: same `X-Service-Key: {key}` header (from `GEMS_SERVICE_KEYS` JSON env var — maps key → permitted gem types)
- Both are idempotent: duplicate `idempotency_key` returns `is_duplicate: true`, no second write

### Pattern 5: Connect Prompt Timing

**What:** When to show the "connect your account" prompt. CONTEXT.md decision: "when anonymous user performs a persistent action."

**Examples of persistent actions in Essentials context:**
- User saves a politician to follow
- User sets a notification preference
- User bookmarks a local issue
- User interacts with a feature that requires identity (voting, posting)

**What to specify in the doc:** The timing trigger (persistent action), not the UI copy. UI copy is Essentials' decision.

**Auth redirect pattern** (same as CompassV2, source: `docs/COMPASSV2-INTEGRATION.md`):

```typescript
function redirectToAuthHub(returnUrl: string): void {
  const url = new URL('https://accounts.empowered.vote/login');
  url.searchParams.set('redirect', returnUrl);
  window.location.href = url.toString();
}

// Token extraction on return (call on every page load / route change)
function handleAuthReturn(): string | null {
  const hash = window.location.hash;
  if (!hash.includes('access_token=')) return null;
  const params = new URLSearchParams(hash.substring(1));
  const token = params.get('access_token');
  if (!token) return null;
  window.history.replaceState(null, '', window.location.pathname + window.location.search);
  localStorage.setItem('ev_token', token);
  return token;
}
```

### Pattern 6: Essentials-Specific Public Endpoints

These endpoints are already live and require no auth:

**GET /api/essentials/candidates/:zip** (source: `backend/src/routes/essentialsCandidates.ts`)
- Returns all active (not demoted) empowered candidates for the given ZIP
- ZIP format: 5-digit or ZIP+4 (normalized to 5-digit internally)
- Empty array `[]` when valid ZIP has no matching candidates — NOT 404
- 422 for invalid ZIP format

**GET /api/essentials/politicians** (source: `backend/src/routes/essentialsPoliticians.ts`)
- Returns active, non-vacant politicians grouped by `office_title`
- Default: incumbents only (`is_candidate = false`)
- `?include_candidates=true` adds candidates alongside incumbents
- Each group shape:

```typescript
interface PoliticianGroup {
  office_title: string | null;
  incumbent: PoliticianRecord | null;
  candidates: PoliticianRecord[];
}

interface PoliticianRecord {
  id: string;
  full_name: string | null;
  office_title: string | null;
  photo_origin_url: string | null;
  is_candidate: boolean;
  representing_city: string | null;
  representing_state: string | null;
  district_type: string | null;        // 'congressional' | 'state_senate' | 'state_house' | 'county' | 'school_district' | null
  district_label: string | null;       // Human-readable, e.g. "IN-07"
  district_id: string | null;          // OCD/TIGER identifier (varies by source)
  chamber_name: string | null;         // e.g. "House", "Senate"
  chamber_name_formal: string | null;  // e.g. "U.S. House of Representatives"
  government_name: string | null;      // e.g. "U.S. Federal Government"
  is_vacant: boolean;
}
```

### Anti-Patterns to Avoid

- **Asking for address when junction is null + user is Connected:** If `user.tier` is `connected` or `empowered` and `jurisdiction` is null, this means the user chose not to share location. Do not prompt for their address. Show address input only for anonymous users.
- **Treating auth 401 as an error state:** 401 on `/account/me` is the normal anonymous state — handle it gracefully as "Inform user," not as an error.
- **Storing tier state across sessions:** Always re-fetch `/account/me` on load. Tier can change between sessions.
- **Using the FRAMER doc jurisdiction format as authoritative:** `docs/FRAMER-LOCATION-TRUST-FLOW.md` shows `"IN-07"` format, but actual values are raw TIGER/Line GEOIDs (`"1807"`). The name field (`congressional_district_name`) is always the reliable human-readable value.
- **Calling `/api/auth/login` directly:** External apps only authenticate via Auth Hub redirect. Direct login is for the accounts app itself.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Auth state management | Custom auth store | `/api/account/me` on every load | Accounts is the source of truth; tier can change |
| User identification | Session cookies, custom tokens | Supabase JWT via Auth Hub redirect | Shared identity across all EV apps |
| Jurisdiction lookup | ZIP-to-district mapping | `jurisdiction` field in `/api/account/me` | Geocoding already done at account setup |
| XP/gem accounting | Increment counters in Essentials DB | `POST /api/xp/award` + `POST /api/gems/award` | Idempotency, atomicity, and ledger are handled |

---

## Common Pitfalls

### Pitfall 1: "jurisdiction null = ask for address" applied to Connected users

**What goes wrong:** Essentials shows an address input to a Connected user whose jurisdiction is null — this user chose not to share their location, and now sees an address prompt they already declined.

**Why it happens:** Simple null check without checking the tier or `location_consent` field.

**How to avoid:** The correct gate is: anonymous user (no token / 401 on `/account/me`) = show address input. Connected user with null jurisdiction = show address input for local exploration, but do NOT frame it as "we need your address" — frame it as "explore an area."

**Warning signs:** Any code path that shows an address form when `tier === 'connected'`.

### Pitfall 2: GEOID format confusion

**What goes wrong:** Code that tries to match `jurisdiction.congressional_district` values against formatted strings like `"IN-07"` will fail. The actual values are numeric TIGER/Line GEOIDs like `"1807"`.

**Why it happens:** The `docs/FRAMER-LOCATION-TRUST-FLOW.md` doc uses illustrative `"IN-07"` format values. Those are not the actual stored values.

**How to avoid:** Use `congressional_district_name` (the human-readable name) for display. Use `congressional_district` (the GEOID) for matching against politicians' `district_id` fields.

**Warning signs:** Hard-coded string matching on jurisdiction fields using state abbreviation format.

### Pitfall 3: Service key scope confusion

**What goes wrong:** Using a gem service key for XP award, or vice versa. Different middleware, different env vars, different header names.

**Why it happens:** Both use `X-Service-Key` as the header name. But XP keys come from `QUEST_SERVICE_KEY`/`TRIVIA_SERVICE_KEY` env vars; gem keys come from `GEMS_SERVICE_KEYS` JSON env var. Each key has a whitelist of permitted sources/gem types.

**How to avoid:** Essentials needs its own registered source name for XP, and its own entry in `GEMS_SERVICE_KEYS`. Coordinate with Accounts team before implementing.

### Pitfall 4: Persistence phrasing

**What goes wrong:** Document says "use `/api/compass/answers` for persistence" — but those are CompassV2 endpoints, not relevant for Essentials.

**Why it happens:** CompassV2 integration guide is the prior art; easy to accidentally reference compass-specific persistence.

**How to avoid:** The Essentials guide should NOT reference `/api/compass/` endpoints. XP and gem endpoints are the relevant Connected enhancements for Essentials.

---

## Code Examples

All examples verified from source code.

### Full detection pattern

```typescript
// Source: backend/src/routes/account.ts (response shape) + CONTEXT.md decisions
const API_BASE = 'https://accounts.empowered.vote/api';

async function loadUserState(): Promise<{
  user: AccountMe | null;
  jurisdiction: Jurisdiction | null;
}> {
  // Check for token returned from Auth Hub
  const freshToken = handleAuthReturn();
  const token = freshToken ?? localStorage.getItem('ev_token');

  if (!token) {
    return { user: null, jurisdiction: null };
  }

  try {
    const response = await fetch(`${API_BASE}/account/me`, {
      headers: { Authorization: `Bearer ${token}` },
    });

    if (!response.ok) {
      if (response.status === 401) {
        localStorage.removeItem('ev_token');
        return { user: null, jurisdiction: null };
      }
      throw new Error(`Unexpected status: ${response.status}`);
    }

    const me: AccountMe = await response.json();
    return { user: me, jurisdiction: me.jurisdiction };

  } catch {
    return { user: null, jurisdiction: null };
  }
}
```

### Jurisdiction-based locality pre-population

```typescript
// Source: CONTEXT.md decisions + jurisdiction field shapes from account.ts

function getDefaultLocality(jurisdiction: Jurisdiction | null): string | null {
  if (!jurisdiction) return null;

  // Use county as the default locality for Essentials
  // (most local area that reliably maps to Essentials content)
  return jurisdiction.county_name ?? null;
}

// In your locality selection UI:
const { user, jurisdiction } = await loadUserState();
const defaultLocality = getDefaultLocality(jurisdiction);

if (defaultLocality) {
  // Pre-populate the locality selector silently
  // User can still type to explore any other area
  setLocalityInput(defaultLocality);
} else {
  // Anonymous user, or Connected user who hasn't shared location
  // Show empty address input
}
```

### Matching politicians to user's congressional district

```typescript
// jurisdiction.congressional_district is a TIGER/Line GEOID: "1807" (Indiana 7th)
// Match against politician's district_id field (also a GEOID or OCD identifier)
// Use district_label for display ("IN-07") and district_name for verbose display

const localPoliticians = politicians.filter(p =>
  p.district_id === jurisdiction.congressional_district
);

// For display, always use the _name variant:
const districtLabel = jurisdiction.congressional_district_name;
// e.g. "Indiana's 7th Congressional District"
```

### XP award (Connected enhancement, optional)

```typescript
// Source: backend/src/routes/xp.ts + backend/src/lib/xpService.ts
// Requires: X-Service-Key header with a key registered for the relevant source

async function awardEssentialsXp(
  userId: string,
  action: string,
  idempotencyKey: string
): Promise<void> {
  const response = await fetch(`${API_BASE}/xp/award`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Service-Key': ESSENTIALS_SERVICE_KEY,
    },
    body: JSON.stringify({
      user_id: userId,
      source: 'essentials_engagement', // Must be registered in Accounts
      amount: 10,
      idempotency_key: idempotencyKey,
    }),
  });
  // is_duplicate: true = already processed, safe to ignore
}
```

### Gem award (Connected enhancement, optional)

```typescript
// Source: backend/src/routes/gems.ts
// Requires: X-Service-Key with yellow gem type permitted

async function awardYellowGem(
  userId: string,
  idempotencyKey: string
): Promise<void> {
  await fetch(`${API_BASE}/gems/award`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Service-Key': ESSENTIALS_GEMS_KEY,
    },
    body: JSON.stringify({
      user_id: userId,
      gem_type: 'yellow',
      amount: 1,
      idempotency_key: idempotencyKey,
    }),
  });
}
```

---

## Document Structure Recommendation

Based on CONTEXT.md decisions and the CompassV2 guide as prior art:

```
docs/ESSENTIALS-INTEGRATION.md
├── Quick Reference (table: endpoint, method, auth, description)
├── 1. The Jurisdiction Principle
│      "Never ask for an address twice" — framing anchor
│      How jurisdiction is established (once, at account setup)
├── 2. Access States
│      Inform (anonymous): address input required
│      Connected with jurisdiction: pre-populate, no prompt
│      Connected without jurisdiction: address input for exploration, not consent
├── 3. Detection Pattern
│      GET /api/account/me on every load
│      Full decision tree TypeScript example
│      Token lifecycle (Auth Hub redirect, hash fragment, expiry)
├── 4. Jurisdiction Fields Reference
│      Interface definition with all fields
│      GEOID format table (congressional 4-char, senate 5-char, etc.)
│      Real production values in examples
│      Note on using _name fields for display vs. GEOID for matching
├── 5. Connected Enhancements
│      XP award (POST /api/xp/award) — opt-in, requires service key
│      Gem award (POST /api/gems/award) — opt-in, requires service key
│      Idempotency pattern
│      Coordination requirement: register source name + gem key with Accounts
└── Checklist (verification items per section)
```

**Quick-reference summary box at top:** Recommended — the CompassV2 guide has a compact endpoint table and tier summary that is the most-referenced section. Include an equivalent for Essentials.

**Edge case: Connected user with null jurisdiction:** Document clearly in Section 2. "Connected, no jurisdiction" is a valid state (user declined location consent). Treat for locality purposes the same as anonymous — show address input for exploration — but do not frame it as a requirement. A separate note: do not prompt for location consent in Essentials; that flow lives at accounts.empowered.vote.

---

## Open Questions

1. **XP source name for Essentials**
   - What we know: XP sources are registered as string constants in `backend/src/lib/xpService.ts` (`XP_SOURCES` array: `validation_quest_completion`, `civic_trivia_championship_score`, `admin_gift`). Each service key is authorized for a specific subset.
   - What's unclear: What source name will Essentials use? None is currently registered.
   - Recommendation: Note in the guide that Essentials needs to coordinate with Accounts to register a source name (e.g., `essentials_engagement`) and obtain a service key before going live. The document can show the call pattern with a placeholder source name.

2. **Gem key for Essentials**
   - What we know: Gem keys are registered in `GEMS_SERVICE_KEYS` JSON env var. Each key maps to permitted gem types.
   - What's unclear: Whether Essentials will award gems and what types. Yellow gems are the standard engagement reward.
   - Recommendation: Document yellow gem award as the expected pattern; note coordination requirement for key provisioning.

3. **GEOID format validation**
   - What we know: The TIGER/Line runbook uses `SELECT GEOID AS geoid` from TIGER/Line shapefiles. Congressional GEOID is 4-char (e.g., `"1807"`). `docs/FRAMER-LOCATION-TRUST-FLOW.md` shows `"IN-07"` — this is a human-authored illustrative value, not from the actual data.
   - What's unclear: The exact GEOIDs stored in production have not been verified against the live DB. There is a small risk the FRAMER doc value `"IN-07"` was correct and the DB stores formatted values.
   - Recommendation: Use the `_name` fields for all display. Use the raw GEOID fields only for matching — and note in the doc that GEOID format matches TIGER/Line 2024. The planner should flag: if code examples show GEOIDs matching against politician `district_id`, verify both use the same format.

4. **Essentials persistence endpoints**
   - What we know: CONTEXT.md specifies "list XP award, gem award, and persistence endpoints with their shapes."
   - What's unclear: What "persistence" means in Essentials context. CompassV2 has compass answer persistence. Essentials may want to persist user preferences, bookmarks, or followed politicians.
   - Recommendation: For Phase 33, the document should call out that persistence beyond XP/gems requires coordinating with Accounts on new endpoints. No existing generic persistence endpoint exists for Essentials.

---

## Sources

### Primary (HIGH confidence)
- `backend/src/routes/account.ts` — AccountMe response shape, jurisdiction construction, tier detection
- `backend/src/routes/xp.ts` + `backend/src/lib/xpService.ts` — XP award endpoint, request/response shape, XP_SOURCES constant, service key auth
- `backend/src/routes/gems.ts` — Gem award endpoint, request/response shape, gem types
- `backend/src/routes/essentialsCandidates.ts` — GET /api/essentials/candidates/:zip endpoint
- `backend/src/routes/essentialsPoliticians.ts` + `backend/src/lib/essentialsService.ts` — GET /api/essentials/politicians endpoint, PoliticianRecord/PoliticianGroup shapes
- `backend/src/middleware/serviceKeyAuth.ts` — Service key auth pattern for XP
- `backend/src/middleware/gemServiceKeyAuth.ts` — Service key auth pattern for gems
- `backend/src/index.ts` — Route mounting, confirmed API prefix `/api/...`
- `supabase/migrations/20260310000031_location_schema.sql` — district_boundaries schema, GEOID column
- `supabase/migrations/20260310000032_location_rpcs.sql` — resolve_user_jurisdiction RPC output shape
- `supabase/migrations/20260313000033_politician_schema.sql` — PoliticianRecord fields
- `docs/RUNBOOK-TIGER-LOAD.md` — TIGER/Line GEOID format (4-char congressional, 5-char state/county, 7-char school district)

### Secondary (HIGH confidence — authoritative internal docs)
- `docs/COMPASSV2-INTEGRATION.md` — Prior art for document structure, Auth Hub pattern, token lifecycle
- `docs/FRAMER-LOCATION-TRUST-FLOW.md` — Prior art for jurisdiction philosophy, location consent flow

### Tertiary (note)
- `docs/FRAMER-LOCATION-TRUST-FLOW.md` jurisdiction example values (`"IN-07"`) are illustrative, not production-verified. GEOID format from migration source is authoritative.

---

## Metadata

**Confidence breakdown:**
- Endpoint shapes and field names: HIGH — read directly from route handlers and service files
- Jurisdiction GEOID format: HIGH — read from migration SQL and TIGER/Line runbook; illustrative FRAMER doc value flagged
- Service key auth pattern: HIGH — read from middleware source
- Essentials-specific source names: LOW — no Essentials XP source registered yet; requires coordination
- Document structure recommendation: HIGH — based on CONTEXT.md decisions + COMPASSV2-INTEGRATION.md prior art

**Research date:** 2026-03-19
**Valid until:** 60 days (API is stable; no active development on these endpoints planned)
