# Phase 8: Public Candidate Pages - Research

**Researched:** 2026-02-28
**Domain:** Public read-only Express API (unauthenticated endpoints), Supabase RLS, Upstash Redis caching, Postgres schema migration
**Confidence:** HIGH

---

## Summary

Phase 8 is the final phase of the Empowered Accounts backend. It adds two unauthenticated read-only endpoints (`GET /api/candidates/:slug` and `GET /api/essentials/candidates/:zip`) that expose active Empowered candidates publicly. The domain is entirely within the established project stack — no new libraries are needed. All patterns (unauthenticated routes via `optionalAuth`, caching via `cache.ts`, field projection via explicit whitelists, RLS for `tolerance_rating` exclusion) are already established in the codebase.

The key complexity areas are: (1) the Supabase RLS on `empower.empowered_profiles` already handles the active/inactive split correctly but needs a schema migration to add seven new jurisdiction fields plus a UNIQUE constraint on `candidate_page_slug`; (2) `legal_name` is stored as a single text field but must be split into `first_name`/`last_name` at the serialization layer — the parsing strategy for edge cases (hyphenated names, suffixes, multi-word last names) is a discretion area; (3) the ZIP-based Essentials lookup requires a join between `empowered_profiles` and the new jurisdiction columns, with a Postgres index on `representing_zip` (or the appropriate ZIP field) for performance; (4) the inversion query param flips stance values (1↔5, 2↔4, 3=3) when caller passes `?inverted=topicId1,topicId2`.

There is no new library to install. The only new files are: one Supabase migration, one Express route file (`candidates.ts`), one service file (`candidateService.ts`), one test file, and an update to `index.ts` to mount the two routers.

**Primary recommendation:** Follow the compass route pattern exactly — `optionalAuth` middleware, `supabaseAdmin` via service layer (`candidateService.ts` in `lib/`), explicit field whitelist serializer (never spread DB rows), cache wrapper around every response, architecture test update to whitelist `candidateService.ts`.

---

## Standard Stack

### Core (no new installations — everything already in package.json)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| express | ^4.21.0 | Route handlers | Already in use — locked decision |
| @supabase/supabase-js | ^2.45.0 | `supabaseAdmin` queries for public reference data | Existing pattern for public-read data |
| @upstash/redis | ^1.34.0 | Response caching via `cache.ts` | Existing layer — no new client needed |
| zod | ^3.23.0 | Query param validation | Existing pattern |
| pg | ^8.13.0 | Pool available if needed for raw queries | Already installed |

### No New Installations Required

```bash
# No npm install step needed for Phase 8.
# All dependencies already present in backend/package.json.
```

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `supabaseAdmin` (via service layer) for public data reads | `createUserClient` with anon key | `supabaseAdmin` is the established pattern for public reference data (compass politicians uses it); anon key adds no benefit for unauthenticated reads |
| Explicit whitelist serializer | DB row spread | Spread risks leaking `tolerance_rating` if schema changes; whitelist is the enforced pattern in this codebase |
| Single router for both endpoints | Two separate routers | Both endpoints are unauthenticated reads; either works. Use one `candidates.ts` route file with two path prefixes mounted in `index.ts` |

---

## Architecture Patterns

### Recommended Project Structure (new files only)

```
backend/src/
├── lib/
│   └── candidateService.ts    # NEW: all candidate data access functions
├── routes/
│   └── candidates.ts          # NEW: /api/candidates/:slug, /api/essentials/candidates/:zip
└── index.ts                   # UPDATE: mount candidatesRouter at both prefixes
supabase/migrations/
└── 20260228000025_phase8_candidate_pages.sql  # NEW: jurisdiction columns + UNIQUE constraint
tests/integration/
└── candidates.test.ts         # NEW: CI-safe architecture tests + skipped DB tests
```

### Pattern 1: Public Route via optionalAuth

Phase 8 endpoints are fully unauthenticated. Use `optionalAuth` (not `requireAuth`, not no-middleware). This is the established pattern for routes that must work for anonymous callers:

```typescript
// Source: existing backend/src/routes/compass.ts (GET /topics, GET /politicians)
import { optionalAuth } from '../middleware/auth.js';
import { getCandidateBySlug, getCandidatesByZip } from '../lib/candidateService.js';

router.get('/:slug', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  // candidateService handles all DB access
});
```

`optionalAuth` does NOT perform a standing check (see decision [04-01]). Suspended users can view public candidate pages — this is correct behavior.

### Pattern 2: Cache-Aside with 15-Minute TTL

Use the existing `cache` singleton from `lib/cache.ts`. The established pattern (from compass routes) is a direct cache.get / compute / cache.set wrapper:

```typescript
// Source: established pattern in this codebase via cache.ts
import { cache } from '../cache.js';

// Cache key naming convention (Claude's discretion — recommendation below):
// candidate profile:  `candidate:slug:${slug}`
// ZIP lookup:         `candidates:zip:${zip}`

export async function getCandidateBySlug(slug: string) {
  const cacheKey = `candidate:slug:${slug}`;
  const cached = await cache.get<CandidateProfileResponse>(cacheKey);
  if (cached) return cached;

  // ... DB query ...

  await cache.set(cacheKey, result, 900); // 900s = 15 minutes
  return result;
}
```

**Cache key convention recommendation:** Use `candidate:slug:{slug}` and `candidates:zip:{zip}`. Colon-separated namespacing, lowercase, matches the existing `slug_reservation:{userId}` pattern in `empowerService.ts`.

**No active cache invalidation:** Demotion sets `is_active = false` via RPC; cache expires naturally within 15 minutes. This is the accepted behavior per CONTEXT.md.

### Pattern 3: Explicit Field Whitelist Serializer (CRITICAL)

NEVER spread DB rows. Build the response object from an explicit whitelist. This is the canonical pattern enforced throughout the codebase and is the primary mechanism for excluding `tolerance_rating`:

```typescript
// Source: established pattern in backend/src/routes/account.ts (GET /me)
// CORRECT — explicit whitelist:
const response = {
  id: row.id,
  first_name: parsedFirstName,
  last_name: parsedLastName,
  candidate_page_slug: row.candidate_page_slug,
  active: row.is_active,
  demoted_at: row.demoted_at ?? null,
  // ...jurisdiction fields explicitly listed...
  images: [{ type: 'default', url: row.photo_origin_url ?? null }],
};

// WRONG — spread leaks unexpected fields:
// const response = { ...row };
```

The architecture test does NOT scan for field spreading, but the test for `tolerance_rating` absence MUST be written and must assert `!('tolerance_rating' in body)` — absence, not null.

### Pattern 4: RLS Coverage for Inactive Candidate Pages

The existing RLS policy (migration 009) already handles the active/inactive split:

- `"empowered_profiles: public read active"` — anon + authenticated can only see rows where `is_active = true AND deleted_at IS NULL`
- `"empowered_profiles: owner read own"` — owner reads their own row regardless of `is_active`

For the public slug endpoint: because `GET /api/candidates/:slug` must return inactive candidates (the permanent public record), the query CANNOT use `createUserClient` (which would enforce RLS and hide inactive rows). It MUST go through `supabaseAdmin` (which bypasses RLS) so inactive profiles are accessible. The route file itself cannot use `supabaseAdmin` directly (architecture test bans it in `src/routes/`), so all DB access goes through `candidateService.ts` in `lib/`.

This means `candidateService.ts` intentionally bypasses RLS for the slug lookup — this is the correct approach because Phase 8 requires returning inactive profiles. The architecture test's whitelist of allowed files must be updated to include `candidateService.ts`.

### Pattern 5: Architecture Test Update Required

The existing architecture test in `tests/integration/architecture.test.ts` has an explicit allowlist of files that may use `supabaseAdmin`. Phase 8 must add `candidateService.ts` to this list:

```typescript
// Source: tests/integration/architecture.test.ts (current allowlist)
const allowedFiles = [
  path.join(BACKEND_SRC, 'lib/supabase.ts'),
  path.join(BACKEND_SRC, 'lib/authService.ts'),
  path.join(BACKEND_SRC, 'lib/inviteService.ts'),
  path.join(BACKEND_SRC, 'lib/enrollService.ts'),
  path.join(BACKEND_SRC, 'lib/empowerService.ts'),
  path.join(BACKEND_SRC, 'lib/gemService.ts'),
  path.join(BACKEND_SRC, 'lib/roleService.ts'),
  path.join(BACKEND_SRC, 'lib/socialService.ts'),
  path.join(BACKEND_SRC, 'lib/adminService.ts'),
  path.join(BACKEND_SRC, 'lib/cronService.ts'),
  // ADD THIS:
  path.join(BACKEND_SRC, 'lib/candidateService.ts'),
  path.join(BACKEND_SRC, 'middleware/auth.ts'),
  path.join(BACKEND_SRC, 'middleware/tierGuards.ts'),
  path.join(BACKEND_SRC, 'middleware/requireVerified.ts'),
  path.join(BACKEND_SRC, 'middleware/requireAdmin.ts'),
];
```

### Pattern 6: Inversion Query Param Logic

The `?inverted=topicId1,topicId2` parameter flips stance values for the caller before returning. Value mapping: 1↔5, 2↔4, 3=3. This is a pure in-memory transform after DB fetch — no DB-level inversion logic needed:

```typescript
// Claude's discretion: recommend comma-separated IDs (simpler parsing, single param)
const invertedParam = req.query.inverted;
const invertedSet = new Set(
  typeof invertedParam === 'string' && invertedParam.length > 0
    ? invertedParam.split(',').map(s => s.trim()).filter(Boolean)
    : []
);

function invertValue(value: number): number {
  return 6 - value; // 1→5, 2→4, 3→3, 4→2, 5→1
}

const invertedAnswers = answers.map(a => ({
  topic_id: a.topic_id,
  value: invertedSet.has(a.topic_id) ? invertValue(a.value) : a.value,
  ...(a.write_in_text ? { write_in_text: a.write_in_text } : {}),
}));
```

### Pattern 7: legal_name Splitting

`legal_name` is stored as a single text field (e.g., `"John Michael Smith Jr."`). The CONTEXT.md decision requires splitting to `first_name` / `last_name` at the serialization layer.

**Recommendation (Claude's discretion):** Split on first space only — everything before the first space is `first_name`; everything after is `last_name`. This handles multi-word last names naturally (e.g., `"Mary Van Den Berg"` → first: `"Mary"`, last: `"Van Den Berg"`). Suffixes remain in `last_name` (e.g., `"John Smith Jr."` → first: `"John"`, last: `"Smith Jr."`). This matches how the Essentials frontend `PoliticianCard` component likely renders — it expects `first_name` and `last_name` as display strings, not parsed tokens.

```typescript
// Recommended implementation
function splitLegalName(legalName: string): { first_name: string; last_name: string } {
  const trimmed = legalName.trim();
  const spaceIndex = trimmed.indexOf(' ');
  if (spaceIndex === -1) {
    return { first_name: trimmed, last_name: '' };
  }
  return {
    first_name: trimmed.slice(0, spaceIndex),
    last_name: trimmed.slice(spaceIndex + 1),
  };
}
```

### Anti-Patterns to Avoid

- **Using `createUserClient` for the slug lookup:** RLS hides inactive profiles from non-owners. The slug endpoint MUST return inactive profiles — use `supabaseAdmin` via `candidateService.ts`.
- **Spreading DB rows into the response:** Any `{ ...row }` risks leaking `tolerance_rating` if the schema or query selection ever widens. Always build from an explicit whitelist.
- **Returning `tolerance_rating: null` instead of absent:** The test requirement is `!('tolerance_rating' in body)` — the field must be structurally absent from the serialized object, not nulled.
- **Putting supabaseAdmin directly in `candidates.ts` route file:** The architecture test bans it. All DB access goes through `candidateService.ts` in `lib/`.
- **ZIP without leading-zero handling:** US ZIP codes like `"01234"` must be treated as strings, not integers. Store and query as TEXT; do not cast to integer or trimming leading zeros.
- **Forgetting the UNIQUE constraint migration:** CONTEXT.md requires adding an explicit `UNIQUE` constraint on `empowered_profiles.candidate_page_slug`. The column already has `UNIQUE` in migration 006 (`TEXT UNIQUE`) — however, the CONTEXT.md decision calls for making this explicit via an ALTER TABLE in the Phase 8 migration. Verify: migration 006 says `candidate_page_slug TEXT UNIQUE` which already creates a unique constraint. The Phase 8 migration should confirm/name this constraint explicitly for documentation, or add it via `ALTER TABLE ... ADD CONSTRAINT ... UNIQUE` if the column-level `UNIQUE` was not carried through (check actual DB state).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP caching layer | Custom Redis integration | Existing `cache.ts` singleton | Already wraps Upstash Redis with in-memory fallback — zero new code needed |
| Unauthenticated route pattern | Custom no-auth middleware | Existing `optionalAuth` | Already handles optional JWT parsing without requiring it |
| Field privacy enforcement | Runtime tolerance_rating filter | Explicit whitelist serializer (project pattern) | Spread-based filter can be bypassed if DB schema changes; whitelist cannot |
| ZIP-based geographic query | External geocoding API | Direct Postgres column index query on `representing_zip` | ZIP is stored directly on `empowered_profiles` after migration; no external service needed for Phase 8 (address lookup deferred) |

**Key insight:** Phase 8 is entirely additive to an established codebase. The "don't hand-roll" principle applies most strongly to the caching layer and privacy enforcement — both already exist and must be reused exactly, not reimplemented.

---

## Common Pitfalls

### Pitfall 1: Inactive Candidate Requires supabaseAdmin Bypass

**What goes wrong:** Developer uses `createUserClient` for the slug lookup (following the "RLS enforced for user data" rule). RLS on `empowered_profiles` hides inactive rows from non-owners. Result: inactive candidate pages return 404 instead of the full profile with `active: false`.

**Why it happens:** The RLS rule "non-owners can only see active profiles" is correct for live product use but incorrect for the permanent public record requirement of Phase 8. The slug endpoint is an explicit exception.

**How to avoid:** Use `supabaseAdmin` via `candidateService.ts` for ALL slug lookups — both active and inactive. The service file bypasses RLS intentionally. The route file `candidates.ts` must never use `supabaseAdmin` directly (architecture test).

**Warning signs:** Integration test for inactive slug returns 404 instead of 200 with `active: false`.

### Pitfall 2: tolerance_rating Leaking via Joined Tables

**What goes wrong:** The slug query joins `empowered_profiles` with `connect.connected_profiles` (to get `candidate_role` or display name). If the Supabase JS `.select()` query includes `connected_profiles(*)` or any wildcard, `tolerance_rating` could appear in the returned data and accidentally be included in the response.

**Why it happens:** Supabase JS supports nested object selection via `foreign_table(columns)` syntax. Using `*` on a nested table fetches all columns including `tolerance_rating`.

**How to avoid:** Always specify explicit column lists in `.select()` — never use `*`. Review every nested join to ensure `tolerance_rating` is not in the selection string. The serializer whitelist is the final backstop but the query should also not fetch it.

**Warning signs:** Test asserting `!('tolerance_rating' in body)` fails unexpectedly even though serializer doesn't include it — indicates it's being inadvertently nested in a join object.

### Pitfall 3: Architecture Test Fails Because candidateService.ts is Not Whitelisted

**What goes wrong:** After implementing `candidateService.ts` with `supabaseAdmin`, the architecture test `'supabaseAdmin exists only in expected files'` fails because `candidateService.ts` is not in the allowlist.

**Why it happens:** The test was written before Phase 8 and does not include `candidateService.ts` in the allowlist.

**How to avoid:** Update `tests/integration/architecture.test.ts` to add `path.join(BACKEND_SRC, 'lib/candidateService.ts')` to the `allowedFiles` array. This is a planned, mandatory update for Phase 8.

**Warning signs:** `npm test` passes TypeScript but fails architecture test with "supabaseAdmin found in unexpected file: lib/candidateService.ts".

### Pitfall 4: ZIP Leading Zeros Stripped

**What goes wrong:** ZIP code `"01234"` (Massachusetts) is stored as `01234` (integer) or queried as integer, stripping the leading zero. ZIP lookups in New England states fail silently or return no results.

**Why it happens:** JavaScript `parseInt("01234")` = 1234. Postgres `WHERE zip = 1234` (integer comparison) would not match the string `"01234"`.

**How to avoid:** The `representing_zip` column in the migration MUST be `TEXT NOT NULL` (not INTEGER). Query params must be treated as strings. Validate with `/^\d{5}(-\d{4})?$/` regex (allows ZIP+4 format).

**Warning signs:** ZIP lookups for any New England state return empty arrays despite active candidates existing.

### Pitfall 5: Essentials ZIP Endpoint Returns Inactive Candidates

**What goes wrong:** The Essentials frontend receives demoted candidates in the ZIP lookup response and renders them as active candidates, confusing voters.

**Why it happens:** The query for ZIP lookup forgets to filter `WHERE is_active = true`.

**How to avoid:** The ZIP endpoint (`GET /api/essentials/candidates/:zip`) ALWAYS filters `is_active = true`. Only the slug endpoint returns inactive candidates. Apply this as a hard requirement in the service function with an explicit `is_active = true` WHERE clause — not relying on RLS (which would only apply if using `createUserClient`).

**Warning signs:** ZIP response includes candidates with `active: false` in the body.

### Pitfall 6: /api/candidates and /api/essentials/candidates Are Different Mount Points

**What goes wrong:** Both endpoints are implemented in one `candidates.ts` router but mounted at the wrong paths. Mounting at `/api/candidates` works but `/api/essentials/candidates` requires a separate mount in `index.ts`.

**Why it happens:** Express routers are mounted at a path prefix. A single router mounted at `/api/candidates` cannot also serve `/api/essentials/candidates/:zip` as the path prefix differs.

**How to avoid:** Mount the same (or separate) router at both prefixes in `index.ts`:
```typescript
app.use('/api/candidates', candidatesRouter);
app.use('/api/essentials/candidates', essentialsCandidatesRouter);
```
Or use two separate routers in the same file. Either approach works.

### Pitfall 7: Selected Topics Cross-Join (Profile + Stances in One Endpoint)

**What goes wrong:** `GET /api/candidates/:slug` must return both profile data AND the candidate's selected topics (3-8 pinned topics). The selected topics are stored on `connected_profiles.selected_topic_ids` (a JSONB array of topic UUIDs). The answers for those topics are in `inform.compass_responses`. This requires two queries: one to get the slug → user_id → connected_profiles.selected_topic_ids, then one to get compass_responses for those topic IDs WHERE visibility = 'public'.

**Why it happens:** There's no single join path from slug to compass responses in one query without subquery complexity.

**How to avoid:** Two sequential queries in the service function:
1. Query `empowered_profiles` by slug → get `user_id` + `connected_profile_id`
2. Query `connected_profiles` for `selected_topic_ids` → query `compass_responses` WHERE `user_id = X AND topic_id IN (selected_topic_ids) AND visibility = 'public'`

Cache the entire assembled response at 900s TTL.

---

## Code Examples

### Schema Migration: Add Jurisdiction Fields + UNIQUE Constraint

```sql
-- Source: CONTEXT.md decisions — jurisdiction fields on empowered_profiles
-- Migration 025: Phase 8 public candidate pages schema

BEGIN;

-- Add jurisdiction fields to empower.empowered_profiles
ALTER TABLE empower.empowered_profiles
  ADD COLUMN IF NOT EXISTS representing_city     TEXT,
  ADD COLUMN IF NOT EXISTS representing_state    TEXT,
  ADD COLUMN IF NOT EXISTS representing_zip      TEXT,        -- Store as TEXT (ZIP leading zeros)
  ADD COLUMN IF NOT EXISTS district_type         TEXT,        -- e.g., 'city_council', 'congressional'
  ADD COLUMN IF NOT EXISTS district_id           TEXT,        -- opaque identifier for the district
  ADD COLUMN IF NOT EXISTS government_name       TEXT,        -- e.g., 'City of Austin'
  ADD COLUMN IF NOT EXISTS chamber_name          TEXT,        -- e.g., 'City Council'
  ADD COLUMN IF NOT EXISTS chamber_name_formal   TEXT;        -- e.g., 'Austin City Council'

-- Index for ZIP-based candidate lookup (Essentials frontend)
CREATE INDEX IF NOT EXISTS idx_empowered_profiles_zip
  ON empower.empowered_profiles(representing_zip)
  WHERE representing_zip IS NOT NULL AND is_active = true;

-- Verify slug uniqueness is named (migration 006 created it inline as TEXT UNIQUE,
-- which Postgres names automatically. This adds a named constraint for explicit enforcement.)
-- Note: if candidate_page_slug already has a UNIQUE constraint from migration 006,
-- this ADD CONSTRAINT will fail with "already exists". Check and handle accordingly.
-- Safest approach: document the existing constraint; add ONLY if not present.

COMMIT;
```

### candidateService.ts: Core Service Functions

```typescript
// Source: established patterns from empowerService.ts and compassService.ts
// File: backend/src/lib/candidateService.ts

import { supabaseAdmin } from './supabase.js';
import { cache } from './cache.js';

const CACHE_TTL = 900; // 15 minutes

export async function getCandidateBySlug(slug: string) {
  const cacheKey = `candidate:slug:${slug}`;
  const cached = await cache.get<CandidateProfileResponse>(cacheKey);
  if (cached) return cached;

  // supabaseAdmin bypasses RLS — required to return inactive profiles
  const { data, error } = await supabaseAdmin
    .schema('empower')
    .from('empowered_profiles')
    .select(`
      user_id, legal_name, candidate_page_slug, is_active,
      empowered_at, demoted_at,
      representing_city, representing_state, representing_zip,
      district_type, district_id, government_name, chamber_name, chamber_name_formal
    `)
    .eq('candidate_page_slug', slug)
    .maybeSingle();

  if (error) throw error;
  if (!data) return null;

  // Then fetch photo and selected topics via additional queries...
  // Return explicit whitelist — never spread data
  const result: CandidateProfileResponse = {
    candidate_page_slug: data.candidate_page_slug!,
    ...splitLegalName(data.legal_name),
    active: data.is_active,
    demoted_at: data.demoted_at ?? null,
    // jurisdiction fields...
    images: [], // populated from photo_origin_url if exists
    // featured_stances: populated from selected topics + compass responses
  };

  await cache.set(cacheKey, result, CACHE_TTL);
  return result;
}

export async function getCandidatesByZip(zip: string) {
  const cacheKey = `candidates:zip:${zip}`;
  const cached = await cache.get<EssentialsCandidateResponse[]>(cacheKey);
  if (cached) return cached;

  const { data, error } = await supabaseAdmin
    .schema('empower')
    .from('empowered_profiles')
    .select(`
      user_id, legal_name, candidate_page_slug,
      representing_city, representing_state, representing_zip,
      district_type, government_name, chamber_name
    `)
    .eq('representing_zip', zip)
    .eq('is_active', true)    // ESSENTIALS: never returns inactive candidates
    .is('deleted_at', null);

  if (error) throw error;

  const result = (data ?? []).map(row => ({
    candidate_page_slug: row.candidate_page_slug,
    ...splitLegalName(row.legal_name),
    images: [],  // populated separately
    representing_city: row.representing_city,
    representing_state: row.representing_state,
    district_type: row.district_type,
    government_name: row.government_name,
    chamber_name: row.chamber_name,
  }));

  await cache.set(cacheKey, result, CACHE_TTL);
  return result;
}
```

### candidates.ts Route File: Error Shapes (Claude's Discretion)

```typescript
// Recommendation: 404 for invalid slug; 200 with empty array for no ZIP results
// This follows existing project conventions:
//   - compass.ts returns 404 for politician context not found
//   - compass.ts returns [] (empty array) for valid endpoints with no data

// Invalid slug → 404 NOT_FOUND
if (!candidate) {
  res.status(404).json({ code: 'NOT_FOUND', message: 'Candidate not found' });
  return;
}

// Valid ZIP, no candidates → 200 with empty array (same as compass /politicians with no results)
res.status(200).json(candidates ?? []);
```

### ZIP Validation

```typescript
// Claude's discretion: validate ZIP format before DB query to prevent cache pollution
const ZIP_REGEX = /^\d{5}(-\d{4})?$/;

if (!ZIP_REGEX.test(req.params.zip)) {
  res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid ZIP code format' });
  return;
}
// Strip ZIP+4 to 5-digit base for consistency
const zip = req.params.zip.slice(0, 5);
```

### Test: tolerance_rating Absence Assertion

```typescript
// Source: CAND-02 requirement + established test pattern
it('GET /api/candidates/:slug does not include tolerance_rating', async () => {
  // This test requires a live DB with an active Empowered candidate
  // Mark as it.skip for CI; run against live DB for integration validation
  const res = await request(app).get('/api/candidates/some-known-slug');
  expect(res.status).toBe(200);
  // MUST be absent, not null — this is the enforced pattern for this field
  expect('tolerance_rating' in res.body).toBe(false);
  // Also check it's not nested in any sub-object
  if (res.body.connected_profile) {
    expect('tolerance_rating' in res.body.connected_profile).toBe(false);
  }
});
```

### index.ts Mount Pattern

```typescript
// Source: existing backend/src/index.ts mount pattern
import candidatesRouter from './routes/candidates.js';

// Mount at both prefixes — same router or separate
app.use('/api/candidates', candidatesRouter);
app.use('/api/essentials/candidates', essentialsCandidatesRouter);
```

---

## Schema: What Already Exists vs. What Phase 8 Adds

### Already Exists (migrations 006, 009, 018)

| Field | Table | Notes |
|-------|-------|-------|
| `candidate_page_slug TEXT UNIQUE` | `empower.empowered_profiles` | Already unique via column-level constraint in migration 006 |
| `is_active BOOLEAN` | `empower.empowered_profiles` | Demotion mechanism since Phase 1 |
| `demoted_at TIMESTAMPTZ` | `empower.empowered_profiles` | Added in migration 018 (Phase 5) |
| `legal_name TEXT` | `empower.empowered_profiles` | Set by execute_empowerment RPC |
| `idx_empowered_profiles_slug` | `empower.empowered_profiles` | Partial index on candidate_page_slug WHERE NOT NULL (migration 006) |
| RLS "public read active" policy | `empower.empowered_profiles` | Allows anon reads of active profiles (migration 009) |
| `selected_topic_ids JSONB` | `connect.connected_profiles` | Phase 4 compass feature (migration 015) |
| `compass_responses` | `inform` schema | User answers with visibility column (migration 015) |

### Phase 8 Adds (migration 025)

| Field | Table | Notes |
|-------|-------|-------|
| `representing_city TEXT` | `empower.empowered_profiles` | Nullable |
| `representing_state TEXT` | `empower.empowered_profiles` | Nullable |
| `representing_zip TEXT` | `empower.empowered_profiles` | TEXT not integer (leading zeros) |
| `district_type TEXT` | `empower.empowered_profiles` | Nullable |
| `district_id TEXT` | `empower.empowered_profiles` | Nullable |
| `government_name TEXT` | `empower.empowered_profiles` | Nullable |
| `chamber_name TEXT` | `empower.empowered_profiles` | Nullable |
| `chamber_name_formal TEXT` | `empower.empowered_profiles` | Nullable |
| Index on `representing_zip` | `empower.empowered_profiles` | Partial: WHERE NOT NULL AND is_active = true |

### photo_origin_url

The `photo_origin_url` column exists on `inform.politicians` (migration 015) but NOT on `empower.empowered_profiles`. The CONTEXT.md response shape requires `images: [{type: 'default', url: photo_origin_url}]`. This means a `photo_origin_url` column needs to be added to `empower.empowered_profiles` in the Phase 8 migration, OR the service layer fetches photo from an alternate source. **Recommendation:** Add `photo_origin_url TEXT` to `empowered_profiles` in the migration. Candidates upload/set their photo as part of the Empowerment flow in a future phase, but the column should be present and nullable for Phase 8.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Per-request Redis client | Singleton `cache` with in-memory fallback | Phase 1 (migration 002) | Cache failure does not crash the API — already handled |
| RLS as sole privacy enforcement | RLS + serialization whitelist (dual layer) | Phase 1 decision | Both layers required; Phase 8 must maintain both |
| Reactive cache invalidation | TTL-based expiry (15-min stale window) | Phase 8 decision | No active invalidation on demotion — accepted for Alpha |

---

## Open Questions

1. **photo_origin_url column on empowered_profiles**
   - What we know: `inform.politicians` has `photo_origin_url`; `empower.empowered_profiles` does not.
   - What's unclear: Is there an existing mechanism for Empowered users to set a profile photo, or is this field purely reserved for a future feature?
   - Recommendation: Add `photo_origin_url TEXT` (nullable) to `empowered_profiles` in the Phase 8 migration. The serializer should include `images: [{type: 'default', url: data.photo_origin_url}]` when present, or `images: []` when null. This matches the stated CONTEXT.md response shape.

2. **candidate_page_slug UNIQUE constraint: already exists or needs explicit migration?**
   - What we know: Migration 006 defines `candidate_page_slug TEXT UNIQUE` (column-level constraint). Postgres creates a nameless unique constraint for this.
   - What's unclear: CONTEXT.md says "Add explicit DB UNIQUE constraint on empowered_profiles.candidate_page_slug". This may mean: (a) rename/document the existing implicit constraint, or (b) the existing constraint is sufficient and only documentation is needed.
   - Recommendation: In the Phase 8 migration, add `ALTER TABLE empower.empowered_profiles ADD CONSTRAINT empowered_profiles_candidate_page_slug_key UNIQUE (candidate_page_slug)` wrapped in a DO $$ BEGIN ... EXCEPTION WHEN duplicate_table THEN NULL; END $$; block to handle the case where the constraint already exists. This makes the constraint explicit and named without failing if migration 006 already created it.

3. **Essentials frontend response shape: exact PoliticianCard fields**
   - What we know: CONTEXT.md says response must match `PoliticianCard`/`PoliticianGrid` component shape from `EmpoweredVote/essentials`. The shape expected includes `images: [{type, url}]` and split name fields.
   - What's unclear: The exact fields the Essentials frontend expects cannot be verified from this codebase (it's in a separate repo). The shape described in CONTEXT.md is the authoritative contract.
   - Recommendation: Implement exactly the shape described in CONTEXT.md (`first_name`, `last_name`, `images`, `candidate_page_slug`, jurisdiction fields). Flag for Essentials frontend integration testing when that repo is available.

---

## Sources

### Primary (HIGH confidence)

- `C:/EV-Accounts/backend/src/lib/cache.ts` — exact cache.ts API (get/set/del with TTL); `cache.set(key, value, 900)` pattern confirmed
- `C:/EV-Accounts/backend/src/routes/compass.ts` — optionalAuth pattern, supabaseAdmin for public reference data pattern, explicit select columns, empty array response for no-data cases
- `C:/EV-Accounts/backend/src/routes/account.ts` — explicit whitelist serializer pattern, tolerance_rating nesting, legal_name nesting
- `C:/EV-Accounts/backend/src/lib/empowerService.ts` — cache key naming pattern (`slug_reservation:{userId}`), supabaseAdmin bypass for service-layer operations
- `C:/EV-Accounts/tests/integration/architecture.test.ts` — exact allowedFiles array; confirms candidateService.ts must be added
- `C:/EV-Accounts/supabase/migrations/20260224000006_empower_empowered_profiles.sql` — confirms existing schema: `candidate_page_slug TEXT UNIQUE`, no jurisdiction columns, no `photo_origin_url`
- `C:/EV-Accounts/supabase/migrations/20260224000009_rls_empower.sql` — confirms RLS policy "public read active" hides inactive profiles from anon/authenticated non-owners; confirms supabaseAdmin must be used for inactive candidate page reads
- `C:/EV-Accounts/supabase/migrations/20260226000015_inform_schema.sql` — confirms `selected_topic_ids` on connected_profiles, `compass_responses.visibility` field, `photo_origin_url` exists on `inform.politicians` but not on `empower.empowered_profiles`
- `C:/EV-Accounts/backend/package.json` — confirms no new packages needed; all dependencies already present

### Secondary (MEDIUM confidence)

- `C:/EV-Accounts/.planning/STATE.md` — decisions [01-01], [02-02], [04-01], [04-02], [05-01] confirmed from accumulated context
- `C:/EV-Accounts/.planning/phases/08-public-candidate-pages/08-CONTEXT.md` — locked decisions for Phase 8

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — entire stack already present in package.json; no new libraries
- Architecture: HIGH — all patterns directly extracted from existing codebase (compass.ts, cache.ts, architecture test, empowerService.ts)
- Migration: HIGH — existing schema confirmed by reading actual migration files; jurisdiction fields confirmed absent, UNIQUE constraint confirmed present
- Pitfalls: HIGH (architecture test, RLS bypass for inactive, tolerance_rating absence) — all verified against actual code; MEDIUM (ZIP leading zeros, photo_origin_url gap) — based on schema reading and JS behavior
- photo_origin_url gap: HIGH confidence it's missing from empowered_profiles (confirmed by migration 006 schema read)

**Research date:** 2026-02-28
**Valid until:** 2026-03-28 (stable library stack; 30-day validity)
